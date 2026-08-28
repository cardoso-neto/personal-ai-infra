#!/usr/bin/env bash
set -euo pipefail

HISTFILE="$HOME/.agents_eternal_history"
PROJECTS_DIR="$HOME/.claude/projects"
BACKFILL="${HISTFILE}.backfill"

find "$PROJECTS_DIR" -name '*.jsonl' -exec \
  jq -r '
    select(.type == "assistant") |
    .timestamp as $ts |
    .message.content[]? |
    select(.type == "tool_use" and .name == "Bash") |
    "#" + ($ts | sub("\\.[0-9]+Z$"; "Z") | fromdate | tostring) + "\n" + .input.command
  ' {} + 2>/dev/null > "$BACKFILL"

existing_lines=0
if [[ -f "$HISTFILE" ]]; then
  existing_lines=$(wc -l < "$HISTFILE")
  cat "$BACKFILL" "$HISTFILE" > "${HISTFILE}.merged"
  mv "${HISTFILE}.merged" "$HISTFILE"
else
  mv "$BACKFILL" "$HISTFILE"
fi
rm -f "$BACKFILL"

new_lines=$(wc -l < "$HISTFILE")
echo "Done. $existing_lines -> $new_lines lines in $HISTFILE"
