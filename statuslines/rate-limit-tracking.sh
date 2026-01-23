#!/bin/bash

# ============================================================================
# Claude Code Rate Limit Tracking for Status Line
# ============================================================================
# Shows time remaining until rate limit reset using ccusage
# Displays: ⌛ 3h 7m until reset at 01:00 (37%) [===-------]
# ============================================================================

# Check if ccusage is available
if ! command -v ccusage >/dev/null 2>&1; then
    printf '\n\033[38;5;210m⚠ Rate limit tracking requires ccusage. Install with: npm install -g ccusage\033[0m'
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    printf '\n\033[38;5;210m⚠ Rate limit tracking requires jq. Install with: apt install jq\033[0m'
    exit 1
fi

# Time helpers
to_epoch() {
    local ts="$1"
    # Try GNU date first
    if command -v gdate >/dev/null 2>&1; then
        gdate -d "$ts" +%s 2>/dev/null && return
    fi
    # Try BSD date (macOS)
    date -u -j -f "%Y-%m-%dT%H:%M:%S%z" "${ts/Z/+0000}" +%s 2>/dev/null && return
    # Fallback to python
    python3 - "$ts" <<'PY' 2>/dev/null
import sys, datetime
s=sys.argv[1].replace('Z','+00:00')
print(int(datetime.datetime.fromisoformat(s).timestamp()))
PY
}

fmt_time_hm() {
    local epoch="$1"
    if date -r 0 +%s >/dev/null 2>&1; then
        date -r "$epoch" +"%H:%M"
    else
        date -d "@$epoch" +"%H:%M"
    fi
}

progress_bar() {
    local pct="${1:-0}"
    local width="${2:-10}"
    [[ "$pct" =~ ^[0-9]+$ ]] || pct=0
    ((pct < 0)) && pct=0
    ((pct > 100)) && pct=100
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    printf '%*s' "$filled" '' | tr ' ' '='
    printf '%*s' "$empty" '' | tr ' ' '-'
}

# Color based on remaining percentage
session_color() {
    local rem_pct="$1"
    if ((rem_pct <= 10)); then
        printf '\033[38;5;210m'  # light pink (critical)
    elif ((rem_pct <= 25)); then
        printf '\033[38;5;228m'  # light yellow (warning)
    else
        printf '\033[38;5;194m'  # light green (ok)
    fi
}

rst() {
    printf '\033[0m'
}

main() {
    local blocks_output=""

    # Try ccusage with timeout
    if command -v timeout >/dev/null 2>&1; then
        blocks_output=$(timeout 5s ccusage blocks --json 2>/dev/null)
    elif command -v gtimeout >/dev/null 2>&1; then
        blocks_output=$(gtimeout 5s ccusage blocks --json 2>/dev/null)
    else
        blocks_output=$(ccusage blocks --json 2>/dev/null)
    fi

    if [ -z "$blocks_output" ]; then
        exit 0
    fi

    # Get the active block
    local active_block
    active_block=$(echo "$blocks_output" | jq -c '.blocks[] | select(.isActive == true)' 2>/dev/null | head -n1)

    if [ -z "$active_block" ]; then
        exit 0
    fi

    # Extract reset time and start time
    local reset_time_str start_time_str
    reset_time_str=$(echo "$active_block" | jq -r '.usageLimitResetTime // .endTime // empty')
    start_time_str=$(echo "$active_block" | jq -r '.startTime // empty')

    if [ -z "$reset_time_str" ] || [ -z "$start_time_str" ]; then
        exit 0
    fi

    # Calculate times
    local start_sec end_sec now_sec
    start_sec=$(to_epoch "$start_time_str")
    end_sec=$(to_epoch "$reset_time_str")
    now_sec=$(date +%s)

    if [ -z "$start_sec" ] || [ -z "$end_sec" ]; then
        exit 0
    fi

    # Calculate progress
    local total=$((end_sec - start_sec))
    ((total < 1)) && total=1
    local elapsed=$((now_sec - start_sec))
    ((elapsed < 0)) && elapsed=0
    ((elapsed > total)) && elapsed=$total

    local session_pct=$((elapsed * 100 / total))
    local remaining=$((end_sec - now_sec))
    ((remaining < 0)) && remaining=0

    local rh=$((remaining / 3600))
    local rm=$(((remaining % 3600) / 60))
    local end_hm
    end_hm=$(fmt_time_hm "$end_sec")

    local remaining_pct=$((100 - session_pct))
    local bar
    bar=$(progress_bar "$session_pct" 10)

    # Output the line
    printf '\n'
    printf '⌛ %s%dh %dm until reset at %s (%d%%) [%s]%s' \
        "$(session_color "$remaining_pct")" \
        "$rh" "$rm" "$end_hm" "$session_pct" "$bar" \
        "$(rst)"
}

main
