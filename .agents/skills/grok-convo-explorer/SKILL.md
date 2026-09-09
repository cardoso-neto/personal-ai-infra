---
name: grok-convo-explorer
description: Explore Grok conversations.
---

# Grok Convo Explorer

Verified against `grok 1.0.5 (5115b46bc909)` transcripts on 2026-09-09.
For execution and resume, see [Grok Handoff](../grok-handoff/SKILL.md).

## Files

Default session directory: `~/.grok/sessions/<percent-encoded-cwd>/<session-id>/`.
For example, `/Users/nei/project` becomes `%2FUsers%2Fnei%2Fproject`.
Find sessions by ID rather than assuming the working directory never changed.

- `summary.json`: `info:{id,cwd}`, `created_at`, `updated_at`, `current_model_id`, `chat_format_version`, `sandbox_profile`, and optional title/lineage fields.
  `num_messages` counts updates; `num_chat_messages` counts conversation records.
- `chat_history.jsonl`: model-facing conversation records, one JSON object per line.
- `updates.jsonl`: timestamped ACP notifications used for display and replay; includes text, tools, hooks, and other session activity.
- `events.jsonl`: lifecycle/telemetry events, such as turn starts, model loops, phases, and tool outcomes.
- `system_prompt.txt`, `prompt_context.json`: effective instructions and prompt context.
- `terminal/<tool-call-id>.log`: externalized terminal output; tool results can point here.
- `rewind_points.jsonl`: file-state rewind data, not conversation messages.

## Conversation records

`chat_history.jsonl` is a `type`-tagged union, without a shared timestamp/ID envelope.

- `system`: `content` string.
- `user`: `content:[{type:"text",text}|{type:"image",url}]`, optional `synthetic_reason`, `prompt_index`, `prior_turn_interrupt`.
  Prompts may have `<user_query>` wrappers.
  `synthetic_reason` distinguishes runtime injections, but its absence alone does not prove human authorship: the observed `<user_info>` preamble has no tag.
- `assistant`: `content` string, optional `tool_calls:[{id,name,arguments}]`, `model_id`, `model_fingerprint`, `reasoning_effort`.
  `arguments` is a JSON-encoded string, not an object.
- `tool_result`: `tool_call_id`, `content` string, optional `images` content parts.
  Join to `assistant.tool_calls[].id`.
- `reasoning`: provider reasoning item, commonly `id`, `summary:[{type:"summary_text",text}]`, optional encrypted content.
  Preserve sibling order; older formats may attach reasoning to the assistant instead.
- `backend_tool_call`: `kind` with `tool_type` and provider fields; a server-executed tool, not a local tool request.

Minimal text extraction, retaining injections for the reader to classify:

```sh
jq -r '
  if .type == "user" then "USER\t" + ([.content[] | select(.type == "text") | .text] | join("\n"))
  elif .type == "assistant" then "ASSISTANT\t" + .content
  else empty end
' "$session/chat_history.jsonl"
```

## Updates and telemetry

An `updates.jsonl` record has this envelope:

```json
{"timestamp":1788963342,"method":"session/update","params":{"sessionId":"...","update":{"sessionUpdate":"agent_message_chunk","content":{"type":"text","text":"Done."}},"_meta":{"eventId":"...","agentTimestampMs":1788963342584,"promptId":"..."}}}
```

- `timestamp`: Unix seconds; `_meta.agentTimestampMs`: milliseconds.
- `method`: `session/update` or extension `_x.ai/session/update`; older files may lack the envelope.
- `params.update.sessionUpdate`: discriminator.
  Text variants include `user_message_chunk`, `agent_message_chunk`, `agent_thought_chunk`; content is a typed block.
- `tool_call`: `toolCallId`, `title`, `rawInput`, optional `kind`, `status`, `content`, `locations`, `_meta`.
  Tool identity can be under `update._meta["x.ai/tool"].name`.
- `tool_call_update`: same `toolCallId`, partial status/output fields including `rawOutput` and `content`.
  Merge updates by call ID; terminal output can be both text content and bytes in `rawOutput.output`.
- Other variants include plans, usage, hooks, and compaction events; inspect their keys as needed.

`events.jsonl` uses `{ts:<RFC3339>,type:<snake_case>,...eventFields}`.
`turn_started` includes `session_id`, `turn_number`, `model_id`, `yolo_mode`, `session_relationship`, `schema_version`.
Follow `loop_started`, `phase_changed`, tool lifecycle, and turn outcomes for execution evidence.

Read in file order; event ID suffixes are not a global ordering key across resumes.
Chat history can be rewritten by compaction or rewind; it is current model context, not an immutable audit log.
Use updates and telemetry to understand the visible trajectory around those changes.
For lineage, inspect `summary.json` fields `parent_session_id`, `session_kind`, `forked_at`, `fork_context_source`, `fork_parent_prompt_id`, and `inherited_prefix_len` when present.
Inherited context is not newly authored child activity.

## Captured stdout

`--output-format streaming-json` is a different schema from all three disk JSONL files:

- `{type:"text"|"thought",data:<string>}`: incremental chunks.
- `tool_call` / `tool_call_update`: flattened ACP tool fields, including `toolName` on calls.
- `usage`: per-response metadata and usage; `plan` and `available_commands` carry their own fields.
- `end`: `stopReason`, `sessionId`, `requestId`, optional usage/cost fields; no final response text.
- `error`: `message`; `max_turns_reached` and `auto_compact_*` can also appear.

Do not parse `streaming-messages-json` with this schema; that option emits Messages-style `system`, `assistant`, `user`, and `result` records.

## Source definitions

Under `~/upstream/xai-org/grok-build/crates/codegen/`:

- `xai-grok-sampling-types/src/conversation.rs`: `ConversationItem`, content, tool, and synthetic-input types.
- `xai-grok-shell/src/session/persistence.rs`: `Summary` and lineage.
- `xai-grok-shell/src/session/storage/mod.rs`: `SessionUpdateEnvelope`; `storage/jsonl/mod.rs`: disk read/write behavior.
- `xai-grok-session-events/src/types.rs`: telemetry event union.
- `xai-grok-pager/src/headless.rs`: stdout projection and completion behavior.
