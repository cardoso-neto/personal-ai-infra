---
name: claude-handoff
description: Delegate tasks to Claude Code non-interactively with `claude -p`. Use for agent-to-agent handoffs, unattended runs, deterministic CLI invocation, JSONL event capture, or structured final output.
---

# Claude handoff

Run from the workspace directory (there is no `--cd` flag) and pass a complete, self-contained task through stdin:

```sh
cd "$workspace" && claude -p \
  --dangerously-skip-permissions \
  --output-format json \
  < "$prompt" > "$result"
```

- Parse `$result`: take the `"type": "result"` object (a bare object, or the last element of a message array when verbose is on); `.result` is the final response, `.is_error` the failure flag.
- Keep `--dangerously-skip-permissions` for unattended runs; it disables all approval prompts.
- Capture `.session_id` to resume the session later with `-r <id>`.
- Swap `--output-format json` for `--output-format stream-json --verbose` when JSONL event capture is required; the last line is the same result object.
- Add `--json-schema <json>` when the caller requires a machine-validated response; read it from `.structured_output`.
- Add `--add-dir <dir>`, `--model <model>`, `--max-budget-usd <amount>`, or `--fallback-model <model>` only when the task requires it.
- Add `--setting-sources ""` when host configuration must not leak into the run.
- Treat a nonzero exit as failure; enforce timeouts in the caller.
- Recheck `claude --help` after CLI upgrades; the installed binary is authoritative.
