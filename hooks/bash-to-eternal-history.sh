#!/usr/bin/env bash
# Appends Claude Code Bash tool commands to a separate eternal history file.
# Used as a PostToolUse hook for the Bash tool.

HISTFILE="$HOME/.agents_eternal_history"

input=$(cat)
command_text=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -n "$command_text" ]]; then
    printf '#%s\n%s\n' "$(date +%s)" "$command_text" >> "$HISTFILE"
fi
