#!/usr/bin/env bash
# Grok uses camelCase input; Claude and Codex use snake_case.

command_text=$(jq -r '.tool_input.command // .toolInput.command // empty | select(type == "string")' 2>/dev/null) || exit 0
[[ -n "$command_text" ]] || exit 0
printf '#%s\n%s\n' "$(date +%s)" "$command_text" >> "$HOME/.agents_eternal_history"
