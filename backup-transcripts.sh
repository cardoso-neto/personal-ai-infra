#!/usr/bin/env bash
# Mirrors ~/.claude/projects into a gzipped tree outside the repo.
# Incremental: only re-archives transcripts that changed. Never deletes anything.

set -euo pipefail

readonly source_dir="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
readonly dest_dir="${CLAUDE_TRANSCRIPT_BACKUP_DIR:-$HOME/claude-transcript-backups}"

if [[ ! -d "$source_dir" ]]; then
    echo "no transcripts at $source_dir" >&2
    exit 1
fi

archive_if_stale() {
    local src="$1"
    local out="$dest_dir/${src#"$source_dir"/}.gz"
    [[ -f "$out" && ! "$src" -nt "$out" ]] && return 1
    mkdir -p "${out%/*}"
    gzip -c -- "$src" > "$out.partial"
    mv -f "$out.partial" "$out"
}

archived=0
skipped=0
while IFS= read -r transcript; do
    if archive_if_stale "$transcript"; then
        archived=$((archived + 1))
    else
        skipped=$((skipped + 1))
    fi
done < <(find "$source_dir" -name '*.jsonl' -type f)

printf '%d archived, %d already current, %s total in %s\n' \
    "$archived" "$skipped" "$(du -sh "$dest_dir" | cut -f1 | tr -d ' ')" "$dest_dir"
