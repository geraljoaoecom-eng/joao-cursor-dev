# Cursor Workspace

Este é um projeto inicial configurado com integrações GitHub, Vercel e Supabase.

## Integrações configuradas:
- ✅ GitHub: Conectado ao repositório `geraljoaoecom-eng/Cursor`
- ✅ Vercel: Configurado para deploy automático
- ✅ Supabase: Script de automação para criar projetos

## Scripts disponíveis:

### `./supabase-setup.sh <project-name> [region] [org]`
Cria automaticamente um projeto Supabase e configura as variáveis de ambiente.

**Uso:**
```bash
# Criar projeto "meu-projeto" na região us-east-1
SUPABASE_PAT=seu_token_aqui ./supabase-setup.sh meu-projeto us-east-1

# O script irá:
# 1. Criar projeto no Supabase
# 2. Gerar arquivos .env na raiz e no projeto
# 3. Configurar variáveis no Vercel (se CLI autenticado)
```

**Variáveis geradas:**
- `SUPABASE_URL`: URL da API do projeto
- `SUPABASE_ANON_KEY`: Chave anônima para autenticação
- `SUPABASE_PROJECT_ID`: ID do projeto
- `SUPABASE_DB_PASSWORD`: Senha do banco (se novo projeto)

### `./new-project.sh <project-name> [github-username]`
Cria um novo projeto com estrutura básica para deploy na Vercel.

### `./dev.sh <project-dir> [port]`
Inicia servidor de desenvolvimento com live reload.

## Como usar:
1. Para integrar Supabase em um projeto:
   - Gere um PAT na Supabase (Account Settings → Access Tokens)
   - Execute: `SUPABASE_PAT=token ./supabase-setup.sh nome-projeto`
2. Desenvolva seu projeto
3. Faça commit: `git add . && git commit -m "sua mensagem"`
4. Push para GitHub: `git push origin main`
5. Deploy automático na Vercel

---
*Configurado por AI Assistant*
