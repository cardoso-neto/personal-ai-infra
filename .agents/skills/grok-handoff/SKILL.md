---
name: grok-handoff
description: Delegate tasks to Grok Build non-interactively with persistent sessions and full permissions.
---

# Grok handoff

Verified with `grok 1.0.5 (5115b46bc909)` on 2026-09-09.
Pass a self-contained task in a file; `--prompt-file` starts headless execution.

```sh
grok --cwd "$workspace" \
  --model grok-build-0.1 \
  --permission-mode bypassPermissions --sandbox off --no-plan \
  --output-format json --prompt-file "$prompt" \
  > "$result" 2> "$errors"
grok_status=$?
jq -r '.text // empty' "$result"
grok_session=$(jq -r '.sessionId // empty' "$result")
```

- `bypassPermissions` auto-approves tool execution; `--sandbox off` removes filesystem/network confinement; `--no-plan` permits implementation.
  Configured deny rules, hooks, some shell ask rules, and administrator locks still apply.
- Keep the default `~/.grok` home and durable `~/.grok/sessions/<encoded-cwd>/<session-id>/` files.
  Never use an alternate home, temporary session storage, or relocate the session to the output directory.
  Verify `summary.json` and `chat_history.jsonl` exist there.
- `grok-build-0.1` was the cheapest available text model at verification.
  Check `grok models` and [official pricing](https://docs.x.ai/developers/pricing) when selecting a different model; the configured default may cost more.
- `--no-subagents --disable-web-search` can keep small smoke tests cheap.
  `--max-turns N` bounds model rounds, not user messages; hitting it can stop before a final answer.
  Choose a cap for the task rather than applying the smoke-test cap to real work.

## Resume

```sh
grok --cwd "$workspace" \
  --model grok-build-0.1 \
  --permission-mode bypassPermissions --sandbox off --no-plan \
  --resume "$grok_session" \
  --output-format json --prompt-file "$followup" \
  > "$result" 2> "$errors"
```

`--resume UUID` appends to the same session; `--continue` selects the latest session for the directory.
`--session-id UUID` creates a new session with a chosen ID; it does not resume.
The saved sandbox profile is fixed for a session; resume rejects a conflicting profile.

## Output contract

- Success JSON: `text`, `stopReason`, `sessionId`, `requestId`, optional `thought`, `usage`, `num_turns`, `modelUsage`, and cost fields.
  `text` accumulates assistant text from the invocation, including any intermediate narration.
- Check the process status and `stopReason`; `end_turn` is a normal completion.
  Errors may emit `{type:"error",message:...}` or an incomplete result plus stderr.
  The tested turn cap exited 1 with `stopReason:"cancelled"`.
- `total_cost_usd` and integer `total_cost_usd_ticks` are optional; missing cost does not mean free.
  `cost_is_partial` and `usage_is_incomplete` mark incomplete accounting.
- For live events, use `--output-format streaming-json` and capture raw stdout as JSONL.
  The final `end` record has metadata, not the response text.
  Its schema and the separate disk formats are in [Grok Convo Explorer](../grok-convo-explorer/SKILL.md).

Recheck `grok --help` after upgrades.
The source guide is `~/upstream/xai-org/grok-build/crates/codegen/xai-grok-pager/docs/user-guide/14-headless-mode.md`.
