---
name: ramblings
description: Captain's log / voice journal transcription system.
---
# ramblings

Voice-first journaling. User dictates; agent transcribes verbatim.

## structure

- ~/ramblings/
  - daily-log/
    - YYYY-MM-DD.md (one file per day, ISO date format)
  - .git/ (local tracking)

## file format

```md
# YYYY-MM-DD

## HH:MM

Verbatim transcription here. No summarizing, no fixing grammar or speech quirks.

> [Vigilius: Agent observations go here if needed. Corrections, context notes, links to memory.]

## HH:MM (later entry)

Another dictation block.
```

## rules

- Transcribe exactly as spoken; preserve repetitions, filler words, incomplete thoughts.
- Don't "clean up" the user's words; that defeats the purpose.
- Agent notes go in blockquotes with `> [Vigilius: ...]` so they're visually distinct.
- Use 24-hour time format (HH:MM).
- One file per calendar day; multiple entries get separate `## HH:MM` sections.
- Git commit after each session with message: `YYYY-MM-DD: brief description`.

## when to use

- User sends voice message asking to log/journal/ramble.
- User explicitly says "add to ramblings" or "captain's log".
- Don't auto-log random voice messages; wait for intent.
