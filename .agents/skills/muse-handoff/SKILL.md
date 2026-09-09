---
name: muse-handoff
description: Delegate tasks to Muse.
---

# Muse handoff

Checked with Muse Code `0.1.0-R708.1` on 2026-09-09.
Pass a self-contained task through a prompt file.

```sh
set -o pipefail
muse exec \
  --json \
  --yolo \
  --workspace "$workspace" \
  --model muse-spark-1.2 \
  --reasoning-effort medium \
  --prompt-file "$prompt" \
  2> "$errors" | tee "$events"
```

- Keep the raw JSONL stream in `$events`; callers can periodically inspect completed lines for progress while Muse runs.
- `--yolo` disables approval and sandboxing and trusts workspace skills/rules for this run.
- Capture `stream.id` from a record whose `stream.kind` is `session`.
  - Resume by adding `--session-id "$session_id"` to the same command with a follow-up prompt.
  - `muse resume` is the interactive entrypoint; `exec --session-id` restores history for unattended follow-ups.
- The final event with `payload.kind: "run_terminal"` contains `payload.terminal`, `payload.text`, and `payload.reason`.
  - Require process success and `terminal: "completed"`; a failed run can still contain successful task events.
  - Correlate `payload.run_stream.id` when inspecting logs with multiple runs.
- Keep durable logs in `~/.local/share/muse/sessions/YYYY/MM/DD/<session-id>/session.jsonl`.
  - Never use `--no-session-log`, a temporary home, or storage-root overrides for handoffs.
  - Verify the log exists there; the captured stdout is a separate projection of the session.
- `--max-model-steps N` can bound smoke tests; reaching the cap fails the run.
  `--disable-web-tools` can avoid web calls during small tests.
- Recheck `muse exec --help` after upgrades; see [muse-convo-explorer](../muse-convo-explorer/SKILL.md) for event and transcript schemas.

The public [SDK source](https://github.com/meta-models/muse-code-sdk) is cloned at `~/upstream/meta-models/muse-code-sdk`.
It includes MSP client/protocol definitions, not the Muse host implementation; installed CLI help and observed records define this handoff.
