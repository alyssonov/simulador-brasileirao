#!/usr/bin/env bash
# Stop: não deixa terminar enquanto o estado atual (com mudanças) não tiver relatório de checagens.
set -u
cat >/dev/null
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
th=$(.claude/scripts/treehash.sh 2>/dev/null) || exit 0
base=$(git rev-parse -q --verify 'origin/main^{tree}' 2>/dev/null || true)
[ -n "$base" ] && [ "$th" = "$base" ] && exit 0          # nada mudou
[ -f ".claude/reports/$th.txt" ] && exit 0               # relatório existe
jq -n --arg t "$th" '{decision: "block", reason: ("Sem relatório de checagens para o estado atual (tree " + $t + "). Rode scripts/check.sh, mostre os comandos e a saída bruta, e só então termine.")}'
