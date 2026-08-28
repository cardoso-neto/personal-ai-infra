#!/bin/bash

# Read the JSON input from Claude Code
input=$(cat)

# Extract current working directory from the JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
cd "$cwd" 2>/dev/null || cd /

# Get path info, shortening $HOME to ~
path="$(pwd)"
case "$path" in
  "$HOME") path="~" ;;
  "$HOME"/*) path="~${path#$HOME}" ;;
esac

# Display current directory
if [ "$path" = "~" ]; then
  printf '\033[1;36m~\033[0m'
else
  printf '\033[90m%s/\033[0m\033[1;36m%s\033[0m' "$(dirname "$path")" "$(basename "$path")"
fi

# Add a separator before ccstatusline output
printf ' \033[90m|\033[0m '

# nvm is lazy-loaded in interactive shells, so npx is often missing from
# the non-interactive PATH this script runs with; fall back to the newest
# nvm-installed node
if ! command -v npx >/dev/null 2>&1; then
  node_bin=$(ls -d "$HOME/.nvm/versions/node/"*/bin 2>/dev/null | sort -V | tail -n 1)
  [ -n "$node_bin" ] && PATH="$node_bin:$PATH"
fi

# Pipe the original JSON input to ccstatusline
echo "$input" | npx ccstatusline@latest

# Add cost tracking line
# bash ~/.claude/statuslines/cost-tracking.sh

# Add rate limit tracking line
# bash ~/.claude/statuslines/rate-limit-tracking.sh
