#!/usr/bin/env bash
# PostToolUse hook for Write|Edit: lints edited markdown and feeds the report back to the model.
# Saves the agent from installing and invoking markdownlint by hand on every markdown edit.

set -uo pipefail

readonly MAX_PER_RULE=3
readonly MAX_LINES=30

# A single bad edit can produce hundreds of near-identical violations, so keep at most
# MAX_PER_RULE examples of each rule, then hard-cap whatever survives at MAX_LINES.
condense_report() {
    awk -v prefix="$1:" -v max_per_rule="$MAX_PER_RULE" -v max_lines="$MAX_LINES" '
        {
            plen = length(prefix)
            if (substr($0, 1, plen) == prefix) $0 = substr($0, plen + 1)
            rule = match($0, /MD[0-9]+/) ? substr($0, RSTART, RLENGTH) : "other"
            if (++count[rule] <= max_per_rule) { kept[++n] = $0; next }
            if (!(rule in suppressed)) order[++rules] = rule
            suppressed[rule]++
        }
        END {
            shown = n > max_lines ? max_lines : n
            for (i = 1; i <= shown; i++) print kept[i]
            if (n > shown) printf "... %d further lines omitted\n", n - shown
            for (i = 1; i <= rules; i++)
                summary = summary (i > 1 ? ", " : "") suppressed[order[i]] "x " order[i]
            if (rules) printf "... repeats suppressed: %s\n", summary
        }
    '
}

emit_context() {
    jq -n --arg context "$1" '{
        hookSpecificOutput: {
            hookEventName: "PostToolUse",
            additionalContext: $context
        }
    }'
}

# nvm-style setups define node/npm as shell functions, so PATH alone is unreliable here.
resolve_markdownlint() {
    if command -v markdownlint >/dev/null 2>&1; then
        command -v markdownlint
        return
    fi
    local candidate
    for candidate in "$HOME"/.nvm/versions/node/*/bin/markdownlint /opt/homebrew/bin/markdownlint /usr/local/bin/markdownlint; do
        if [[ -x "$candidate" ]]; then
            printf '%s' "$candidate"
            return
        fi
    done
}

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null)

case "$file" in
    *.md|*.markdown) ;;
    *) exit 0 ;;
esac
[[ -f "$file" ]] || exit 0

linter=$(resolve_markdownlint)
if [[ -z "$linter" ]]; then
    emit_context "markdownlint is not installed, so $file was not linted. Install it once with \`npm install -g markdownlint-cli\` and this hook will lint every markdown edit from now on."
    exit 0
fi

report=$("$linter" --disable MD013 -- "$file" 2>&1) && exit 0
[[ -n "$report" ]] || exit 0
report=$(printf '%s\n' "$report" | condense_report "$file")

emit_context "markdownlint found issues in $file (MD013 disabled, line:col prefixes). Fix them now; \`markdownlint --disable MD013 --fix -- $file\` auto-fixes most.

$report"
