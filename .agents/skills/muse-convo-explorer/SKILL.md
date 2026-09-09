---
name: muse-convo-explorer
description: Explore Muse conversations.
---

# Muse conversation explorer

Checked against Muse Code `0.1.0-R708.1` local records on 2026-09-09.
For execution and resume, see [Muse Handoff](../muse-handoff/SKILL.md).

## Files

Default data directory on this installation: `~/.local/share/muse/`.

- `sessions/YYYY/MM/DD/<session-uuid>/session.jsonl`: durable event log.
- `sessions/.../<session-uuid>/subagent/<child-uuid>/session.jsonl`: child logs, including automatic reminder agents.
- `session-index.db`: SQLite discovery index; `sessions` includes `session_id`, `session_log_path`, `workspace_root`, `model_id`, `title`, `updated_at_us`.
- `tui-history.jsonl`: JSON strings for input recall, including slash commands; no session linkage or timestamps.
- `.session.lock`, `cron.db` and SQLite sidecars: runtime state, not conversation text.

## Durable envelope

Each JSONL record has:

```json
{"schema_version":1,"id":"...","stream":{"kind":"session","id":"..."},"sequence":1,"recorded_at":1788960000000000,"record_type":"event","durability":"durable","causation_id":null,"payload_type":"runtime.session","payload_schema_version":1,"payload":{"kind":"run","run_id":"...","event":{"kind":"started","prompt":"..."}}}
```

`recorded_at` is Unix microseconds.
`sequence` belongs to its stream; preserve file order and stream identity.
The session UUID differs from run/task IDs and provider response IDs.

`payload.kind` selects the wrapper:

- `metadata`: `record.{build,workspace_root,provider_id,model_id?,tool_surface_version,web_search_mode}`.
- `run_model`: `record.{run_stream,command_id,model_id,provider_id,source,...}`; records per-run model selection.
- `run`: `run_id`, `event`; mirrored records may include `source_run_record_id`, `source_run_record_sequence`.
- `task`: `run_id`, `task_id`, `event`.
- Other wrappers include `security_mode`, `agent_tree_initialized`, `session_opened`, `session_end`, and lifecycle observations.
  Inspect `event` or `record` according to the wrapper; `payload_type` alone does not identify a message.

## Conversation and tools

For `payload.kind == "run"`, `payload.event.kind` selects:

- `started`: `prompt` string, the submitted run input.
- `assistant_message_committed`: `text`, `message_id`, `response_id`, optional `provider_item_id`.
- `reasoning_committed`: `text`, `message_id`, `response_id`, `provider_item_id`, `encrypted_content`.
- `assistant_tool_calls_committed`: `message_id`, `response_id`, `tool_calls:[{id,call_id,name,args}]`.
  `args` is a JSON-encoded string; join `call_id` to result `tool_call_id`, not provider item `id`.
- `tool_result_batch_committed`: `batch_id`, `results:[{tool_call_id,tool_call_index,text}]`.
- `model_completed`: `model`, `duration_ms`, optional `finish_reason`, `usage`.
  Usage fields include `input_tokens`, `output_tokens`, `cached_tokens`, `cache_read_tokens`, `cache_write_tokens`, `reasoning_tokens`.
- `terminal`: `terminal`, optional `reason` and timing fields; run outcome, not an assistant message.
- `model_request_configured`: `base_instructions`, `run_context_messages`, `toolset`, and provenance.
  These are injected model context, not newly authored user messages.

Task events use lifecycle kinds such as `proposed`, `accepted`, `started`, `completed`, `cancelled`, `rejected`, plus `status` and `output`.
`output.chunk` carries incremental tool output; committed tool results carry model-facing results.

## Reconstruction and export

Select committed messages for transcript text rather than concatenating every rendering or lifecycle event.
Group runs by `run_id`; task links carry `task_id` and `task_stream`.
Child-session links can carry `parent_session_id`, `parent_run_id`, `child_session_id`, and `child_session_log_path`.
Automatic reminder-agent logs are separate conversations.

Use the built-in offline projections for lineage, copied context, gaps, and records outside the observed schema:

```sh
muse export --session "$session_id" --out "$export_file"
muse trace inspect --session-log "$session_file" --all-runs --format json
```

Export is one JSON document, not JSONL: `export_schema_version:1`, `sessions`, `events`, `diagnostics`, build and redaction metadata.
Observed `events[]` entries have `{kind:"record",recorded_at,envelope,derived}`.
`envelope` retains the original durable record; `derived` includes `decoded`, `session_id`, `trajectory_id`, `step_id`, `turn_count`, optional `model`.
`sessions[]` includes `session_id`, `root_session_id`, `trajectory_id`, `is_copied_context`, turn/step counts and termination metadata.
`diagnostics` reports gaps, duplicate records, omitted live-only events and unparseable lines.
Export defaults to raw payloads; `--redacted` applies telemetry redaction, preserving encrypted reasoning blobs.
Compaction's durable record shape was not observed in this check; do not infer active model context from the complete event log.

## Stdout and SDK schemas

`muse exec --json` uses the same envelope fields with a different payload projection.
Its `payload.kind` is flattened: `run_started`, `turn_input_user`, `run_model_configured`, `run_output_delta`, `tool_result`, `task_lifecycle`, `run_terminal`, and other events.
`run_output_delta.text` is incremental; the terminal event contains the completed text.
`tool_result` has `call_id`, `text`, `run_stream`, `command_id`; `run_terminal` has `terminal`, `text`, optional `reason`.
Do not apply the disk `.payload.event.kind` selector to stdout.

The public [Muse Code SDK](https://github.com/meta-models/muse-code-sdk) is cloned at `~/upstream/meta-models/muse-code-sdk`.
Its `schema/msp/msp.d.ts` defines MSP JSON-RPC notifications and projected items (`itemId`, `kind`, `turnId`, `revision`, `status`), not CLI stdout or durable JSONL.
MSP history snapshots, cursors and compaction anchors belong to that protocol.
The public repository does not contain the CLI's durable-log implementation; the installed `muse export --help`, `muse trace inspect --help`, and actual records are the references for this version.
