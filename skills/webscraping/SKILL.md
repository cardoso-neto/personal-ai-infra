---
name: webscraping
description: Always use this skill when writing or editing webscrapers!
---
# webscraping

Knowledge about writing good webscrapers.

## flows

1. Invoke the skill related to the dataset you're working on.

### new spider

1. Explore the target website using browser tools.
2. Help the user design a schema for the source if one wasn't already provided.
3. Write the code, run it, and fix any errors you find.
4. Document the command to test the spider as well as the one to scrape the entire website in the root README.md.
5. If an integration test doesn't exist yet, write one that scrapes a single record and checks the output against the schema.
  1. Keep iterating until all required fields are extracted correctly.

## tech stack

- Spiders should be named `<source-name>_<dataset-name>.py`, e.g.: `instagram_short-videos.py`.
- All URLs should be absolute (not relative).

## code smells

### Hallucinating default values when scraping

Do not make up IDs when scraping.

```python
try:
    rule_id = int(rule_id_str)
except ValueError:
    logger.warning(f"Could not parse rule_id from {rule_number!r}.")
    rule_id = hash(rule_number)
```

If one can't be scraped and the field is required, raise an error.

```python
except ValueError as e:
    logger.error(f"Could not parse rule_id from {rule_number!r}.")
    raise MissingRequiredFieldError("rule_id") from e
```
