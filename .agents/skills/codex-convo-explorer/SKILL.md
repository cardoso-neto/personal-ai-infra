---
name: codex-convo-explorer
description: Explore, search, reconstruct, and audit local Codex conversations stored as rollout JSONL files under $CODEX_HOME or ~/.codex. Use for finding prior prompts or answers, inspecting tool activity and subagent lineage, extracting readable transcripts, checking history.jsonl, or discovering schema drift in Codex session files. Requires only filesystem access and ordinary JSON-processing or coding ability.
---

# codex-convo-explorer

Work directly from Codex's local files.
Do not require Codex itself or a service API.

The rollout format is a private implementation format, not a stable public API.
The schema below was checked against Codex CLI 0.147.0, current upstream source, and 100 recent local rollouts on 2026-08-10.
Discover the live schema before relying on exhaustive type lists.

## Locate the data

Resolve the root without changing `CODEX_HOME`:

```bash
codex_root="${CODEX_HOME:-$HOME/.codex}"
```

- `$codex_root/sessions/YYYY/MM/DD/rollout-<timestamp>-<thread-id>.jsonl`
  - Active conversation rollouts.
  - The filename timestamp uses dashes in the time portion.
- `$codex_root/archived_sessions/rollout-<timestamp>-<thread-id>.jsonl`
  - Archived conversations.
  - Search recursively; older or future versions can use a different layout.
- `$codex_root/history.jsonl`
  - Global user-input history.
  - Useful as an index, but not a complete transcript.
- `*.jsonl.zst`
  - Compressed rollout variant supported by current Codex.
  - Stream with `zstd -dc FILE.jsonl.zst`; do not edit the archive.

Do not depend on SQLite state or other derived indexes.
The rollout JSONL is the portable source available to an arbitrary coding agent.

## Work safely

Treat all files as private user data.
Do not print full records during schema discovery because prompts, reasoning, tool output, credentials, and environment context can be present.

Inspect sizes before reading:

```bash
find "$codex_root/sessions" "$codex_root/archived_sessions" \
  -type f \( -name 'rollout-*.jsonl' -o -name 'rollout-*.jsonl.zst' \) \
  -exec ls -lh {} + 2>/dev/null
```

Process rollouts one line at a time.
Recent rollouts can exceed 25 MB, and an individual line can contain a large tool result, image, world-state snapshot, or encoded payload.
Use `jq` projections or a streaming parser instead of loading a whole tree into memory.

## Current rollout envelope

Each line is one JSON object:

```json
{
  "timestamp": "2026-08-10T03:17:42.123Z",
  "ordinal": 123,
  "type": "response_item",
  "payload": {}
}
```

- `timestamp`
  - UTC ISO-8601 write time.
- `ordinal`
  - Optional monotonically increasing rollout position.
  - Older records can omit it.
- `type`
  - Top-level rollout-item discriminator.
- `payload`
  - Object whose schema depends on `type`.

The current serializer flattens the tagged rollout item into the line.
Do not expect a separate `item` property in the stored JSONL.

## Current top-level record types

### `session_meta`

Session identity and lineage.
Usually appears at the start of a rollout.

Important fields:

- `id`, `session_id`
  - Thread identifiers.
  - Current files normally contain both; older files can contain only `id`.
- `timestamp`, `cwd`, `originator`, `cli_version`, `source`, `thread_source`
  - Creation and client context.
- `model_provider`, `base_instructions`, `history_mode`, `context_window`
  - Model and history configuration.
- `git`
  - Optional `commit_hash`, `branch`, and `repository_url`.
- `forked_from_id`, `parent_thread_id`
  - Fork and subagent lineage.
- `agent_nickname`, `agent_role`, `agent_path`, `multi_agent_version`
  - Subagent identity.
- `history_base`
  - Optional inherited prefix in another thread.
  - Contains `thread_id`, `end_ordinal_exclusive`, and `end_byte_offset`.
- `subagent_history_start_ordinal`
  - First record belonging to a subagent's own projected history.

Do not assume the child rollout physically copies inherited history.
Follow `history_base` when the task requires exact fork or subagent reconstruction.

### `turn_context`

Effective context recorded for a user turn.

Current fields include `turn_id`, `cwd`, `workspace_roots`, `current_date`, `timezone`, `model`, `effort`, `approval_policy`, `approvals_reviewer`, `sandbox_policy`, `permission_profile`, `personality`, `collaboration_mode`, `multi_agent_version`, `realtime_active`, `summary`, and `comp_hash`.

Use `turn_id` to associate later items when available.
Treat all other fields as version-dependent context, not conversation text.

### `response_item`

Durable model input, model output, reasoning, and tool activity.
Its nested `payload.type` is a second discriminator.

Current nested types include:

- `message`
- `agent_message`
- `reasoning`
- `local_shell_call`
- `function_call`, `function_call_output`
- `custom_tool_call`, `custom_tool_call_output`
- `tool_search_call`, `tool_search_output`
- `web_search_call`
- `image_generation_call`
- `additional_tools`
- `compaction`, `compaction_trigger`, `context_compaction`

Unknown nested types are valid future or provider-specific data.
Retain them during structural analysis and skip them during a narrow transcript projection.

#### `response_item.message`

This is the primary source for a readable transcript:

```json
{
  "type": "response_item",
  "payload": {
    "type": "message",
    "role": "assistant",
    "content": [{"type": "output_text", "text": "..."}],
    "phase": "final_answer"
  }
}
```

- `role`
  - Currently includes `user`, `assistant`, and `developer`.
- `content`
  - `input_text` with `text`
  - `output_text` with `text`
  - `input_image` with `image_url` and optional `detail`
  - `input_audio` with `audio_url`
- `phase`
  - Optional for assistant messages.
  - Current values are `commentary` and `final_answer`.
  - Treat absence as unknown, not as proof that a message is final.
- `internal_chat_message_metadata_passthrough.turn_id`
  - Optional turn association.

For ordinary transcript extraction, select `message` items with role `user` or `assistant`, then join only `input_text` and `output_text` blocks.
Include `developer` only when the user asks for injected instructions or full model context.

#### `response_item.agent_message`

Inter-agent communication, not an assistant reply to the user.
It contains `author`, `recipient`, and content blocks of `input_text` or `encrypted_content`.
Exclude it from an ordinary transcript.
Include its readable `input_text` only when investigating delegation or subagent behavior.

#### Tool and reasoning items

- Calls use `call_id` to link to their output.
- Function-call `arguments` and custom-tool `input` are JSON encoded as strings.
- Tool output can be a plain string or structured content.
- Reasoning can contain summaries, plaintext detail, or only `encrypted_content`.

Do not treat tool output, reasoning, or encrypted content as user-visible conversation text.
Search them only when the user's question requires implementation evidence.

### `event_msg`

Lifecycle and presentation events.
Its nested `payload.type` includes variants such as `task_started`, `task_complete`, `item_completed`, `user_message`, `agent_message`, `token_count`, `thread_settings_applied`, `context_compacted`, `turn_aborted`, `sub_agent_activity`, and tool-specific events.

Many event messages mirror information already stored as `response_item` records.
Use them for timing, errors, token usage, status, and turn boundaries.
Do not combine their message text with `response_item.message` unless you intentionally deduplicate it.

### `compacted`

A context-compaction checkpoint.

- `message`
  - Summary used to replace older model context.
- `replacement_history`
  - Optional replacement `response_item` list.
- `window_number`, `first_window_id`, `previous_window_id`, `window_id`
  - Optional context-window lineage.

Do not present `message` as an assistant reply.
Use it only when reconstructing the model's effective post-compaction context.

### `world_state`

Persisted state used to resume context diffing.

- `full: true`
  - Establishes a full baseline.
- `full: false`
  - Applies a patch to the previous baseline.
- `state`
  - Arbitrary JSON value.

This can be large and can repeat data visible elsewhere.
Exclude it from ordinary transcript search unless the task concerns model-visible state.

### Inter-agent records

- `inter_agent_communication`
  - Legacy model-visible delivery item.
- `inter_agent_communication_metadata`
  - Local delivery metadata; currently includes `trigger_turn`.

Do not confuse either with user-facing assistant messages.

## `history.jsonl` schema

Each line contains:

```json
{"session_id":"<thread-id>","ts":1776347724,"text":"<submitted text>"}
```

- `session_id`
  - Links the input to a rollout thread.
- `ts`
  - Unix timestamp in seconds.
- `text`
  - Submitted input text.

Use this file to find what the user typed across threads.
Then inspect the matching rollout for responses and tool activity.

Do not treat it as complete:

- Persistence can be disabled.
- A configured byte limit can remove old entries.
- It contains inputs, not assistant responses or the full execution record.
- Structured inputs can require the rollout for faithful interpretation.

## Find conversations

Search literal text broadly first:

```bash
rg -l -i -F --glob 'rollout-*.jsonl' -- "$term" \
  "$codex_root/sessions" "$codex_root/archived_sessions"
```

This can match prompts, replies, reasoning, tool output, instructions, or world state.
Project the matching records before drawing conclusions.

Find sessions by working directory without printing their contents:

```bash
find "$codex_root/sessions" "$codex_root/archived_sessions" \
  -type f -name 'rollout-*.jsonl' \
  -exec jq -r --arg cwd "$PWD" '
    select(.type == "session_meta" and .payload.cwd == $cwd)
    | input_filename
  ' {} + 2>/dev/null
```

Extract the readable user/assistant transcript from one rollout:

```bash
jq -r '
  select(.type == "response_item" and .payload.type == "message")
  | select(.payload.role == "user" or .payload.role == "assistant")
  | [
      .timestamp,
      .payload.role,
      (.payload.phase // "unknown"),
      ([.payload.content[]?
        | select(.type == "input_text" or .type == "output_text")
        | .text] | join("\n"))
    ]
  | @tsv
' "$rollout"
```

For a final-answer-only view, keep assistant messages whose `phase` is `final_answer` and legacy assistant messages whose `phase` is absent.
Do not infer that `commentary` is the final response.

## Discover schema drift

Run discovery before writing a parser, after a Codex upgrade, or when known projections miss data.
Discovery must report keys and type names without printing values.

### Census recent files

Use a time-bounded sample first:

```bash
find "$codex_root/sessions" "$codex_root/archived_sessions" \
  -type f -name 'rollout-*.jsonl' -mtime -14 \
  -exec jq -r '[.type, (.payload.type // "<none>")] | @tsv' {} + \
  2>/dev/null | sort | uniq -c | sort -nr
```

Repeat across all files only when the bounded sample does not explain older data.

### Enumerate field sets

For one candidate rollout:

```bash
jq -r '
  [
    .type,
    (.payload.type // "<none>"),
    (keys_unsorted | sort | join(",")),
    ((.payload // {}) | keys_unsorted | sort | join(","))
  ]
  | @tsv
' "$rollout" | sort -u
```

This reveals optional-field combinations without exposing values.

### Enumerate message variants

```bash
jq -r '
  select(.type == "response_item" and .payload.type == "message")
  | [
      (.payload.role // "<missing>"),
      (.payload.phase // "<none>"),
      ([.payload.content[]?.type] | unique | join(","))
    ]
  | @tsv
' "$rollout" | sort | uniq -c | sort -nr
```

### Inspect a redacted representative record

```bash
jq -n '
  first(
    inputs
    | select(.type == "response_item" and .payload.type == $subtype)
    | .payload |= (
        del(.content, .output, .arguments, .input, .encrypted_content, .result)
        | with_entries(.value = "<redacted>")
      )
  )
' --arg subtype 'custom_tool_call' "$rollout"
```

Change `subtype` to inspect a newly discovered variant.
Keep field names; redact field values.

### Check integrity and line sizes

```bash
jq -Rr 'try (fromjson | empty) catch input_filename' "$rollout" | sort -u
awk '{ if (length > max) { max = length; line = NR } } END { print line, max }' "$rollout"
```

An empty first command means every non-empty line parsed as JSON.
The second prints the largest line number and byte-like character count.

### Update assumptions

When discovery differs from this document:

1. Prefer evidence from the user's actual files.
2. Preserve unknown records instead of failing the entire scan.
3. Make optional-field access tolerant with `.get`, `//`, or equivalent.
4. Separate structural discovery from content extraction.
5. Record the sampled Codex versions from `session_meta.payload.cli_version`.
6. Update this skill only after checking multiple recent rollouts and at least one older rollout when available.

If local Codex source is available, use it to explain observed fields, not to replace the JSONL audit.
The current canonical definitions are `RolloutLine` and `RolloutItem` in `codex-rs/protocol/src/protocol.rs`, `ResponseItem` in `codex-rs/protocol/src/models.rs`, and `HistoryEntry` in `codex-rs/message-history/src/lib.rs`.
