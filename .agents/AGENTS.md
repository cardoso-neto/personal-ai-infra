# Instructions

- Read @~/.agents/USER.md to know more about me.
- Most tasks are better tackled by breaking them down and handing them off to focused subagents.

## Writing

- You're an intelligent AI agent. Write accordingly and follow the "spirit-of-the-law" of ASD-STE100.

### For agents

- Prefer concise, non-redundant instructions and explanations.
- Do not "overprompt" other agents and avoid hardcoding behaviors.

### On behalf of humans

- You'll often write using my credentials.
- Preface your snippets with `> 🤖 [model] via [harness] on behalf of [@username or my first-name second-name]`
  - `> 🤖 gpt-6-astra via Pi on behalf of John Doe`
  - `> 🤖 Fable 5.1 via Claude Code on behalf of @github-user`
  - `> 🤖 grok-4.6 via Grok Build on behalf of @twitter-handle`

## Git attribution

- Append exactly one co-author trailer per contributing harness in this form: `Co-authored-by: [harness] [model] <[email]>`.
  - Codex example: `Co-authored-by: Codex gpt-5.6-sol <noreply@openai.com>`.
  - Claude Code example: `Co-authored-by: Claude Fable 5.1 <noreply@anthropic.com>`.
  - For Codex: The model ID can come from the latest `turn_context.payload.model` value in the current rollout JSONL.

## sourcecode

- If you'd benefit from inspecting source code locally, clone it to `~/upstream/org/repo`.

## Agent tooling

- For Neurohive Workspace access, read @~/neurohive/docs/gsuite/workspace-admin.md.

- agent harnesses already available
  - codex (`~/upstream/openai/codex`)
  - pi (`~/upstream/badlogic/pi-mono`)
  - claude code (closed source) :cry:
  - grok (`~/upstream/xai-org/grok-build`)
  - muse (SDK/protocol: `~/upstream/meta-models/muse-code-sdk`; CLI implementation not included)
- metaharness
  - t3code (`~/upstream/pingdotgg/t3code`)

- I have a fleet of machines connected via t3 connect and ssh which I use through t3code.
  - ~/.agents/fleet/t3code/ has .md files explaining how each of them was setup.

## Misc

- If you encounter difficulties, ask for help and relay the error messages to me.
  - You can install any dependencies you need.
  - And I can install them for you if sudo is needed.
