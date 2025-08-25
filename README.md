# Cursor Workspace

Este é um projeto inicial configurado com integrações GitHub, Vercel e Supabase.

## Integrações configuradas:
- ✅ GitHub: Conectado ao repositório `geraljoaoecom-eng/Cursor`
- ✅ Vercel: Configurado para deploy automático
- ✅ Supabase: Script de automação para criar projetos

## Scripts disponíveis:

### `./auto-setup.sh <project-name> [github-username]` ⭐ **RECOMENDADO**
**Script de automação completa** que detecta automaticamente se precisa de banco e configura TUDO sozinho!

**Uso:**
```bash
# Configurar projeto "meu-projeto" automaticamente
./auto-setup.sh meu-projeto

# O script faz TUDO automaticamente:
# 1. ✅ Cria estrutura do projeto
# 2. ✅ Detecta necessidade de banco (sempre sim)
# 3. ✅ Cria projeto Supabase
# 4. ✅ Configura variáveis no Vercel
# 5. ✅ Inicializa Git e faz commit
# 6. ✅ Testa build e conexão
```

**Funcionalidades automáticas:**
- 🗄️ **Supabase**: Projeto criado + variáveis configuradas
- ☁️ **Vercel**: Variáveis de ambiente configuradas automaticamente
- 📝 **Git**: Repositório inicializado + primeiro commit
- 🧪 **Teste**: Build testado + conexão Supabase validada

### `./supabase-setup.sh <project-name> [region] [org]`
Script manual para criar apenas o projeto Supabase.

### `./new-project.sh <project-name> [github-username]`
Cria um novo projeto com estrutura básica para deploy na Vercel.

### `./dev.sh <project-dir> [port]`
Inicia servidor de desenvolvimento com live reload.

## Como usar:

### 🚀 **Setup Automático (RECOMENDADO):**
```bash
# 1. Configurar projeto automaticamente
./auto-setup.sh nome-do-projeto

# 2. O script faz TUDO sozinho:
#    ✅ Cria estrutura do projeto
#    ✅ Cria projeto Supabase
#    ✅ Configura Vercel
#    ✅ Inicializa Git
#    ✅ Testa tudo

# 3. Próximos passos:
cd nome-do-projeto
git push -u origin main
# Importar na Vercel → Deploy automático!
```

### 🔧 **Setup Manual:**
1. Para integrar Supabase em um projeto existente:
   - Execute: `SUPABASE_PAT=token ./supabase-setup.sh nome-projeto`
2. Desenvolva seu projeto
3. Faça commit: `git add . && git commit -m "sua mensagem"`
4. Push para GitHub: `git push origin main`
5. Deploy automático na Vercel

---
*Configurado por AI Assistant*
