---
name: python
description: Always use this skill when writing or editing python code!
---
# python

- Keep lines short.
- Use ruff for linting and formatting.
  - Install them with `uv tool install ruff` if not already installed.
- Never use "try ... except Exception" that swallows errors.
  - Prefer handling specific exceptions, logging, or re-raising it.
- Always add type hints to code; especially anything non-obvious.
  - Prefer `|` over `Union[]` and `| None` over `Optional`.
  - Run a type checker (pyright or whatever the project specifies) and fix all errors.
  - Prefer strict, tight type hints.
- Never import things from `__future__`, just use the latest Python features and require a modern Python version.
- Whenever possible, extract logic out to staticmethods and classmethods.
- Don't return multiline statements; prefer assigning then returning.
- Don't setup `logging` in libraries; leave that to the application using the library.
- Add doctests to regular expressions.

## pydantic conventions

- Prefer the new [validators](https://docs.pydantic.dev/latest/concepts/validators/#field-validators) over the older `@validator` decorators.
  - e.g.: `number: Annotated[int, AfterValidator(is_even)]`
- Prefer Annotated type aliases for constrained fields at module level for better reusability and readability.
- Prefer constrained types (e.g.: PositiveInt and EmailStr over bare int and str).

## imports

- Imports should always be at the top of the file.
- Always use relative imports within a package (`from ..schemas import ...`).

## dependencies

- Prefer adding dependencies without version constraints unless absolutely necessary.
- Never try except missing imports; assume users of our code will install all needed dependencies.
  - Add them to `pyproject.toml`, `requirements.txt`, or equivalent.
- When installing packages for source code that's local, use `uv pip install -e ./path`.
  - So we don't confuse ourselves editing local code and running things from site-packages.

## naming

- `UPPER_SNAKE_CASE` for constants and regex patterns
- Module-level logger: `log = logging.getLogger(__name__)`

## tests

- Rely on pytest.
  - Use markers effectively.
  - Tests are auto-marked `unit` unless explicitly `@pytest.mark.integration`.

## negative examples

### horizontal alignment is not pythonic

Never do this:

```py
var1         = 1
my_other_var = 2
```

### useless getters and setters

Always prefer accessing attributes directly over something like this:

```py
  def get_my_items(self) -> list[MyItem]:
    return self.my_items
```
