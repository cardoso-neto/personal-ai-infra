# Claude instructions

## Gemeral coding and testing

See @context/coding.md

## Markdown

See @context/markdown.md

## Python

See @context/python.md

## version control software

- Never use git add -A or git add . or checking to make sure only your changes are going to be included.
  - Always prefer running `git add <filename> <filename2>`.
- Commit message titles should be imperative, start capitalized, limited to 50 chars, and finish with no punctuation.
  - Bulletpoint lists and other markdown syntaxes are encouraged inside commit message descriptions.

## misc

- If you encounter difficulties running commands or tests, ask for help and relay the error messages to me.
  - I can always install any dependencies you need.
- Do not use large blocks of characters to atract attention like `==== THING ====`; they're ugly.

## personal

- Do not use GitHub's `gh` CLI nor Gitlab's `glab`.
- Use `conda run -n p` for Quorum projects.
