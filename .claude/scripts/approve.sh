#!/usr/bin/env bash
# Grava a aprovação de um commit. SÓ depois de um exame 5/5 respondido pelo usuário.
# Uso: .claude/scripts/approve.sh <sha> "<resumo das 5 respostas>"
# Isto é atrito local, não garantia: a trava real é a proteção de branch no GitHub.
set -eu
sha=$(git rev-parse --verify "${1:?sha}^{commit}")
[ -n "${2:-}" ] || { echo "faltou o resumo do exame"; exit 1; }
root=$(git rev-parse --show-toplevel)
mkdir -p "$root/.claude/approvals"
printf 'commit: %s\ndata: %s\nexame: 5/5\n%s\n' "$sha" "$(date -Is)" "$2" > "$root/.claude/approvals/$sha"
echo "aprovado: $sha"
