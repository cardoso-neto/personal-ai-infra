#!/bin/bash

# ============================================================================
# Claude Code Cost Tracking for Status Line
# ============================================================================
# Calculates costs from Claude Code JSONL transcript files
# Displays: SESSION | 30DAY | 7DAY | TODAY costs
# ============================================================================

# Cache settings (in seconds)
CACHE_TTL=300  # 5 minutes
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-cost"
CACHE_FILE="$CACHE_DIR/cost_cache.txt"

# Projects directory where Claude Code stores transcripts
PROJECTS_DIR="$HOME/.claude/projects"

# Model pricing (per million tokens: input output cache_write cache_read)
get_model_pricing() {
    local model="${1:-default}"
    case "$model" in
        claude-opus-4-5-20251101)
            echo "5.00 25.00 6.25 0.50" ;;
        claude-sonnet-4-5-20251101|claude-sonnet-4-5-20250929)
            echo "3.00 15.00 3.75 0.30" ;;
        claude-sonnet-4-20250514)
            echo "3.00 15.00 3.75 0.30" ;;
        claude-haiku-4-5-20251101|claude-haiku-4-5-20251001)
            echo "1.00 5.00 1.25 0.10" ;;
        *)
            echo "3.00 15.00 3.75 0.30" ;;
    esac
}

# Get AWK pricing block for all models
get_awk_pricing() {
    cat <<'AWK_PRICING'
        p["claude-opus-4-5-20251101"] = "5.00 25.00 6.25 0.50"
        p["claude-sonnet-4-5-20251101"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-5-20250929"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-20250514"] = "3.00 15.00 3.75 0.30"
        p["claude-haiku-4-5-20251101"] = "1.00 5.00 1.25 0.10"
        p["claude-haiku-4-5-20251001"] = "1.00 5.00 1.25 0.10"
        p["default"] = "3.00 15.00 3.75 0.30"
AWK_PRICING
}

# Get ISO timestamp for start of period
get_iso_timestamp() {
    local days_ago="${1:-0}"
    if [[ "$days_ago" -eq 0 ]]; then
        # Today's midnight in local time, converted to UTC
        if [[ "$(uname -s)" == "Darwin" ]]; then
            date -u -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 00:00:00" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null
        else
            date -u -d "$(date +%Y-%m-%d)" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null
        fi
    else
        # N days ago midnight
        if [[ "$(uname -s)" == "Darwin" ]]; then
            local target_date=$(date -v-${days_ago}d +%Y-%m-%d)
            date -u -j -f "%Y-%m-%d %H:%M:%S" "$target_date 00:00:00" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null
        else
            local target_date=$(date -d "$days_ago days ago" +%Y-%m-%d)
            date -u -d "$target_date" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null
        fi
    fi
}

# Calculate costs for all periods in one pass
calculate_costs() {
    local current_dir="${1:-$PWD}"

    # Check if projects directory exists
    [[ ! -d "$PROJECTS_DIR" ]] && echo "0.00:0.00:0.00:0.00" && return 1

    # Calculate time boundaries
    local today_start=$(get_iso_timestamp 0)
    local week_start=$(get_iso_timestamp 7)
    local month_start=$(get_iso_timestamp 30)

    # Sanitize project path for matching
    local project_filter=$(echo "$current_dir" | sed 's|/|-|g')

    # Get pricing data
    local awk_pricing=$(get_awk_pricing)

    # Process all JSONL files (modified in last 30 days for performance)
    local result=$(find "$PROJECTS_DIR" -name "*.jsonl" -type f -mtime -30 2>/dev/null | while read -r jsonl_file; do
        [[ -z "$jsonl_file" ]] && continue
        # Extract usage data and file path
        jq -r --arg file "$jsonl_file" 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
            [$file, .timestamp, (.message.model // "default"),
             (.message.usage.input_tokens // 0),
             (.message.usage.output_tokens // 0),
             (.message.usage.cache_creation_input_tokens // 0),
             (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
    done | awk -F'\t' -v today="$today_start" -v week="$week_start" -v month="$month_start" -v project="$project_filter" "
    BEGIN {
        daily = 0; weekly = 0; monthly = 0; session = 0
$awk_pricing
    }
    {
        file = \$1
        ts = \$2
        model = \$3
        input = \$4 + 0
        output = \$5 + 0
        cache_write = \$6 + 0
        cache_read = \$7 + 0

        # Remove milliseconds from timestamp
        gsub(/\.[0-9]+Z?\$/, \"\", ts)

        # Get pricing
        pricing = p[model]
        if (pricing == \"\") pricing = p[\"default\"]
        split(pricing, pr, \" \")

        # Calculate cost (prices per million tokens)
        cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000

        # Accumulate by period
        if (ts >= month) monthly += cost
        if (ts >= week) weekly += cost
        if (ts >= today) daily += cost

        # Session/repo cost (filter by project path)
        if (index(file, project) > 0) session += cost
    }
    END {
        printf \"%.2f:%.2f:%.2f:%.2f\", session, monthly, weekly, daily
    }")

    echo "${result:-0.00:0.00:0.00:0.00}"
}

# Check cache validity
use_cache() {
    [[ ! -f "$CACHE_FILE" ]] && return 1

    local cache_age
    if [[ "$(uname -s)" == "Darwin" ]]; then
        local cache_mtime=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null)
    else
        local cache_mtime=$(stat -c "%Y" "$CACHE_FILE" 2>/dev/null)
    fi

    cache_age=$(( $(date +%s) - cache_mtime ))
    [[ $cache_age -lt $CACHE_TTL ]]
}

# Format and display costs
format_costs() {
    local costs="$1"
    IFS=':' read -r session_cost monthly_cost weekly_cost daily_cost <<< "$costs"

    printf '\n'
    printf '\033[90m💰 Costs:\033[0m '
    printf '\033[32mSESSION $%.2f\033[0m \033[90m|\033[0m ' "$session_cost"
    printf '\033[35m30DAY $%.2f\033[0m \033[90m|\033[0m ' "$monthly_cost"
    printf '\033[36m7DAY $%.2f\033[0m \033[90m|\033[0m ' "$weekly_cost"
    printf '\033[33mTODAY $%.2f\033[0m' "$daily_cost"
}

# Main execution
main() {
    # Create cache directory if needed
    mkdir -p "$CACHE_DIR" 2>/dev/null

    local costs

    # Try to use cache
    if use_cache; then
        costs=$(cat "$CACHE_FILE")
    else
        # Calculate fresh costs
        costs=$(calculate_costs "$PWD")
        # Save to cache
        echo "$costs" > "$CACHE_FILE"
    fi

    format_costs "$costs"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
