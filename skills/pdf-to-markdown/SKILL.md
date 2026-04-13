---
name: pdf-to-markdown
description: Extracting text and tables, merging/splitting documents. Use when needing to convert PDFs while preserving structure.
---

# PDF to Markdown

## marker-pdf

- Preserves structure, math, tables, figures.
- This should be your go-to tool for converting PDFs to Markdown with good fidelity.
- Repo: <https://github.com/datalab-to/marker>

### CLI

```bash
# pip install marker-pdf  # python==3.12
marker_single input.pdf --output_dir ./marker-output

marker_single input.pdf --output_dir ./out --page_range "0,5-10"  # specific pages
marker_single input.pdf --output_dir ./out --force_ocr  # for scanned PDFs
OUTPUT_IMAGE_FORMAT=PNG marker_single input.pdf --output_dir ./out  # change image format to PNG
marker_single input.pdf --output_dir ./out --use_llm \
  --llm_service marker.services.openai.OpenAIService \
  --openai_api_key "$OPENAI_API_KEY" \
  --openai_model gpt-5.2
```

Output:

- `marker_output/<filename>/<filename>.md`
- extracted images as JPEGs by default.
  - `marker_output/<filename>/_page_<N>_Figure_<M>.jpeg`
- Run `marker_single --help` for all available options.

### python API

- [convert.py](scripts/convert.py) - simple PDF -> markdown conversion.
  - `python convert.py input.pdf [output.md]`
- [convert_json.py](scripts/convert_json.py)
  - PDF -> JSON via [`ConfigParser`](https://github.com/datalab-to/marker/blob/master/marker/config/parser.py).

### downsides

- Discards most styling (colors, fonts, anything that would need HTML).
