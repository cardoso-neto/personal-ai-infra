---
name: pi-convo-explorer
description: Inspect Pi session JSONL, reconstruct conversation branches, and interpret handoff event streams.
---

# Pi conversation explorer

Checked against Pi 0.81.1, session version 3, and a local tool-call/resume trajectory on 2026-09-09.

## Files and envelope

- `~/.pi/agent/sessions/<encoded-cwd>/<timestamp>_<session-id>.jsonl`: persisted conversation tree.
  - Encoding wraps the absolute cwd in `--`, removes its leading slash, and replaces remaining `/`, `\`, and `:` with `-`.
  - Read the header's `cwd` for the original path; encoding is lossy.
  - Filename timestamps replace ISO timestamp colons and periods with `-`.
- The first line is a header: `{type: "session", version: 3, id, timestamp, cwd, parentSession?}`.
  - `parentSession` is the source file path for a fork; the fork contains copied history.
- Later lines share `{type, id, parentId, timestamp, ...}`.
  - Entry IDs differ from the session UUID; `parentId: null` starts a branch root.
  - Envelope timestamps are ISO strings; message timestamps are epoch milliseconds.

Find a known session without reconstructing the cwd encoding:

```sh
rg --files --hidden "$HOME/.pi/agent/sessions" | rg -F -- "_${session_id}.jsonl"
```

## Record schema

- `message`: `message` holds one of the roles below.
  - `user`: `content` is a string or `text`/`image` block array; `timestamp`.
  - `assistant`: `content` is a block array; `provider`, `model`, `api`, `usage`, `stopReason`, `timestamp`, optional `errorMessage`, `responseId`, `responseModel`.
  - `toolResult`: `toolCallId`, `toolName`, `content`, `isError`, `timestamp`, optional `details`, `usage`.
  - `bashExecution`: `command`, `output`, `exitCode`, `cancelled`, `truncated`, optional `fullOutputPath`, `excludeFromContext`.
    - Records interactive `!`/`!!` commands; ordinary model bash calls use `toolCall` and `toolResult`.
- `model_change`: `provider`, `modelId`.
- `thinking_level_change`: `thinkingLevel`.
- `compaction`: `summary`, `firstKeptEntryId`, `tokensBefore`, optional `details`, `usage`, `fromHook`.
- `branch_summary`: `fromId`, `summary`, optional `details`, `usage`, `fromHook`.
- `custom_message`: `customType`, `content`, `display`, optional `details`.
  - Extension-injected model context; `display: false` hides it in the UI, not from the model.
- `custom`: `customType`, optional `data`; extension state, excluded from model context.
- `session_info`: optional `name`; latest name wins.
- `label`: `targetId`, optional `label`; bookmarks, with an absent label clearing one.

Content blocks:

- `text`: `text`, optional `textSignature`.
- `thinking`: `thinking`, optional `thinkingSignature`, `redacted`.
- `image`: base64 `data`, `mimeType`.
- `toolCall`: `id`, `name`, `arguments` object, optional `thoughtSignature`.
  - Join `id` to the result's `toolCallId`; arguments are already parsed JSON.

Assistant `stopReason` is `stop`, `length`, `toolUse`, `error`, or `aborted`.
`usage` contains `input`, `output`, `cacheRead`, `cacheWrite`, `totalTokens`, optional `reasoning`, and `cost.{input,output,cacheRead,cacheWrite,total}`.
Reasoning tokens are included in output; cost fields are estimates, not subscription charges.

## Branches and compaction

On reload, the last non-header entry is the leaf.
Follow `parentId` to the root and reverse that path for the selected branch; file order alone can mix branches.
The latest compaction on that path replaces older context with its summary, retains entries starting at `firstKeptEntryId` before the compaction, then includes entries after it.
Historical entries remain in the file.
Branch summaries carry context from the abandoned branch; they are not assistant replies.

For chronological user/assistant text across all branches:

```sh
jq -r '
  select(.type == "message")
  | select(.message.role == "user" or .message.role == "assistant")
  | [.timestamp, .message.role,
      (.message.content | if type == "string" then . else
        [.[] | select(.type == "text") | .text] | join("\n") end)]
  | @tsv
' "$session_file"
```

## Handoff stdout schema

`pi -p --mode json` emits JSONL with the same session header followed by runtime events, not persisted tree entries:

- `agent_start`, `agent_end`: the latter contains `messages` produced by the run.
- `turn_start`, `turn_end`: the latter contains `message`, `toolResults`.
- `message_start`, `message_end`: `message`; use `message_end` for completed messages.
- `message_update`: `assistantMessageEvent` with `type`, `contentIndex`, and delta-specific fields such as `delta`.
  - Pi 0.81.1 includes cumulative `message` and `assistantMessageEvent.partial`; newer source omits these snapshots and adds cumulative `usage`.
- `tool_execution_start`: `toolCallId`, `toolName`, `args`.
- `tool_execution_update`: the same identifiers plus `partialResult`.
- `tool_execution_end`: `toolCallId`, `toolName`, `result`, `isError`.
- Queue, compaction, and retry events expose lifecycle status; inspect their fields when needed.

Messages repeat across lifecycle events; choose one representation instead of concatenating them.
See [pi-handoff](../pi-handoff/SKILL.md) for invocation, persistence, and final-response extraction.

## Source definitions

The installed package's `dist/core/session-manager.d.ts`, `dist/core/messages.d.ts`, and dependency `@earendil-works/pi-ai/dist/types.d.ts` define the persisted schema.
Its `dist/modes/print-mode.js` defines stdout and exit behavior.
Local upstream is `~/upstream/badlogic/pi-mono`; newer session types live in `packages/agent/src/harness/session/`.
Compare installed definitions and actual records when they differ from [upstream JSON stream docs](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/json.md).
