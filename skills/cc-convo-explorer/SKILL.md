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

Session lifecycle events.

```json
{
  "type": "queue-operation",
  "operation": "dequeue",
  "timestamp": "2026-01-28T14:54:06.011Z",
  "sessionId": "uuid"
}
```

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

User messages.

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

Command/session history (not conversation content).

```json
{
  "display": "/command-name",
  "pastedContents": {},
  "timestamp": 1765934747869,
  "project": "/Users/foo/project",
  "sessionId": "uuid"
}
```

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

```python
import json
from collections.abc import Iterator
from pathlib import Path

def extract_user_messages(jsonl_path: str | Path) -> Iterator[str]:
    with open(jsonl_path) as f:
        for line in f:
            record = json.loads(line)
            if record.get('type') != 'user':
                continue
            for block in record.get('message', {}).get('content', []):
                if block.get('type') == 'text' and (text := block.get('text')):
                    yield text

if __name__ == '__main__':
    import sys
    for msg in extract_user_messages(sys.argv[1]):
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
