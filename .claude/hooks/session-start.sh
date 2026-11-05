#!/bin/bash
# SessionStart: ativa o pre-push do repositório (.githooks) em toda sessão.
# Roda pelo Claude Code, não pelo agente, porque o guard-git.sh proíbe o agente
# de mexer em core.hooksPath. Idempotente: só grava se ainda não estiver certo.
set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}"
if [ "$(git config --get core.hooksPath || true)" != ".githooks" ]; then
  git config core.hooksPath .githooks
fi
