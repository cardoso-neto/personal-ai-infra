---
name: cc-convo-explorer
description: Explore and search previous Claude Code conversations stored in ~/.claude/projects/
---

# cc-convo-explorer

Claude Code stores conversation history as JSONL files in `~/.claude/projects/`, one JSON object per line.

## File locations

- `~/.claude/projects/{encoded-project-path}/`
  - `{session-id}.jsonl` - main conversation files (session id is a UUID)
  - `{session-id}/` - per-session subdirectory holding ancillary data
    - `subagents/agent-{hash}.jsonl` - subagent transcripts (records have `isSidechain: true`)
    - `subagents/agent-{hash}.meta.json` - sidecar (`agentType`, `description`, `name`, `toolUseId`)
    - `subagents/journal.jsonl`, `subagents/agent-compact-{hash}.jsonl` - workflow/compaction state
    - `tool-results/*.txt` - raw tool-result payloads (not JSONL)
    - `workflows/` - workflow run state
  - `sessions-index.json`, `memory`, `debug-{digits}.jsonl` - other per-project entries
- `~/.claude/history.jsonl` - every user-typed message across all projects (see below)

### Path encoding

The project dir name is the absolute project path with each of `/`, `.`, and `_` collapsed to a single `-`.

- `/home/user/company/proj` -> `-home-user-company-proj`
- `/home/user/.claude` -> `-home-user--claude`
- `/home/user/svc_410439` -> `-home-user-svc-410439`

## Size warnings

- Don't read conversation files or lines naively.
  - Files run up to ~18 MB (avg ~350 KB); single lines can exceed 1.5 MB (large tool results, thinking blocks).
  - Check file size first (`ls -lah`); process line-by-line above ~60 KB.
  - `awk 'NR==5 { print length; exit }' file.jsonl` checks the length of line 5 before reading it.
  - When lines are huge, project to the fields you need with `jq` instead of reading whole lines.
- Exclude `history*.jsonl` and `*/tool-results/*.txt` when scanning a tree for JSONL records - they are not conversation lines and pollute a naive census.

## Record envelope

Heavyweight records (`user`, `assistant`, `attachment`, `system`, `progress`) share a common envelope; the rest carry only `type`, `sessionId`, and their own payload.

- `type` - record type
- `uuid` / `parentUuid` - record id and its parent (`parentUuid: null` marks a session's initial message)
- `timestamp` - ISO-8601 string
- `sessionId`, `cwd`, `gitBranch`, `version`, `entrypoint` - session context (`entrypoint`: `cli` / `sdk-cli` / `sdk-ts`)
- `isSidechain` - `true` only in subagent files
- `userType` - `external`

`version` is `2.1.x`. Model ids (`message.model`) are `claude-opus-4-x` / `claude-sonnet-4-x` / `claude-fable-x` / `claude-haiku-4-x`, plus `<synthetic>` for injected or error turns.
Don't hardcode either - they move constantly.

## Conversation record types

### user

User-side turns: initial prompts, follow-ups, and tool-result carriers.

- Initial message (`parentUuid: null`): `message.content` is a plain string (or a short list of `{type: "text", text}` blocks) holding the clean user prompt.
  - It no longer embeds CLAUDE.md or system-reminders, so no stripping is needed.
- Tool results (`parentUuid` set): `message.content` is a list of `tool_result` blocks (`tool_use_id`, `content`); structured tool metadata is mirrored in a top-level `toolUseResult`.
  - `text` blocks here are mostly skill expansions or `[Request interrupted by user]`, not user-typed text.
- Useful extra fields: `promptId`, `permissionMode`, `promptSource`, `origin`.

```json
{"type": "user", "parentUuid": null, "message": {"role": "user", "content": "the prompt"}}
```

### assistant

Model turns. `message.content` is a list of blocks:

- `thinking` - reasoning (`thinking`, `signature`)
- `text` - response text
- `tool_use` - tool call (`id`, `name`, `input`)

`message` also has `model`, `id`, `stop_reason`, and `usage` (with `input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`).
A turn may be attributed to a skill or MCP tool via top-level `attributionSkill` / `attributionMcpServer` / `attributionMcpTool`.

### queue-operation

Message-queue lifecycle. The best source for the full text of follow-up messages, including pasted content.

```json
{"type": "queue-operation", "operation": "enqueue", "sessionId": "...", "timestamp": "...", "content": "full follow-up text"}
```

- `operation` - `enqueue`, `dequeue`, `remove`, `popAll`
- `content` - present on `enqueue` and `popAll`; absent on `dequeue` / `remove`
  - Also carries `<task-notification>` XML for agent notifications - filter those out.
- No envelope beyond `type`, `operation`, `sessionId`, `timestamp`.

### system

System/meta events keyed by `subtype`. Field set varies per subtype.

- `away_summary` - prose recap of what the agent did while you were away
- `local_command` - `.content` holds the `<command-name>` of a slash-command invocation
- `turn_duration`, `stop_hook_summary`, `compact_boundary`, `api_error` (carries `error`), `bridge_status`, `scheduled_task_fire`

### attachment

Context injected into a turn, keyed by `attachment.type`. Mostly bookkeeping (`task_reminder`, `deferred_tools_delta`, `skill_listing`, `edited_text_file`, `nested_memory`, `command_permissions`, ...).

- `queued_command` is search-relevant: `attachment.prompt` holds real user follow-up text - a source beyond `queue-operation`.

### progress

Streaming status during long tool/subagent operations (`data.type`: `hook_progress`, `agent_progress`, ...).
High volume, low value for search; the underlying subagent output is already in the `agent-*.jsonl` files.

## Session-metadata records

Tiny records, useful as a cheap per-session index without parsing message bodies:

- `last-prompt` - `lastPrompt`: full text of the session's most recent user prompt
- `ai-title` - `aiTitle`: auto-generated topic label for the session
- `custom-title` - `customTitle`: user-set label (overrides `ai-title`)
- `agent-name` - `agentName`: readable label for a (sub)agent session
- `pr-link` - `prNumber` / `prUrl` / `prRepository`: the PR a session opened
- `fork-context-ref` - `parentSessionId` / `parentLastUuid` (in subagent files): links a fork back to its origin

Pure bookkeeping (skip for search): `permission-mode`, `mode`, `bridge-session`, `agent-setting`, `file-history-snapshot`, `debug_claude`.

## history.jsonl schema

One record per user-typed message, across all projects.
The simplest source for "what did the user type", though pasted content is abbreviated.

```json
{"display": "the typed text", "pastedContents": {}, "project": "/abs/path", "sessionId": "uuid", "timestamp": 1765934747869}
```

- `display` - the message as typed; pasted blocks show as `[Pasted text #1 +N lines]`
- `project` - absolute project path (matches the conversation file's `cwd`, not the encoded dir name)
- `sessionId` - present on recent records; older records and bare slash-commands (e.g. `/mcp status`) may omit it
- `timestamp` - epoch milliseconds
- `pastedContents` - map keyed `"1"`, `"2"`, ... per pasted block; `{}` when none. Two variants:
  - by reference: `{"id": 1, "type": "text", "contentHash": "hex"}` (text stored elsewhere by hash)
  - inline: `{"id": 1, "type": "text", "content": "full pasted text"}`
  - `id` is an integer and may be `null`.
- Slash commands also appear here.

## Extracting user-typed messages

Three sources, by completeness:

1. `history.jsonl` - every message with timestamps; pasted content abbreviated.
2. `queue-operation` `content` and `queued_command` `attachment.prompt` - full follow-up text including pasted content.
3. `parentUuid: null` `user` records - the full initial prompt of each session.

```python
import json
from pathlib import Path

HISTORY = Path("~/.claude/history.jsonl").expanduser()


def typed_messages(project_path: str) -> list[str]:
    """Every user-typed message for a project, oldest first."""
    out: list[tuple[int, str]] = []
    for line in HISTORY.read_text().splitlines():
        record = json.loads(line)
        if record.get("project") != project_path:
            continue
        display = (record.get("display") or "").strip()
        if display and not (display.startswith("/") and " " not in display):
            out.append((record.get("timestamp", 0), display))
    out.sort()
    return [text for _, text in out]
```

```python
import json
from pathlib import Path


def session_user_messages(jsonl_path: str | Path) -> list[str]:
    """Full user-typed text (initial prompt + follow-ups) for one session, in order."""
    out: list[tuple[str, str]] = []
    for line in Path(jsonl_path).read_text().splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        rtype = record.get("type")
        if rtype == "queue-operation" and record.get("operation") in ("enqueue", "popAll"):
            content = (record.get("content") or "").strip()
            if content and not content.startswith("<task-notification>"):
                out.append((record.get("timestamp", ""), content))
        elif rtype == "user" and record.get("parentUuid") is None:
            content = record.get("message", {}).get("content")
            if isinstance(content, str):
                text = content
            elif isinstance(content, list):
                text = "".join(
                    b.get("text", "")
                    for b in content
                    if isinstance(b, dict) and b.get("type") == "text"
                )
            else:
                text = ""
            if text.strip():
                out.append((record.get("timestamp", ""), text.strip()))
    out.sort()
    return [text for _, text in out]
```

## Searching

Useful shell one-liners (records have no spaces after colons, so the compact patterns match):

```bash
head -1 file.jsonl | jq -c keys                                  # keys of the first record
grep '"type":"user"' file.jsonl | head -1 | jq                   # first record of a type
grep '"type":"assistant"' file.jsonl | head -1 | jq 'del(.message.content)'  # structure, minus bulk
jq -r .type file.jsonl | sort | uniq -c | sort -rn               # count records by type
cat *.jsonl | jq -rR 'fromjson? | .type' | sort -u               # all types in a dir (tolerates non-JSON)
grep -h '"type":"queue-operation"' *.jsonl | head -1 | jq        # first match across files (-h drops filename)
```

Keyword search across a project's files:

```python
import json
import sys
from pathlib import Path


def search(base_path: str | Path, keyword: str):
    """Yield (filename, line_no, record_type) for lines containing keyword."""
    needle = keyword.lower()
    for fpath in Path(base_path).glob("*.jsonl"):
        with fpath.open() as f:
            for line_no, line in enumerate(f, 1):
                if needle not in line.lower():
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                yield fpath.name, line_no, record.get("type")


if __name__ == "__main__":
    for name, line_no, rtype in search(sys.argv[1], sys.argv[2]):
        print(f"{name}:{line_no} ({rtype})")
```
