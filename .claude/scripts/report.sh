#!/usr/bin/env bash
# Roda cada comando passado em "$@" (um por argumento), grava comando + saída bruta + exit code
# em .claude/reports/<tree-hash>.txt e imprime o mesmo na tela. Sai com 1 se algum falhar.
set -u
root=$(git rev-parse --show-toplevel); cd "$root"
th=$(.claude/scripts/treehash.sh)
mkdir -p .claude/reports; out=".claude/reports/$th.txt"
{ echo "tree: $th"; echo "HEAD: $(git rev-parse HEAD)"; echo "data: $(date -Is)"; } > "$out"
fail=0
for c in "$@"; do
  { echo; echo "\$ $c"; } >> "$out"
  bash -c "$c" >> "$out" 2>&1; rc=$?
  echo "[exit $rc]" >> "$out"; [ $rc -eq 0 ] || fail=1
done
echo; echo "RESULTADO: $([ $fail -eq 0 ] && echo PASSOU || echo FALHOU)" >> "$out"
cat "$out"; echo; echo "relatório: $out"
exit $fail
