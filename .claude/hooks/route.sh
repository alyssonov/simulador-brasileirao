#!/usr/bin/env bash
# Roteamento determinístico de micro-forks: escolha de ferramenta e de caminho.
# Só bloqueia com um motivo; nunca aprova permissões.
set -u
input=$(cat)
tool=$(jq -r '.tool_name' <<<"$input")

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

case "$tool" in
  Bash)  # escolha de ferramenta: busca/leitura vão para as ferramentas dedicadas
    cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
    first=$(awk '{print $1}' <<<"$cmd")
    case "$first" in
      grep|egrep|rg) deny "Use a ferramenta Grep (ou o subagente grep) em vez de $first." ;;
      find)          deny "Use a ferramenta Glob (ou o subagente search) em vez de find." ;;
      cat|head|tail) deny "Use a ferramenta Read em vez de $first." ;;
    esac ;;
  Edit|Write)  # seleção de caminho: só dentro do projeto, nunca segredos
    p=$(jq -r '.tool_input.file_path // ""' <<<"$input")
    root="${CLAUDE_PROJECT_DIR:-$PWD}"
    case "$p" in "$root"/*) ;; *) deny "Edição fora do projeto bloqueada: $p" ;; esac
    case "$(basename "$p")" in
      .env|.env.*) deny "Não edite $p: segredos ficam fora do repositório." ;;
    esac ;;
esac
exit 0
