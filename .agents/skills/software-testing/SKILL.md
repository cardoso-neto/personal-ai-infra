---
name: software-testing
description: Always use this skill when writing or editing software tests!
---
# software-testing

- When writing tests, avoid mocking too much otherwise your tests will be unmaintainable.
  - Always prefer one or two simple integration tests over a bunch of fully mocked unit tests.
  - Use real models and data structures whenever possible.
- Print local variables to stdout on tests.
  - Except when they're going to be tested against a particular expected value.
    - e.g.: don't do `print(f"{header_count=}")\nassert header_count == 1`
  - Focus on inputs and outputs to make it easier to debug it when tests fail.
- Prefer running tests individually rather than the entire suite when facing errors.
- Validate using models (e.g.: pydantic) instead of countless field-by-field assertions.
  - `data = MyDataModel(**obj)` validates structure and types.
  - then assert `data == expected_data`.
- When testing file operations (reading/writing), use `tmp_path` fixture.
  - Files are automatically cleaned up after the test.
- When reading Excel/CSV files for comparison with Pydantic models:
  - Use `pd.read_excel(..., dtype=str, keep_default_na=False)` to avoid type coercion issues.
  - Pandas converts numeric strings to int/float and empty cells to NaN, breaking Pydantic validation.
- Do not bend prod code over backwards to make tests easier to write.
  - Unless that refactoring is beneficial for the prod code itself.

## fixture-driven testing

- Testcases live in fixture files (in domain-native formats), not inlined into test code.
- The test infrastructure discovers, loads, and runs them generically.
- Adding a testcase means adding files.

### structure

- Multi-file testcases should share a stem.
  - `stem.input.yaml`, `stem.action.sh`, `stem.expected.yaml`
  - `stem.pdf`, `stem.md`, `stem.py`; source, intermediate, structured.
- stored in a `fixtures/` directory next to the tests.
- We should aim for a given/when/then cycle.
  - Given: initial state or input data.
  - When: actions, commands, or the pipeline step to invoke.
    - Sometimes implicit (the test function itself is the "when").
  - Then: expected output to compare against.
- A single parametrized test function (or a small family sharing the same fixture) handles all cases.
- Comparison should use structured equality (model-to-model, parsed object to parsed object), not string diffs.

### why this works

- Cases are end-to-end.
  - Fixtures exercise real code, not mocked internals.
  - Failing tests mean the pipeline broke, not that a mock drifted.
- The runner changes only when the pipeline interface changes, not when test data evolves.
