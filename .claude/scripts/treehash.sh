#!/usr/bin/env bash
# Hash do estado atual do working tree, incluindo arquivos não rastreados (respeita .gitignore).
set -eu
root=$(git rev-parse --show-toplevel)
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp "$root/.git/index" "$tmp" 2>/dev/null || true
GIT_INDEX_FILE="$tmp" git -C "$root" add -A >/dev/null 2>&1
GIT_INDEX_FILE="$tmp" git -C "$root" write-tree
