# Rename Screenshots by Content

I have screenshots with generic timestamp names (e.g. `Screenshot 2025-09-03 at 14.13.34.png`).
Your job is to rename every file with a descriptive name based on what the screenshot actually shows.

## Naming Convention

YYYY-MM-DD.hh:mm.ss_[prefix]-short-description-sentence-or-tags-version.ext

- Extract the date from the original filename
- Use lowercase, hyphens between words
- Apply a category prefix based on context:
  - `p-` for personal files (health cards, personal forms, wallpapers, music, shopping)
  - `q-` for quorum.us (Zoom meetings, legislation scrapers, Sentry, Jenkins, Jira, Teleport, django)
  - `r-` for rabbit inc. (r1, intern, discord, Jesse Lyu)
  - `t-` for thoughtful.ai / PHS (Brightree, MaxRTE, Availity, EVA, insurance docs, PHS standups, payerlayer)
  - `g-` for grubhub (metasecapp, food delivery)
  - `teia-` for Teia Labs (athena, codesearch, allai, gauth, tauth)
  - Nesting is also useful: `p-<tool>-<tag>-<description>`
- Aim for completeness

## Examples

- `Screenshot 2025-10-24 at 12.54.47.png`
  -> `2025-10-24.12:54.47_t-maxrte-deep-dive-1.png`
- `Screenshot 2025-10-31 at 15.36.40.png`
  -> `2025-10-31.15:36.40_alpine-lake-landscape.png`

## Process

1. Glob all files in my Desktop and Pictures folders with the Screenshot prefix.
   1. Move all of them to `~/Pictures/Screenshots/`.
   2. Identify which ones already have good names (skip those) and which have generic timestamp names (process those).
2. Use subagents to view and rename files one by one.
   - Split the files into batches and launch multiple subagents in parallel for speed.
   - Each subagent should process its batch sequentially (view the image first, then rename) so descriptions are accurate.
3. Verify the final listing has zero generic names remaining and try to identify patterns, standardization opportunities, and room for improvement in general.

## Notes

- If two screenshots are nearly identical (e.g. taken seconds apart), number them with `-1`, `-2` suffixes
- If content is unrecognizable, just standardize the filename (e.g. `2025-10-31.15:36.40.png`) and move on.
