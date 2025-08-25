#!/bin/zsh
# Usage: SUPABASE_PAT=... ./supabase-setup.sh <project-name> [region] [org_slug]
# Example: SUPABASE_PAT=xxxx ./supabase-setup.sh spy-ecom eu-central my-org
set -euo pipefail

if [ -z "${SUPABASE_PAT:-}" ]; then
  echo "[error] SUPABASE_PAT não definido. Exemplo: SUPABASE_PAT=xxxx $0 <project-name>" >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <project-name> [region] [org_slug]" >&2
  exit 1
fi

PROJECT_NAME="$1"
REGION="${2:-eu-central}"   # veja regiões válidas na doc da Supabase
ORG_SLUG="${3:-default}"     # equipe/organização; ajuste conforme sua conta

ROOT_DIR="$(pwd)"
PROJECT_DIR="$ROOT_DIR/$PROJECT_NAME"

echo "[info] Criando projeto Supabase: name=$PROJECT_NAME region=$REGION org=$ORG_SLUG"

# Buscar projeto existente ou criar novo
org_id=$(curl -sS -H "Authorization: Bearer $SUPABASE_PAT" "https://api.supabase.com/v1/organizations" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$org_id" ]; then
  echo "[error] Não foi possível obter organization_id" >&2
  exit 1
fi

echo "[info] Organization ID: $org_id"

# Buscar projeto existente
projects=$(curl -sS -H "Authorization: Bearer $SUPABASE_PAT" "https://api.supabase.com/v1/projects")
PROJECT_ID=$(echo "$projects" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)
PROJECT_NAME_FOUND=$(echo "$projects" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p' | head -1)

if [ "$PROJECT_NAME_FOUND" = "$PROJECT_NAME" ]; then
  echo "[info] Projeto '$PROJECT_NAME' já existe, usando: $PROJECT_ID"
  DB_PASS="[já definida]"
else
  echo "[info] Criando novo projeto: $PROJECT_NAME"
  # Gerar senha aleatória para o banco
  db_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
  
  create_resp=$(curl -sS -X POST \
    -H "Authorization: Bearer $SUPABASE_PAT" \
    -H "Content-Type: application/json" \
    -d '{"name":"'"$PROJECT_NAME"'","organization_id":"'"$org_id"'","db_pass":"'"$db_pass"'","region":"'"$REGION"'","plan":"free"}' \
    https://api.supabase.com/v1/projects)
  
  echo "$create_resp" | grep -q '"id"' || { echo "[error] Falha ao criar projeto: $create_resp" >&2; exit 1; }
  
  PROJECT_ID=$(echo "$create_resp" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
  DB_PASS="$db_pass"
fi

echo "[info] Project ID: $PROJECT_ID"

# Buscar informações do projeto
proj_info=$(curl -sS -H "Authorization: Bearer $SUPABASE_PAT" "https://api.supabase.com/v1/projects/$PROJECT_ID")
REF=$(echo "$proj_info" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
API_URL="https://$REF.supabase.co"

echo "[info] Project REF: $REF"

echo "[info] API URL: $API_URL"

# Obter anon key (JWT pública)
# Tentar diferentes endpoints para obter as chaves
keys=$(curl -sS -H "Authorization: Bearer $SUPABASE_PAT" "https://api.supabase.com/v1/projects/$PROJECT_ID/keys" 2>/dev/null || echo "")
if [ -z "$keys" ] || echo "$keys" | grep -q "Cannot GET"; then
  keys=$(curl -sS -H "Authorization: Bearer $SUPABASE_PAT" "https://api.supabase.com/v1/projects/$PROJECT_ID/api-keys" 2>/dev/null || echo "")
fi

ANON_KEY=$(echo "$keys" | sed -n 's/.*"api_key":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$ANON_KEY" ]; then
  echo "[error] Não foi possível extrair ANON_KEY. Resposta: $keys" >&2
  exit 1
fi

echo "[info] ANON KEY obtida."

# Escrever envs na raiz e no projeto alvo (se existir)
write_env() {
  local env_path="$1"
  mkdir -p "$(dirname "$env_path")"
  cat > "$env_path" << ENV
SUPABASE_URL=$API_URL
SUPABASE_ANON_KEY=$ANON_KEY
SUPABASE_PROJECT_ID=$PROJECT_ID
SUPABASE_DB_PASSWORD=$DB_PASS
ENV
  echo "[info] Gravado: $env_path"
}

write_env "$ROOT_DIR/.env"

if [ -d "$PROJECT_DIR" ]; then
  write_env "$PROJECT_DIR/.env"
fi

# Configurar Vercel (se CLI estiver autenticada)
if command -v vercel >/dev/null 2>&1; then
  if vercel whoami >/dev/null 2>&1; then
    echo "[info] Configurando variáveis no Vercel (escopo do projeto raiz)"
    vercel env add SUPABASE_URL production < <(echo -n "$API_URL") || true
    vercel env add SUPABASE_ANON_KEY production < <(echo -n "$ANON_KEY") || true
    vercel env add SUPABASE_PROJECT_ID production < <(echo -n "$PROJECT_ID") || true
    vercel env add SUPABASE_DB_PASSWORD production < <(echo -n "$DB_PASS") || true
    vercel env add SUPABASE_URL preview < <(echo -n "$API_URL") || true
    vercel env add SUPABASE_ANON_KEY preview < <(echo -n "$ANON_KEY") || true
    vercel env add SUPABASE_PROJECT_ID preview < <(echo -n "$PROJECT_ID") || true
    vercel env add SUPABASE_DB_PASSWORD preview < <(echo -n "$DB_PASS") || true
    vercel env add SUPABASE_URL development < <(echo -n "$API_URL") || true
    vercel env add SUPABASE_ANON_KEY development < <(echo -n "$ANON_KEY") || true
    vercel env add SUPABASE_PROJECT_ID development < <(echo -n "$PROJECT_ID") || true
    vercel env add SUPABASE_DB_PASSWORD development < <(echo -n "$DB_PASS") || true
  else
    echo "[hint] Vercel CLI não autenticado. Rode: vercel login" >&2
  fi
else
  echo "[hint] Instale Vercel CLI: npm i -g vercel" >&2
fi

echo "[done] Supabase pronto. URL e chave gravadas."

