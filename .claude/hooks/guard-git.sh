#!/usr/bin/env bash
# PreToolUse: bloqueia git push (exceto do branch verify-setup), --no-verify,
# desvio de hooks, merge pelo gh e escrita direta de aprovações. É atrito, não garantia.
set -u
input=$(cat)
tool=$(jq -r '.tool_name' <<<"$input")
deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}
case "$tool" in
  Bash)
    cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
    case "$cmd" in *--no-verify*) deny "--no-verify é proibido nesta sessão." ;; esac
    grep -Eq 'git[^|;&]*[[:space:]]commit[^|;&]*[[:space:]]-[a-zA-Z]*n[a-zA-Z]*([[:space:]]|$)' <<<"$cmd" && deny "git commit -n pula hooks; proibido."
    grep -Eq 'hooksPath|HUSKY=0|SKIP_HOOKS|GIT_CONFIG|git[[:space:]]+-c[[:space:]]|\.githooks' <<<"$cmd" && deny "Alterar ou desligar hooks é proibido nesta sessão."
    grep -Eq 'gh[[:space:]]+(pr[[:space:]]+merge|api)' <<<"$cmd" && deny "Merge/API do GitHub pelo gh é proibido nesta sessão. Peça ao usuário."
    if grep -Eq 'approvals|approve\.sh' <<<"$cmd"; then
      grep -Eq '^\.claude/scripts/approve\.sh [0-9a-f]{7,40} "[^"]+"$' <<<"$cmd" \
        || deny "Aprovações só com '.claude/scripts/approve.sh <sha> \"<resumo>\"', depois de um exame 5/5."
    fi
    if grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)' <<<"$cmd"; then
      grep -Eq '^git push( -u)? origin verify-setup$' <<<"$cmd" && exit 0
      deny "git push é proibido nesta sessão (só 'git push -u origin verify-setup'). Peça ao usuário."
    fi ;;
  Edit|Write|NotebookEdit)
    p=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$input")
    case "$p" in */.claude/approvals/*|*/.githooks/*|*/.claude/hooks/*|*/.claude/settings.json)
      deny "Aprovações, hooks e settings não são editados pelo agente. Proponha a mudança ao usuário." ;; esac ;;
esac
exit 0
