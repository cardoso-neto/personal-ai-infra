---
name: claude-handoff
description: Delegate tasks to Claude Code non-interactively with `claude -p`. Use for agent-to-agent handoffs.
---

# Claude handoff

Run from the workspace directory and pass a complete, self-contained task through stdin.

## Invoke

Keep the complete event stream and show the caller a small live view:

```sh
set -o pipefail
claude -p \
  --dangerously-skip-permissions \
  --output-format stream-json \
  --verbose \
  < "$prompt" \
  | tee "$events" \
  | jq --unbuffered -c '
      if .type == "assistant" then
        [
          .message.content[]?
          | select(.type == "text" or .type == "tool_use")
          | if .type == "tool_use" then
              if .name == "Workflow" then
                {type, name}
              else
                {type, name, input}
              end
            else
              {type, text}
            end
        ] as $content
        | select($content | length > 0)
        | {type, content: $content}
      elif .type == "system" and .subtype == "init" then
        {type, subtype, session_id}
      elif .type == "system" and .subtype == "task_started" then
        {type, subtype, task_id, workflow_name, description}
      elif .type == "system" and .subtype == "task_progress" and (.workflow_progress? != null) then
        {
          type,
          subtype,
          task_id,
          agents: (
            [.workflow_progress[] | select(.type == "workflow_agent") | .state]
            | group_by(.)
            | map({key: .[0], value: length})
            | from_entries
          )
        }
      elif .type == "system" and .subtype == "task_notification" then
        {type, subtype, task_id, status, summary, output_file}
      elif .type == "result" then
        {type, subtype, is_error, session_id, duration_ms, duration_api_ms}
      else
        empty
      end
    '
```

- `$events` is the source of truth.
  - Extract its last `"type": "result"` event after the process exits.
  - The live filter omits the duplicate response body from the `result` event.
- Keep `--dangerously-skip-permissions` for unattended runs; it disables all approval prompts.
- Capture `.session_id` to resume the session later with `-r <id>`.
- Add `--json-schema <json>` when the caller requires a machine-validated response; read it from `.structured_output`.
- Add `--model <model>`.
- Do not enable `--include-partial-messages`.
  - Token deltas add noise without improving task-level observability.
- Do not enable `--forward-subagent-text` by default.
  - A large fan-out can flood the parent with every child's text and thinking.
  - Enable it when monitoring subagents is useful.

## Progress and large results

- Poll a task-owned journal or status artifact when provided.
- For Claude Workflows, inspect `task_progress` events and read `task_notification.output_file`.
- Full trajectories are stored at `~/.claude/projects/**/*.jsonl`.
- Give large results an output path in the prompt and validate it after completion.

## Failure handling

- Preserve `$events`, the task journal, and the result file on failure for diagnosis.
- Recheck `claude --help` after CLI upgrades; the installed binary is authoritative.
