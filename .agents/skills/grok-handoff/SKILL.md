---
name: grok-handoff
description: Delegate tasks to Grok.
---

# Grok handoff

CLI behavior verified with `grok 1.0.5 (5115b46bc909)` using `grok-build-0.1` on 2026-09-09.
Pass a self-contained task in a file; `--prompt-file` starts headless execution.

```sh
set -o pipefail
grok --cwd "$workspace" \
  --model grok-4.6 \
  --permission-mode bypassPermissions --sandbox off --no-plan \
  --output-format streaming-json --prompt-file "$prompt" \
  2> "$errors" | tee "$events"
```

- `bypassPermissions` auto-approves tool execution; `--sandbox off` removes filesystem/network confinement; `--no-plan` permits implementation.
  Configured deny rules, hooks, some shell ask rules, and administrator locks still apply.
- Keep the default `~/.grok` home and durable `~/.grok/sessions/<encoded-cwd>/<session-id>/` files.
  Never use an alternate home, temporary session storage, or relocate the session to the output directory.
  Verify `summary.json` and `chat_history.jsonl` exist there.
- Use a cheap model for smoke tests; check `grok models` and [official pricing](https://docs.x.ai/developers/pricing).
- `--no-subagents --disable-web-search` can keep small smoke tests cheap.
  `--max-turns N` bounds model rounds, not user messages; hitting it can stop before a final answer.
  Choose a cap for the task rather than applying the smoke-test cap to real work.

## Resume

```sh
grok --cwd "$workspace" \
  --model grok-4.6 \
  --permission-mode bypassPermissions --sandbox off --no-plan \
  --resume "$grok_session" \
  --output-format streaming-json --prompt-file "$followup" \
  2> "$errors" | tee "$events"
```

`--resume UUID` appends to the same session; `--continue` selects the latest session for the directory.
`--session-id UUID` creates a new session with a chosen ID; it does not resume.
The saved sandbox profile is fixed for a session; resume rejects a conflicting profile.

## Output contract

- Keep the raw JSONL stream in `$events`; callers can periodically inspect completed lines for text and tool activity while Grok runs.
- `text` and `thought` events carry incremental strings in `data`; concatenate `text.data` for assistant text, including intermediate narration.
- The final `end` event contains `stopReason`, `sessionId`, `requestId`, and optional usage/cost fields, but no response text.
  Capture its `sessionId` as `$grok_session` for resume.
- Check the process status and the final `end.stopReason`; `end_turn` is a normal completion.
  Errors may emit `{type:"error",message:...}` or an incomplete result plus stderr.
  The tested turn cap exited 1 with `stopReason:"cancelled"`.
- `total_cost_usd` and integer `total_cost_usd_ticks` are optional; missing cost does not mean free.
  `cost_is_partial` and `usage_is_incomplete` mark incomplete accounting.
- Stream and disk schemas are in [Grok Convo Explorer](../grok-convo-explorer/SKILL.md).

Recheck `grok --help` after upgrades.
The source guide is `~/upstream/xai-org/grok-build/crates/codegen/xai-grok-pager/docs/user-guide/14-headless-mode.md`.
