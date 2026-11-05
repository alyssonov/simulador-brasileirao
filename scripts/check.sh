#!/usr/bin/env bash
# Checagem definida deste repositório. Grava comandos + saída bruta em .claude/reports/<tree>.txt
exec "$(git rev-parse --show-toplevel)/.claude/scripts/report.sh" \
  node\ .claude/scripts/smoke.cjs\ .
