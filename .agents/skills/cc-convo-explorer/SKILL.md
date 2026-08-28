---
name: cc-convo-explorer
description: Explore, search, and reconstruct Claude Code conversations stored under ~/.claude/projects/ and ~/.claude/history.jsonl. Use for transcript forensics, finding prior prompts or tool calls, inspecting session and subagent metadata.
---

# Claude Code conversation explorer

Treat the format as an append-only event log, not a stable public API.
Inspect recent local records before relying on an exact field or enum value.

## Locate the data

- `~/.claude/projects/{encoded-project-path}/`
  - `{session-id}.jsonl`: main session event log.
  - `{session-id}/`: optional ancillary data for that session.
    - `subagents/agent-{id}.jsonl`: subagent event log.
    - `subagents/agent-{id}.meta.json`: optional subagent metadata.
      - Recent files can include `agentType`, `description`, `model`, `name`, `parentAgentId`, `spawnDepth`, `toolUseId`, `worktreeBranch`, and `worktreePath`.
      - Do not assume that all fields are present.
    - `subagents/workflows/wf_{id}/`: workflow subagent logs, metadata, and `journal.jsonl` files.
    - `tool-results/`: externalized tool-result payloads.
      - Payloads can be text or binary files; do not parse the directory as JSONL.
    - `workflows/`: workflow state and scripts.
  - `sessions-index.json`: optional project index.
  - `memory/`: project memory files, not conversation records.
- `~/.claude/history.jsonl`: user input history across projects.

Some older records use other layouts or types.
Discover what exists instead of requiring every path above.

### Path encoding

Claude Code normally replaces each character outside ASCII letters and digits in the absolute project path with `-`.
It does not collapse adjacent replacements.

- `/home/user/company/proj` -> `-home-user-company-proj`
- `/home/user/.claude` -> `-home-user--claude`
- `/home/user/svc_410439` -> `-home-user-svc-410439`

Do not reverse an encoded name to obtain the original path; the encoding is lossy.
Use `sessions-index.json.originalPath`, `history.jsonl.project`, or a record's `cwd` when available.
A relocated session can remain under its original project directory while later records contain a different `cwd`.

If the session ID is known, avoid path reconstruction:

```bash
find ~/.claude/projects -maxdepth 2 -type f -name "$SESSION_ID.jsonl" -print
```

## Inspect safely

- Check file size before opening a transcript.
  - Main logs can reach tens of megabytes.
  - A single JSONL line can contain a very large tool result.
- Parse one line at a time.
  - `Path.read_text().splitlines()` materializes the complete file and every large line.
- Project large records to the required fields before displaying them.
- Search main sessions and subagents separately unless the task needs both.
  - Subagent logs repeat delegated context and can dominate results.
- Exclude `history.jsonl`, workflow journals, and `tool-results/` from a conversation-record census.

```bash
ls -lh "$SESSION_FILE"
awk 'NR == 5 { print length; exit }' "$SESSION_FILE"
jq -c 'del(.message.content, .toolUseResult, .attachment)' "$SESSION_FILE" | head
```

## Understand the event graph

Conversation records usually contain `uuid` and `parentUuid`.
The file order is event order, but the parent links form the conversation graph.
Retries, edits, forks, and resumes can create branches.

- `parentUuid: null` usually identifies a root record.
  - It does not identify every user-authored prompt.
- The latest `last-prompt.leafUuid`, when present, identifies the current leaf.
  - Trace `parentUuid` backward to reconstruct that branch.
- A chronological scan is suitable for activity history, but it can mix branches.

The common envelope is not universal.
Conversation, attachment, and system events commonly include:

- `type`, `uuid`, `parentUuid`, `timestamp`.
- `sessionId`, `cwd`, `gitBranch`, `version`, `entrypoint`.
- `isSidechain`, `userType`.
- Optional execution context such as `session_id`, `slug`, `sessionKind`, `teamName`, `agentName`, and `agentId`.

Main records normally have `isSidechain: false`; subagent records normally have `isSidechain: true` and an `agentId`.
Do not hardcode Claude Code versions, model IDs, entrypoints, tool names, or optional envelope fields.

## Interpret record types

### `user`

This type has three important shapes:

- User or injected text.
  - `message.content` is a string or a list containing `text`, `image`, or `document` blocks.
  - Normal follow-up prompts usually have a non-null `parentUuid`.
- Tool results.
  - `message.content` contains `tool_result` blocks.
  - `toolUseResult` often contains the richer structured result.
  - Large results can use a `<persisted-output>` reference and `persistedOutputPath` under `toolUseResult`.
- Meta or generated input.
  - `isMeta`, `isCompactSummary`, `isVisibleInTranscriptOnly`, `promptSource`, and `origin.kind` help distinguish human input from compaction summaries, command expansions, hooks, task notifications, and agent coordination.

Recent human-authored records can use `promptSource: typed` or `queued` and `origin.kind: human`, but older records often omit these fields.
Do not use `parentUuid is null` as a prompt filter.

### `assistant`

`message.content` is a list of blocks, commonly:

- `thinking`: `thinking`, `signature`.
- `text`: response text.
- `tool_use`: `id`, `name`, `input`, and sometimes `caller`.

The message can also contain `model`, `id`, `stop_reason`, `stop_details`, `usage`, diagnostics, and context-management data.
Usage fields change over time; inspect the live key set before computing costs or token totals.

Top-level attribution can include `attributionSkill`, `attributionAgent`, `attributionMcpServer`, or `attributionMcpTool`.

### `queue-operation`

This type records queue lifecycle, not only delivered conversation turns.

```json
{"type":"queue-operation","operation":"enqueue","sessionId":"...","timestamp":"...","content":"queued text"}
```

- `enqueue`: has `content`.
- `dequeue`: normally omits `content`.
- `remove`: has the removed `content` in recent records.
- `popAll`: has popped `content` in recent records.

Queue text can duplicate a later `user` record.
It can also represent input that was removed before delivery.
Use it to investigate queue behavior, not as the canonical transcript.

### `attachment`

`attachment.type` identifies injected context.
Common recent values include:

- `task_reminder`, `skill_listing`, `invoked_skills`, `dynamic_skill`.
- `deferred_tools_delta`, `agent_listing_delta`, `team_context`.
- `hook_success`, `hook_additional_context`, `hook_non_blocking_error`.
- `edited_text_file`, `file`, `compact_file_reference`, `nested_memory`.
- `command_permissions`, `date_change`, `read_truncation_notice`.
- `queued_command`.
  - `attachment.prompt` contains queued text and often duplicates a queue event.

Treat the enum as open-ended.

### `system`

System events are keyed by `subtype`.
Recent values include `stop_hook_summary`, `turn_duration`, `compact_boundary`, `local_command`, `agents_killed`, and informational or consent events.
Fields vary by subtype.

Older logs can contain `progress` records for streaming tool and agent status.
Recent builds might not persist them.

### Metadata and bookkeeping

These records are small but can occur repeatedly as state changes:

- `last-prompt`: `leafUuid` and optional `lastPrompt`.
  - Use the last record; `lastPrompt` can be absent.
- `ai-title`, `custom-title`, `agent-name`.
- `pr-link`.
- `permission-mode`, `mode`, `agent-setting`.
- `bridge-session`, `relocated`, `worktree-state`, `frame-link`.
- `file-history-snapshot`, `file-history-delta`.

Older or specialized logs can also contain `fork-context-ref`, `progress`, and other types.
Skip unknown types only after inspecting their keys.

Workflow `journal.jsonl` files use their own schema, such as `started` and `result` records.
They are not conversation logs.

## Extract user-authored text

Choose the source based on the question:

1. Delivered conversation turns: textual `user` records in the session JSONL.
2. Current visible branch: trace parents from the latest `last-prompt.leafUuid`, then select textual `user` records on that branch.
3. Everything typed across projects: `~/.claude/history.jsonl`.
4. Queue forensics, including removed input: `queue-operation` and `queued_command` attachments.

The following extractor returns delivered textual user turns in event order.
It excludes common generated inputs while retaining records from older versions that lack provenance fields:

```python
import json
from collections.abc import Iterable
from pathlib import Path

GENERATED_PREFIXES = (
    "<bash-input>",
    "<bash-stdout>",
    "<command-message>",
    "<command-name>",
    "<local-command-caveat>",
    "<local-command-stdout>",
    "<system-reminder>",
    "<task-notification>",
    "<teammate-message>",
)


def text_blocks(content: object) -> list[str]:
    if isinstance(content, str):
        return [content.strip()] if content.strip() else []
    if not isinstance(content, list):
        return []
    has_tool_result = any(
        isinstance(block, dict) and block.get("type") == "tool_result"
        for block in content
    )
    if has_tool_result:
        return []
    return [
        block["text"].strip()
        for block in content
        if isinstance(block, dict)
        and block.get("type") == "text"
        and isinstance(block.get("text"), str)
        and block["text"].strip()
    ]


def user_text(record: dict) -> list[str]:
    generated_record = any(
        record.get(field)
        for field in ("isMeta", "isCompactSummary", "isVisibleInTranscriptOnly")
    )
    if record.get("type") != "user" or generated_record:
        return []
    origin = record.get("origin")
    origin_kind = origin.get("kind") if isinstance(origin, dict) else None
    if origin_kind in {"coordinator", "task-notification"}:
        return []
    if record.get("promptSource") == "system":
        return []
    texts = text_blocks(record.get("message", {}).get("content"))
    known_human_source = record.get("promptSource") in {"typed", "queued", "sdk"}
    if known_human_source or origin_kind == "human":
        return texts
    return [text for text in texts if not text.lstrip().startswith(GENERATED_PREFIXES)]


def session_user_messages(path: str | Path) -> Iterable[tuple[str, str]]:
    with Path(path).open() as lines:
        for line in lines:
            if not line.strip():
                continue
            record = json.loads(line)
            for text in user_text(record):
                yield record.get("timestamp", ""), text
```

This is a practical heuristic, not a guaranteed authorship classifier.
When provenance matters, inspect `promptSource`, `origin`, command-related XML wrappers, and nearby queue events.

## Use `history.jsonl`

Recent history records have this shape:

```json
{"display":"typed text","pastedContents":{},"project":"/abs/path","sessionId":"uuid","timestamp":1765934747869}
```

- `display`: typed text.
  - Pasted blocks can appear as placeholders such as `[Pasted text #1 +N lines]`.
- `project`: absolute project path.
- `sessionId`: present on recent records, but older records can omit it.
- `timestamp`: epoch milliseconds.
- `pastedContents`: map keyed by paste number.
  - Inline variant: `content` contains the text.
  - Reference variant: `contentHash` replaces the inline content.
    - The history record does not identify a location from which to resolve the hash.
    - Use the delivered session `user` record when the full paste is required.
  - Paste entries also have `id` and `type`; `id` can be null.

Stream the file and preserve the placeholders unless the inline paste content is available:

```python
import json
from collections.abc import Iterable
from pathlib import Path


def typed_messages(project_path: str) -> Iterable[tuple[int, str]]:
    history = Path("~/.claude/history.jsonl").expanduser()
    with history.open() as lines:
        for line in lines:
            record = json.loads(line)
            if record.get("project") == project_path:
                yield record.get("timestamp", 0), record.get("display", "")
```

`history.jsonl` is an input history, not the exact delivered transcript.
Slash commands, interrupted input, and abbreviated pastes can appear there.

## Use optional session indexes

When present, `sessions-index.json` is a cheap way to list sessions without parsing their message bodies.
Recent indexes contain:

- Top-level `version`, `originalPath`, and `entries`.
- Entry fields such as `sessionId`, `fullPath`, `projectPath`, `firstPrompt`, `summary`, `messageCount`, `created`, `modified`, `fileMtime`, `gitBranch`, and `isSidechain`.

The index can be absent or stale.
Confirm important results against the JSONL.

## Search and inspect

Prefer `rg` for candidate selection and `jq` for JSON parsing.
Do not depend on JSON whitespace when correctness matters.

```bash
head -1 "$SESSION_FILE" | jq -c 'keys'
rg -m1 -F '"type":"user"' "$SESSION_FILE" | jq
rg -m1 -F '"type":"assistant"' "$SESSION_FILE" | jq 'del(.message.content, .toolUseResult)'
jq -r '.type // "<missing>"' "$SESSION_FILE" | sort | uniq -c | sort -rn
jq -r 'select(.type == "system") | .subtype // "<missing>"' "$SESSION_FILE" | sort -u
jq -r 'select(.type == "attachment") | .attachment.type // "<missing>"' "$SESSION_FILE" | sort -u
```

Search only main session files for a first pass:

```python
import json
from collections.abc import Iterable
from pathlib import Path


def search_main_sessions(
    base_path: str | Path, keyword: str
) -> Iterable[tuple[Path, int, str]]:
    needle = keyword.casefold()
    for path in Path(base_path).glob("*.jsonl"):
        with path.open(errors="replace") as lines:
            for line_number, line in enumerate(lines, 1):
                if needle not in line.casefold():
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                yield path, line_number, record.get("type", "<missing>")
```

Use `rglob("*.jsonl")` only when the task also needs subagents and workflow journals, and then classify each path before interpreting its records.
