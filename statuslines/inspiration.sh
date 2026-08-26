#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Truncate directory to max 30 chars, keeping right side
if [ ${#CURRENT_DIR} -gt 30 ]; then
    DISPLAY_DIR="...${CURRENT_DIR: -27}"
else
    DISPLAY_DIR="$CURRENT_DIR"
fi

# Get git branch, truncate to max 20 chars, keeping right side
GIT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        if [ ${#BRANCH} -gt 20 ]; then
            BRANCH_DISPLAY="...${BRANCH: -17}"
        else
            BRANCH_DISPLAY="$BRANCH"
        fi
        GIT_BRANCH=" | 🌿 $BRANCH_DISPLAY"
    fi
fi

# Format cost with 2 decimal places
COST_FORMATTED=$(printf "%.2f" "$COST_USD")

# Output status line
echo "[🤖 $MODEL_DISPLAY] [💰 \$$COST_FORMATTED] | 📁 $DISPLAY_DIR$GIT_BRANCH"