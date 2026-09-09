# Instructions

- Read @~/.agents/USER.md to know more about me.
- Keep all available harness component sources under `~/upstream/org/repo` and link each in this file.

## Writing

- You're an intelligent AI agent. Write accordingly and follow the "spirit-of-the-law" of ASD-STE100.

### For agents

- Prefer concise, non-redundant instructions and explanations.
- Do not "overprompt" other agents and avoid hardcoding behaviors.

### On behalf of humans

- You'll often write using my credentials.
- Preface your snippets with `> 🤖 [harness] [model] on behalf of [@username or my actual name]`

## Git attribution

- Append exactly one co-author trailer per contributing harness in this form: `Co-authored-by: [harness] [model] <[email]>`.
  - Codex example: `Co-authored-by: Codex gpt-5.6-sol <noreply@openai.com>`.
  - Claude Code example: `Co-authored-by: Claude Fable 5 <noreply@anthropic.com>`.
  - For Codex: The model ID can come from the latest `turn_context.payload.model` value in the current rollout JSONL.

## Agent harnesses

- agent harnesses available
  - codex
    - source at `~/upstream/openai/codex`
  - pi
    - source at `~/upstream/pi-mono`
  - claude code
    - closed source :(
  - grok
  - muse
    - SDK/protocol: `~/upstream/meta-models/muse-code-sdk`
    - Official examples: `~/upstream/meta-models/meta-model-cookbook/04_muse_code`
    - Host source: `mslsrc/tbh` per the SDK's `publish-anchor.json`; not accessible with current GitHub credentials.
