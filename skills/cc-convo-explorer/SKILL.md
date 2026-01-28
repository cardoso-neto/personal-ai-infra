---
name: cc-convo-explorer
description: Explore and search previous Claude Code conversations stored in ~/.claude/projects/
---

# cc-convo-explorer

Claude Code stores conversation history as JSONL files in `~/.claude/projects/`.

## File locations

- `~/.claude/projects/{encoded-project-path}/`
  - `{session-id}.jsonl` - main conversation files (UUID format)
  - `agent-{hash}.jsonl` - subagent conversation files
  - `{session-id}/` - directories may exist alongside some conversations
- `~/.claude/history.jsonl` - command history (not conversation content)

Project paths are encoded by replacing `/` with `-` (e.g.: `/Users/foo/my-project` -> `-Users-foo-my-project`).

## Size warnings

Before reading conversation files:

1. Check file size first (`ls -lah` or `wc -l`).
2. Check max line length - single lines can exceed 500KB.
3. Never read entire files blindly - use line-by-line processing.

Typical sizes observed:

- Files range from empty to 12+ MB
- Lines can be 100KB-500KB+ (tool results, assistant responses)
- A single project folder can contain 50+ MB across all conversations

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
  "cwd": "/path/to/project",
  "gitBranch": "branch-name",
  "version": "2.1.11",
  "message": {
    "model": "claude-opus-4-5-20251101",
    "id": "msg_...",
    "role": "assistant",
    "content": [
      {"type": "thinking", "thinking": "...", "signature": "..."},
      {"type": "text", "text": "response text"},
      {"type": "tool_use", "id": "toolu_...", "name": "ToolName", "input": {...}}
    ],
    "usage": {
      "input_tokens": 10,
      "output_tokens": 100,
      "cache_read_input_tokens": 0
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
  "timestamp": "..."
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
  "isMeta": true,
  "level": "info",
  "parentUuid": "uuid",
  "uuid": "uuid",
  "timestamp": "..."
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

## Example: extracting user messages

```python
import json

def extract_user_messages(jsonl_path):
    messages = []
    with open(jsonl_path) as f:
        for line in f:
            record = json.loads(line)
            if record.get('type') != 'user':
                continue
            content = record.get('message', {}).get('content', [])
            for block in content:
                if block.get('type') == 'text':
                    messages.append(block.get('text', ''))
    return messages
```

## Example: finding conversations by keyword

```python
import json
import os

def search_conversations(base_path, keyword):
    results = []
    for fname in os.listdir(base_path):
        if not fname.endswith('.jsonl'):
            continue
        fpath = os.path.join(base_path, fname)
        with open(fpath) as f:
            for line_num, line in enumerate(f, 1):
                if keyword.lower() in line.lower():
                    record = json.loads(line)
                    results.append({
                        'file': fname,
                        'line': line_num,
                        'type': record.get('type')
                    })
    return results
```
