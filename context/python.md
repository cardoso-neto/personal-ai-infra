# Python

- Keep lines short and avoid horizontal alignment.
- isort and black (unless the project specifies otherwise).
  - Install them with pip if not already installed.
- Avoid try except Exception that swallows errors.
  - Prefer logging, re-raising it, or handling specific exceptions.
- Never try except missing imports; assume users of our code will install all needed dependencies.
  - Add them to requirements.txt or equivalent.
- Prefer adding dependencies without version constraints unless absolutely necessary.
- Always add type hints to code; especially anything non-obvious.
  - Prefer `|` over `Union[]` and `| None` over `Optional`.
  - Run a type checker (e.g.: `mypy`) and fix all errors after writing the code.
- Whenever possible, extract logic out to staticmethods and classmethods.
- When installing packages for source code that's local, use `pip install -e ./path`.
  - So we don't confuse ourselves editing local code and running things from site-packages.
