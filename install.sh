#!/usr/bin/env bash
# Instala o skill /prospeccao-aisa-apollo no seu Claude Code, direto do repositório.
# Uso (rodar no terminal, fora do chat do Claude):
#   curl -fsSL https://raw.githubusercontent.com/andrealencarz/prospeccao-aisa-apollo/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/andrealencarz/prospeccao-aisa-apollo/main"
SKILL_DIR="$HOME/.claude/skills/prospeccao-aisa-apollo"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
MARKER="# prospeccao-aisa-apollo"

echo "==> Criando pasta do skill em $SKILL_DIR"
mkdir -p "$SKILL_DIR"

echo "==> Baixando SKILL.md do repositório"
curl -fsSL "$REPO_RAW/SKILL.md" -o "$SKILL_DIR/SKILL.md"

echo "==> Registrando o gatilho /prospeccao-aisa-apollo no CLAUDE.md"
mkdir -p "$HOME/.claude"
touch "$CLAUDE_MD"

if grep -qF "$MARKER" "$CLAUDE_MD"; then
  echo "    Já estava registrado, nada a fazer."
else
  cat >> "$CLAUDE_MD" <<'EOF'

# prospeccao-aisa-apollo
- **prospeccao-aisa-apollo** (`~/.claude/skills/prospeccao-aisa-apollo/SKILL.md`) - prospecção B2B ativa via Google Maps + Apollo (MCP da AIsa): encontra empresas prováveis de terem aberto recentemente por nicho+cidade e monta lista de contatos qualificada. Trigger: `/prospeccao-aisa-apollo`
When the user types `/prospeccao-aisa-apollo`, invoke the Skill tool with `skill: "prospeccao-aisa-apollo"` before doing anything else.
EOF
  echo "    Registrado."
fi

echo ""
echo "==> Pronto! Pra usar, abra o Claude Code e digite:"
echo "    /prospeccao-aisa-apollo <nicho> <cidade>"
echo "    Exemplo: /prospeccao-aisa-apollo salão de beleza São Paulo"
echo ""
echo "IMPORTANTE: esse skill depende do MCP da AIsa (Google Maps + Apollo) já"
echo "conectado e com crédito na sua conta do Claude Code. Sem isso as buscas"
echo "vão falhar. Veja o README do repositório pra saber como configurar."
