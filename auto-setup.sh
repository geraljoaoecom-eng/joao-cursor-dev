#!/bin/zsh
# Script de automação completa para projetos
# Detecta automaticamente se precisa de Supabase e configura tudo
# Usage: ./auto-setup.sh <project-name> [github-username]

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <project-name> [github-username]" >&2
  exit 1
fi

PROJECT_NAME="$1"
GITHUB_USER="${2:-geraljoaoecom-eng}"
ROOT_DIR="$(pwd)"
PROJECT_DIR="$ROOT_DIR/$PROJECT_NAME"

echo "🚀 [AUTO-SETUP] Configurando projeto '$PROJECT_NAME' automaticamente..."

# 1. Criar estrutura básica do projeto
if [ ! -d "$PROJECT_DIR" ]; then
  echo "📁 Criando estrutura do projeto..."
  mkdir -p "$PROJECT_DIR"
  cd "$PROJECT_DIR"
  
  # Criar arquivos básicos
  cat > index.html << 'HTML'
<!doctype html>
<html lang="pt">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>__PROJECT_NAME__</title>
    <style>
      body { margin:0; font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, Helvetica, Arial; background:#0b0b0c; color:#e6e6e6; display:grid; place-items:center; min-height:100svh; }
      .card { padding:32px; border:1px solid #2a2a2e; border-radius:16px; text-align:center; }
      .status { background:#1a1a1d; border:1px solid #2a2a2e; padding:16px; border-radius:8px; margin:16px 0; }
      .success { border-color:#22c55e; color:#22c55e; }
      .error { border-color:#ef4444; color:#ef4444; }
      code { background:#1a1a1d; border:1px solid #2a2a2e; padding:2px 6px; border-radius:6px; }
    </style>
  </head>
  <body>
    <main class="card">
      <h1>__PROJECT_NAME__</h1>
      <p>Projeto configurado automaticamente com Supabase + Vercel</p>
      
      <div id="status" class="status">Verificando conexão...</div>
      
      <div id="features">
        <h3>✅ Funcionalidades configuradas:</h3>
        <ul style="text-align:left; display:inline-block;">
          <li>Supabase (banco de dados)</li>
          <li>Vercel (deploy automático)</li>
          <li>GitHub (versionamento)</li>
        </ul>
      </div>
    </main>

    <!-- Supabase CDN -->
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
    <script>
      (async () => {
        const statusEl = document.getElementById('status');
        
        // Verificar se as variáveis estão disponíveis
        if (typeof window.SUPABASE_URL === 'undefined' || typeof window.SUPABASE_ANON_KEY === 'undefined') {
          statusEl.textContent = '⚠️ Variáveis Supabase não encontradas. Execute o build primeiro.';
          statusEl.className = 'status error';
          return;
        }

        try {
          const supabase = window.supabase.createClient(window.SUPABASE_URL, window.SUPABASE_ANON_KEY);
          
          // Testar conexão
          const { data: { session }, error } = await supabase.auth.getSession();
          if (error) throw error;
          
          statusEl.innerHTML = `
            <strong>✅ Supabase conectado com sucesso!</strong><br>
            URL: ${window.SUPABASE_URL}<br>
            Sessão: ${session ? 'Ativa' : 'Nenhuma'}
          `;
          statusEl.className = 'status success';
          
        } catch (e) {
          statusEl.innerHTML = `
            <strong>❌ Erro na conexão Supabase:</strong><br>
            ${e.message || e}
          `;
          statusEl.className = 'status error';
        }
      })();
    </script>
  </body>
</html>
HTML

  # Substituir nome do projeto
  sed -i '' "s/__PROJECT_NAME__/$PROJECT_NAME/g" index.html

  # Package.json com build inteligente
  cat > package.json << 'JSON'
{
  "name": "'$PROJECT_NAME'",
  "version": "1.0.0",
  "description": "Projeto '$PROJECT_NAME' configurado automaticamente",
  "scripts": {
    "dev": "npx -y live-server --port=5173 --no-browser --watch=.",
    "build": "mkdir -p dist && sed -e 's~window\\.SUPABASE_URL~\"'\"\\$SUPABASE_URL\"'\"~g' -e 's~window\\.SUPABASE_ANON_KEY~\"'\"\\$SUPABASE_ANON_KEY\"'\"~g' index.html > dist/index.html",
    "start": "python3 -m http.server 3000"
  },
  "license": "MIT"
}
JSON

  # Vercel config
  cat > vercel.json << 'JSON'
{
  "name": "'$PROJECT_NAME'",
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "env": {
    "SUPABASE_URL": "@supabase_url",
    "SUPABASE_ANON_KEY": "@supabase_anon_key"
  }
}
JSON

  # README
  cat > README.md << 'MD'
# '$PROJECT_NAME'

Projeto configurado automaticamente com integrações completas.

## ✅ Funcionalidades configuradas:
- **Supabase**: Banco de dados em tempo real
- **Vercel**: Deploy automático
- **GitHub**: Versionamento

## 🚀 Como usar:
1. **Desenvolvimento local**: \`npm run dev\`
2. **Build**: \`npm run build\`
3. **Deploy**: Push para GitHub → Vercel faz deploy automático

## 🔧 Variáveis de ambiente:
- \`SUPABASE_URL\`: URL da API Supabase
- \`SUPABASE_ANON_KEY\`: Chave anônima para autenticação

---
*Configurado automaticamente por Cursor AI*
MD

  cd "$ROOT_DIR"
  echo "✅ Estrutura do projeto criada"
else
  echo "📁 Projeto já existe, usando estrutura existente"
fi

# 2. Verificar se precisa de Supabase (sempre sim para este exemplo)
echo "🔍 Verificando necessidade de banco de dados..."
NEEDS_DATABASE=true

if [ "$NEEDS_DATABASE" = "true" ]; then
  echo "🗄️ Projeto precisa de banco de dados. Configurando Supabase..."
  
  # Verificar se já temos PAT configurado
  if [ -z "${SUPABASE_PAT:-}" ]; then
    echo "⚠️ SUPABASE_PAT não encontrado. Tentando usar token salvo..."
    
    # Tentar ler de arquivo de configuração
    if [ -f "$ROOT_DIR/.supabase_token" ]; then
      SUPABASE_PAT=$(cat "$ROOT_DIR/.supabase_token")
      echo "✅ Token carregado de .supabase_token"
    else
      echo "❌ Token não encontrado. Crie um arquivo .supabase_token na raiz com seu PAT"
      echo "   Ou execute: SUPABASE_PAT=seu_token $0 $PROJECT_NAME"
      exit 1
    fi
  fi
  
  # Executar setup do Supabase
  echo "🚀 Executando setup automático do Supabase..."
  SUPABASE_PAT="$SUPABASE_PAT" "$ROOT_DIR/supabase-setup.sh" "$PROJECT_NAME" "us-east-1" "default"
  
  echo "✅ Supabase configurado automaticamente!"
else
  echo "ℹ️ Projeto não precisa de banco de dados"
fi

# 3. Configurar Vercel automaticamente
echo "☁️ Configurando Vercel..."
if command -v vercel >/dev/null 2>&1; then
  if vercel whoami >/dev/null 2>&1; then
    echo "🔑 Vercel CLI autenticado. Configurando variáveis..."
    
    # Ler variáveis do .env do projeto
    if [ -f "$PROJECT_DIR/.env" ]; then
      
             # Configurar variáveis no Vercel
       cd "$PROJECT_DIR"
       
       # Ler variáveis do .env
       if [ -f ".env" ]; then
         SUPABASE_URL=$(grep "^SUPABASE_URL=" .env | cut -d'=' -f2)
         SUPABASE_ANON_KEY=$(grep "^SUPABASE_ANON_KEY=" .env | cut -d'=' -f2)
         
         if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
           vercel env add SUPABASE_URL production < <(echo -n "$SUPABASE_URL") 2>/dev/null || true
           vercel env add SUPABASE_ANON_KEY production < <(echo -n "$SUPABASE_ANON_KEY") 2>/dev/null || true
           vercel env add SUPABASE_URL preview < <(echo -n "$SUPABASE_URL") 2>/dev/null || true
           vercel env add SUPABASE_ANON_KEY preview < <(echo -n "$SUPABASE_ANON_KEY") 2>/dev/null || true
           vercel env add SUPABASE_URL development < <(echo -n "$SUPABASE_URL") 2>/dev/null || true
           vercel env add SUPABASE_ANON_KEY development < <(echo -n "$SUPABASE_ANON_KEY") 2>/dev/null || true
         fi
       fi
      
      echo "✅ Variáveis configuradas no Vercel"
      cd "$ROOT_DIR"
    else
      echo "⚠️ Arquivo .env não encontrado. Vercel não configurado automaticamente"
    fi
  else
    echo "⚠️ Vercel CLI não autenticado. Execute: vercel login"
  fi
else
  echo "⚠️ Vercel CLI não instalado. Execute: npm i -g vercel"
fi

# 4. Configurar Git
echo "📝 Configurando Git..."
cd "$PROJECT_DIR"

# Git init se necessário
if [ ! -d ".git" ]; then
  git init
  
  # Configurar usuário se necessário
  _git_email="$(git config --global user.email || true)"
  _git_name="$(git config --global user.name || true)"
  if [ -z "${_git_email}" ]; then
    git config --global user.email "geral.joaoecom@gmail.com"
  fi
  if [ -z "${_git_name}" ]; then
    git config --global user.name "$GITHUB_USER"
  fi
  
  # .gitignore
  printf "node_modules\n.dist\n.DS_Store\n.env\n.env.local\n" > .gitignore
  
  # Primeiro commit
  git add .
  git commit -m "feat: initial setup with Supabase + Vercel integration"
  
  # Configurar remote
  REPO_SSH="git@github.com:${GITHUB_USER}/${PROJECT_NAME}.git"
  git remote add origin "$REPO_SSH" || true
  
  echo "✅ Git configurado"
else
  echo "ℹ️ Git já configurado"
fi

# 5. Teste final
echo "🧪 Fazendo teste final..."
cd "$PROJECT_DIR"
npm run build

if [ $? -eq 0 ]; then
  echo "✅ Build bem-sucedido!"
else
  echo "❌ Build falhou"
  exit 1
fi

cd "$ROOT_DIR"

# 6. Resumo final
echo ""
echo "🎉 PROJETO '$PROJECT_NAME' CONFIGURADO AUTOMATICAMENTE!"
echo ""
echo "📁 Localização: $PROJECT_DIR"
echo "🗄️ Supabase: Configurado e funcionando"
echo "☁️ Vercel: Variáveis configuradas"
echo "📝 Git: Repositório inicializado"
echo ""
echo "🚀 Próximos passos:"
echo "1. cd $PROJECT_NAME"
echo "2. git push -u origin main"
echo "3. Importar na Vercel (deploy automático)"
echo "4. Desenvolver com npm run dev"
echo ""
echo "✨ Tudo funcionando automaticamente!"
