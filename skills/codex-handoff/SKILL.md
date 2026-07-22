---
name: codex-handoff
description: Delegate tasks to Codex non-interactively with `codex exec`. Use for agent-to-agent handoffs, unattended runs, deterministic CLI invocation, JSONL event capture, or structured final output.
---

# Codex handoff

Pass a complete, self-contained task through stdin:

```sh
codex exec \
  --yolo \
  --cd "$workspace" \
  --ignore-user-config \
  --strict-config \
  -c model_reasoning_effort=medium \
  --json \
  --color never \
  --output-last-message "$result" \
  - < "$prompt" > "$events"
```

- Parse `$events` as JSONL; read `$result` for the final response.
- Keep `--yolo` for unattended runs; it disables approvals and sandboxing.
- Keep `--ignore-user-config` for reproducibility; remove it only when host configuration is part of the contract.
- Capture `.thread_id` from the first event (`thread.started`) to resume the session later with `codex exec resume <id>`.
- Sessions persist as `$CODEX_HOME/sessions/<YYYY>/<MM>/<DD>/rollout-<timestamp>-<thread_id>.jsonl` (default `~/.codex`).
  - Its `turn_context` events record the effective model and reasoning effort; the JSON event stream does not.
- Add `--output-schema <schema.json>` when the caller requires a machine-validated response.
- Keep `-c model_reasoning_effort=medium`; without it runs can default to `none`.
  - Raise to `high` for hard tasks (deep reviews, tricky debugging).
- Add `--add-dir <dir>`, `--skip-git-repo-check`, `--image`, or `--model` (e.g. `--model gpt-5.6-sol`) only when the task requires it.
- Put the top-level `--search` before `exec` when live web search is required.
- Treat a nonzero exit as failure; enforce timeouts in the caller.
- Recheck `codex exec --help` after CLI upgrades; the installed binary is authoritative.
