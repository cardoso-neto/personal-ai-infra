# /// script
# requires-python = "==3.13"
# dependencies = ["marker-pdf>=1.10.2"]
# ///
"""Convert a PDF to markdown using marker-pdf."""

import sys
from pathlib import Path

from marker.converters.pdf import PdfConverter
from marker.models import create_model_dict
from marker.output import text_from_rendered


def convert(pdf_path: str) -> str:
    converter = PdfConverter(artifact_dict=create_model_dict())
    rendered = converter(pdf_path)
    text, _, _ = text_from_rendered(rendered)
    return text


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input.pdf> [output.md]")
        sys.exit(1)
    pdf = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else Path(pdf).with_suffix(".md")
    Path(out).write_text(convert(pdf))
    print(f"Wrote {out}")
