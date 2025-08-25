#!/bin/zsh
# Usage: ./new-project.sh <project-name> [github-username]
# Example: ./new-project.sh loja-online geraljoaoecom-eng

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <project-name> [github-username]" >&2
  exit 1
fi

PROJECT_NAME="$1"
GITHUB_USER="${2:-geraljoaoecom-eng}"
PROJECT_DIR="$(pwd)/$PROJECT_NAME"

if [ -d "$PROJECT_DIR" ]; then
  echo "[warn] Directory '$PROJECT_NAME' already exists. Aborting." >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "[info] Initializing project in '$PROJECT_DIR'"

# Basic files
cat > index.html << 'HTML'
<!doctype html>
<html lang="pt">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>__PROJECT_NAME__</title>
    <style>
      body { margin:0; font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, Helvetica, Arial; background:#0b0b0c; color:#e6e6e6; display:grid; place-items:center; min-height:100svh; }
      .card { padding:32px; border:1px solid #2a2a2e; border-radius:16px; }
      code { background:#1a1a1d; border:1px solid #2a2a2e; padding:2px 6px; border-radius:6px; }
    </style>
  </head>
  <body>
    <main class="card">
      <h1>__PROJECT_NAME__</h1>
      <p>Deploy inicial. Edite <code>index.html</code>.</p>
    </main>
  </body>
</html>
HTML

sed -i '' "s/__PROJECT_NAME__/$PROJECT_NAME/g" index.html

cat > package.json << JSON
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "Projeto $PROJECT_NAME",
  "scripts": {
    "build": "mkdir -p dist && cp index.html dist/index.html",
    "start": "python3 -m http.server 3000"
  },
  "license": "MIT"
}
JSON

cat > vercel.json << JSON
{
  "name": "$PROJECT_NAME",
  "buildCommand": "npm run build",
  "outputDirectory": "dist"
}
JSON

cat > README.md << MD
# $PROJECT_NAME

Setup inicial para deploy estático na Vercel.

- Build: `npm run build`
- Output: `dist`
- Deploy: importe o repositório na Vercel
MD

# Git init
_git_email="$(git config --global user.email || true)"
_git_name="$(git config --global user.name || true)"
if [ -z "${_git_email}" ]; then
  git config --global user.email "geral.joaoecom@gmail.com"
fi
if [ -z "${_git_name}" ]; then
  git config --global user.name "$GITHUB_USER"
fi

git init
printf "node_modules\n.dist\n.DS_Store\n" > .gitignore

git add .
git commit -m "chore: initial scaffold for $PROJECT_NAME"

git branch -M main
REPO_SSH="git@github.com:${GITHUB_USER}/${PROJECT_NAME}.git"

echo "[info] Setting remote to $REPO_SSH"
git remote add origin "$REPO_SSH" || true

# Try to auto-create repo with GitHub CLI if available and authenticated
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "[info] Creating repo on GitHub via gh..."
    gh repo create "${GITHUB_USER}/${PROJECT_NAME}" --public --source . --push --confirm || true
  else
    echo "[hint] Run: gh auth login --web --git-protocol ssh --scopes repo"
  fi
else
  echo "[hint] Install GitHub CLI: brew install gh"
fi

cat << NOTE
[Next steps]
1) Se o repositório não foi criado automaticamente, crie vazio: https://github.com/new
   - Owner: ${GITHUB_USER}
   - Repository name: ${PROJECT_NAME}
   - NÃO adicione README/.gitignore/licença
2) Primeiro push (se necessário):
   cd "$PROJECT_DIR" && git push -u origin main
3) Na Vercel, importe o repo:
   - Framework: Other
   - Build Command: npm run build
   - Output Directory: dist
NOTE

echo "[done] Projeto '$PROJECT_NAME' criado em: $PROJECT_DIR"
