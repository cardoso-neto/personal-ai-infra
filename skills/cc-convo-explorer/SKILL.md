---
name: cc-convo-explorer
description: Explore and search previous Claude Code conversations stored in ~/.claude/projects/
---

# cc-convo-explorer

Claude Code stores conversation history as JSONL files in `~/.claude/projects/`.

## File locations

- `~/.claude/projects/{encoded-project-path}/`
  - `{session-id}.jsonl`
    - main conversation files (UUID format)
  - `agent-{hash}.jsonl`
    - subagent conversation files
  - `{session-id}/`
    - directories may exist alongside some conversations
- `~/.claude/history.jsonl`
  - command history (not conversation content)

Project paths are encoded by replacing `/` with `-` (e.g.: `/Users/foo/my-project` -> `-Users-foo-my-project`).

## Size warnings

- Don't read conversation files naively.
  - Files can range from empty to 12+ MB
  - Check file size first (`ls -lah`).
  - Use line-by-line processing if it's bigger than 60KB.
- Also don't read lines blindly.
  - Single lines can be 100KB-500KB+ (tool results, assistant responses).
  - Check line length before reading.
  - `awk 'NR==5 { print length; exit }' file.jsonl` to check line number 5.
  - if lines are too long, filter for the fields you need using `jq` or code.

## JSONL record types

Each line is a JSON object. The `type` field determines the record structure.

### queue-operation

Session lifecycle events. Follow-up user messages appear as `enqueue` operations with a `content` field containing the full message text (including pasted content). This is the best source for follow-up message full text.

```json
{
  "type": "queue-operation",
  "operation": "enqueue",
  "timestamp": "2026-01-28T14:54:06.011Z",
  "sessionId": "uuid",
  "content": "the full user-typed message including pasted text"
}
```

- `operation` - `enqueue` (new message queued), `dequeue` (processing started), `remove` (done)
- `content` - only present on `enqueue` records for user follow-up messages
  - Also contains `<task-notification>` XML for agent notifications (filter these out)
  - NOT present for the initial message of a session (that's in the `parentUuid=null` user record)

### file-history-snapshot

File state tracking for undo/restore.

```json
{
  "type": "file-history-snapshot",
  "messageId": "uuid",
  "snapshot": {
    "messageId": "uuid",
    "trackedFileBackups": {},
    "timestamp": "..."
  },
  "isSnapshotUpdate": false
}
```

### user

User messages. Two distinct formats:

1. **Initial message** (`parentUuid: null`): content is a flat list of single-character strings.
   - Concatenate all strings to reconstruct the full text.
   - Contains system context (CLAUDE.md, system-reminders) followed by the user's actual message.
   - User message starts after the last `</system-reminder>` tag.
2. **Tool results** (`parentUuid: "uuid"`): content is a list of `tool_result` or `text` dicts.
   - `text` blocks here are mostly skill expansions (`Base directory for this skill:...`) or interrupts (`[Request interrupted by user]`), not user-typed messages.
   - Real follow-up user messages are in `queue-operation` records, not here.

```json
{
  "type": "user",
  "parentUuid": "uuid|null",
  "uuid": "uuid",
  "timestamp": "...",
  "sessionId": "uuid",
  "cwd": "/path/to/project",
  "gitBranch": "branch-name",
  "version": "2.1.11",
  "isSidechain": false,
  "userType": "external",
  "message": {
    "role": "user",
    "content": [
      {"type": "text", "text": "user message here"}
    ]
  }
}
```

### assistant

Assistant responses, may contain multiple content types.

```json
{
  "type": "assistant",
  "parentUuid": "uuid",
  "uuid": "uuid",
  "timestamp": "...",
  "sessionId": "uuid",
  "requestId": "req_...",
  "cwd": "/path/to/project",
  "gitBranch": "branch-name",
  "version": "2.1.11",
  "isSidechain": false,
  "userType": "external",
  "message": {
    "model": "claude-opus-4-5-20251101",
    "id": "msg_...",
    "type": "message",
    "role": "assistant",
    "stop_reason": "end_turn|tool_use|null",
    "stop_sequence": "...|null",
    "content": [
      {"type": "thinking", "thinking": "...", "signature": "..."},
      {"type": "text", "text": "response text"},
      {"type": "tool_use", "id": "toolu_...", "name": "ToolName", "input": {...}}
    ],
    "usage": {
      "input_tokens": 10,
      "output_tokens": 100,
      "cache_read_input_tokens": 0,
      "cache_creation_input_tokens": 0,
      "cache_creation": {
        "ephemeral_5m_input_tokens": 0,
        "ephemeral_1h_input_tokens": 0
      },
      "service_tier": "standard"
    }
  }
}
```

Content block types in assistant messages:

- `thinking` - Claude's reasoning (has `thinking` and `signature` fields)
- `text` - Response text
- `tool_use` - Tool invocation (has `id`, `name`, `input` fields)

### tool_result (inside user message)

Tool results appear as content blocks in user-type records.

```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": [
      {
        "type": "tool_result",
        "tool_use_id": "toolu_...",
        "content": [{"type": "text", "text": "result here"}]
      }
    ]
  }
}
```

### progress

Status updates during long operations.

```json
{
  "type": "progress",
  "slug": "progress-indicator-name",
  "data": {...},
  "toolUseID": "toolu_...",
  "parentToolUseID": "toolu_...|null",
  "parentUuid": "uuid",
  "uuid": "uuid",
  "timestamp": "...",
  "sessionId": "uuid",
  "cwd": "/path/to/project",
  "gitBranch": "branch-name",
  "version": "2.1.11",
  "isSidechain": false,
  "userType": "external"
}
```

### summary

Conversation summaries (used for context management).

```json
{
  "type": "summary",
  "summary": "text summary of conversation",
  "leafUuid": "uuid"
}
```

### system

System-level events and metadata.

```json
{
  "type": "system",
  "subtype": "event-type",
  "content": "...",
  "isMeta": true|false,
  "level": "info",
  "parentUuid": "uuid|null",
  "uuid": "uuid",
  "timestamp": "...",
  "sessionId": "uuid",
  "cwd": "/path/to/project",
  "gitBranch": "branch-name",
  "version": "2.1.11",
  "isSidechain": false,
  "userType": "external"
}
```

## history.jsonl schema

Every user-typed message across all projects, one record per message.
Best source for extracting what the user actually typed (conversation JSONL files mix user messages with system context, skill expansions, and tool results).

```json
{
  "display": "the full user-typed message text",
  "pastedContents": {"1": {"id": "int", "type": "text", "contentHash": "hex"}},
  "timestamp": 1765934747869,
  "project": "/Users/foo/project",
  "sessionId": "uuid"
}
```

- `display` - the complete message text as typed by the user
- `pastedContents` - references to pasted text blocks (content stored by hash, not inline)
  - Messages referencing pasted content show `[Pasted text #1 +N lines]` in `display`
- `timestamp` - epoch milliseconds
- `project` - absolute path to the project directory
- `sessionId` - maps to `{sessionId}.jsonl` in the project's conversation directory
- Slash commands (e.g. `/model`) also appear here

## Code references

### Useful shell one-liners

```bash
# List keys from first record
head -1 file.jsonl | jq -c 'keys'

# Find and pretty-print a specific record type
grep '"type":"user"' file.jsonl | head -1 | jq '.'

# Show record structure without large content fields
grep '"type":"assistant"' file.jsonl | head -1 | jq 'del(.message.content)'

# Search across all files in a project folder, extract the JSON part
grep '"type":"summary"' *.jsonl | head -1 | cut -d: -f2- | jq '.'

# Count records by type
jq -r '.type' file.jsonl | sort | uniq -c | sort -rn

# List all unique record types across all files
cat *.jsonl | jq -r '.type' | sort -u
```

### Extracting user messages

Three data sources, combined for completeness:

1. `history.jsonl` - has every message with timestamps, but pasted content shows as `[Pasted text #1 +N lines]`
2. `queue-operation` records (in conversation JSONL) - full text of follow-up messages including pasted content
3. `parentUuid=null` user records (in conversation JSONL) - full text of initial session messages (reconstruct from single-char string blocks)

Quick approach (history.jsonl only, loses pasted content):

```bash
python3 -c "
import json, sys
with open('$HOME/.claude/history.jsonl') as f:
    for line in f:
        r = json.loads(line)
        if r.get('project') == sys.argv[1]:
            d = r.get('display', '')
            if d and not (d.startswith('/') and ' ' not in d):
                print(d)
" /path/to/project
```

Full approach (resolves pasted content):

```python
import json
from pathlib import Path

def extract_user_messages(
    project_path: str,
    *,
    exclude_sessions: set[str] | None = None,
) -> list[tuple[int, str]]:
    """Return [(timestamp, message)] for all user-typed messages in a project."""
    history = Path("~/.claude/history.jsonl").expanduser()
    exclude = exclude_sessions or set()
    encoded = project_path.replace("/", "-")
    convo_dir = Path("~/.claude/projects").expanduser() / encoded

    # Collect full-text follow-ups from queue-operation records
    queue_msgs: dict[tuple[str, str], str] = {}  # (session_id, timestamp) -> content
    initial_msgs: dict[str, str] = {}  # session_id -> initial message text
    for jsonl_file in convo_dir.glob("*.jsonl"):
        sid = jsonl_file.stem
        if sid in exclude or sid.startswith("agent-"):
            continue
        with open(jsonl_file) as f:
            for line in f:
                record = json.loads(line.strip() or "{}")
                rtype = record.get("type")
                if rtype == "queue-operation" and "content" in record:
                    content = record["content"].strip()
                    if content and not content.startswith("<task-notification>"):
                        queue_msgs[(sid, record.get("timestamp", ""))] = content
                elif rtype == "user" and not record.get("parentUuid"):
                    blocks = record.get("message", {}).get("content", [])
                    if blocks and isinstance(blocks[0], str):
                        full = "".join(b for b in blocks if isinstance(b, str))
                        pos = full.rfind("</system-reminder>")
                        msg = full[pos + 18:].strip() if pos >= 0 else full.strip()
                        if msg and sid not in initial_msgs:
                            initial_msgs[sid] = msg

    # Build list from history, replacing with full text where available
    messages: list[tuple[int, str]] = []
    seen_initial: set[str] = set()
    with open(history) as f:
        for line in f:
            record = json.loads(line.strip() or "{}")
            if record.get("project") != project_path:
                continue
            sid = record.get("sessionId", "")
            if sid in exclude:
                continue
            display = record.get("display", "").strip()
            ts = record.get("timestamp", 0)
            if not display or (display.startswith("/") and " " not in display):
                continue
            text = display
            if sid not in seen_initial:
                seen_initial.add(sid)
                if sid in initial_msgs:
                    text = initial_msgs[sid]
            else:
                for (qsid, _qts), qcontent in queue_msgs.items():
                    if qsid == sid and display[:30].lower().replace(" ", "") == qcontent[:30].lower().replace(" ", ""):
                        text = qcontent
                        break
            messages.append((ts, text))
    messages.sort(key=lambda x: x[0])
    return messages

if __name__ == "__main__":
    import sys
    for _ts, msg in extract_user_messages(sys.argv[1]):
        print(msg)
```

### Finding conversations by keyword

```python
import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import TypedDict

class SearchResult(TypedDict):
    file: str
    line: int
    type: str | None

def search_conversations(
    base_path: str | Path,
    keyword: str,
    *,
    parallel: bool = False,
) -> list[SearchResult]:
    keyword_lower = keyword.lower()
    files = list(Path(base_path).glob('*.jsonl'))

    def search_file(fpath: Path) -> list[SearchResult]:
        results: list[SearchResult] = []
        with open(fpath) as f:
            for line_num, line in enumerate(f, 1):
                if keyword_lower in line.lower():
                    record = json.loads(line)
                    results.append({
                        'file': fpath.name,
                        'line': line_num,
                        'type': record.get('type'),
                    })
        return results

    if parallel and len(files) > 1:
        with ThreadPoolExecutor() as executor:
            all_results = executor.map(search_file, files)
        return [r for batch in all_results for r in batch]
    return [r for fpath in files for r in search_file(fpath)]

if __name__ == '__main__':
    import sys
    for result in search_conversations(sys.argv[1], sys.argv[2]):
        print(f"{result['file']}:{result['line']} ({result['type']})")
```
