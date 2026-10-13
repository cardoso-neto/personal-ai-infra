---
name: arch-review
description: Review how a PR changes a system's architecture. Use on PRs that add or move boundaries, abstractions, dependencies, data ownership, contracts, or infrastructure.
argument-hint: "[PR | branch] [--comment] [focus]"
---
# Arch Review

> 🤖 Opus 5.5 via Claude Code on behalf of Nei Cardoso

- Judge the design decisions in the change, not its lines.
  - Leave bugs, style, and nits to code review.
- Default to the current branch's PR, or its diff against the base branch.
  - `--comment` posts the result as a PR review; otherwise report it here.
- Understand the system before you judge the change.
  - Read why the PR exists: its description, linked issues, and discussion.
  - Read how the system is built: docs, ADRs, agent instructions, and the code around the change.
  - Summarize the architecture before and after in a few lines.
    - Use `flow-spec` when a flow is hard to follow.
    - If nothing architectural changes, say so and stop.
- Question each significant decision.
  - Does it solve the stated problem at the right layer?
  - Does it fit the existing design, or add a second way to do something already solved?
  - Is there a simpler design that meets the same goal?
    - New layers, abstractions, services, and configuration must earn their keep.
  - Are data ownership, dependency direction, and module boundaries clear?
  - How expensive is it to reverse?
    - Schemas, persisted formats, public APIs, and new dependencies deserve the most scrutiny.
  - What does it make easier or harder next?
  - Where it matters, how does it fail, migrate, and scale?
- Verify each finding against the code before you report it.
  - Drop matters of taste, speculative futures, and scope expansion.
  - Raise a question when intent is unclear instead of guessing.
- Report:
  - The before/after summary and a verdict: land as is, adjust, or rethink.
  - Findings ranked by the cost of being wrong, each with evidence and a concrete alternative.
  - Decisions worth recording, and docs the change makes stale.
