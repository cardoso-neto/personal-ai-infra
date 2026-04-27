#!/bin/bash

# Read the JSON input from Claude Code
input=$(cat)

# Extract current working directory from the JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
cd "$cwd" 2>/dev/null || cd /

# Get path info
path="$(pwd)"
base="$(basename "$path")"

# Display current directory
printf '\033[90m%s/\033[0m\033[1;36m%s\033[0m' "$(dirname "$path")" "$base"

# Add a separator before ccstatusline output
printf ' \033[90m|\033[0m '

# Pipe the original JSON input to ccstatusline
echo "$input" | npx ccstatusline@latest

# Add cost tracking line
# bash ~/.claude/statuslines/cost-tracking.sh

# Add rate limit tracking line
# bash ~/.claude/statuslines/rate-limit-tracking.sh
