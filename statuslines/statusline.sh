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

# Display git branch if in a git repository
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch="$(git branch --show-current 2>/dev/null || echo 'detached')"
    printf ' \033[90m⎇\033[0m \033[1;33m%s\033[0m' "$branch"
fi

# Display Node.js version if it's a Node project
if [ -d node_modules ] || [ -f package.json ]; then
    node_ver="$(node --version 2>/dev/null || echo 'N/A')"
    printf ' \033[90m⬢\033[0m \033[1;32m%s\033[0m' "$node_ver"
fi

# Display Python version/virtualenv if it's a Python project
if [ -f requirements.txt ] || [ -f setup.py ] || [ -f pyproject.toml ]; then
    if [ -n "$VIRTUAL_ENV" ]; then
        venv_name="$(basename "$VIRTUAL_ENV")"
        printf ' \033[90m🐍\033[0m \033[1;34m%s\033[0m' "$venv_name"
    elif command -v python3 >/dev/null 2>&1; then
        py_ver="$(python3 --version 2>/dev/null | cut -d' ' -f2 | cut -d'.' -f1-2)"
        printf ' \033[90m🐍\033[0m \033[1;34mpy%s\033[0m' "$py_ver"
    fi
fi

# Add a separator before ccstatusline output
printf ' \033[90m|\033[0m '

# Pipe the original JSON input to ccstatusline
echo "$input" | npx ccstatusline@latest