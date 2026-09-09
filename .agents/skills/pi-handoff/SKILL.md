---
name: pi-handoff
description: Delegate tasks to Pi.
---

# Pi handoff

Run from the workspace directory and pass a self-contained task through stdin.
Checked with Pi 0.81.1 on 2026-09-09.

```sh
set -o pipefail
pi -p \
  --mode json \
  --approve \
  --provider openai-codex \
  --model gpt-5.6-luna \
  --thinking low \
  < "$prompt" | tee "$events"
```

- Keep the raw JSONL stream in `$events`; callers can periodically inspect completed lines for messages and tool activity while Pi runs.
- The final `agent_end.messages[-1]` contains the response; read its `content` blocks of type `text`.
  - Check process status and the final message's `stopReason` / `errorMessage`; JSON mode can exit zero after a model error.
  - `stopReason: "stop"` indicates normal completion.
- `openai-codex` uses the OpenAI subscription login; `openai` selects API billing instead.
- Pi's built-in tools run without sandboxing or permission prompts.
  - `--approve` trusts project-local settings and extensions for this run; it is not a tool-permission bypass.
  - Extensions can add their own approval flows; inspect those if an unattended run blocks.
- Capture `.id` from the first `type: "session"` event.
  - Resume by adding `--session "$session_id"` to the same command with a follow-up prompt.
  - An existing session file path also works; `--resume` alone opens an interactive picker.
- Keep sessions in `~/.pi/agent/sessions/<encoded-cwd>/<timestamp>_<id>.jsonl`.
  - Never use `--no-session`, a temporary home, `--session-dir`, or overrides of `PI_CODING_AGENT_DIR` / `PI_CODING_AGENT_SESSION_DIR` for handoffs.
  - Verify the file exists there after the run; Pi defers its first disk write until an assistant message arrives.
- If `pi` is missing from a noninteractive shell, load the user's nvm default (`source "$HOME/.nvm/nvm.sh"; nvm use default >/dev/null`) or resolve its installed binary.
- Recheck `pi --help` after upgrades; use [pi-convo-explorer](../pi-convo-explorer/SKILL.md) for stream and transcript schemas.
