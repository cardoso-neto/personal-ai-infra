# /// script
# requires-python = "==3.13"
# dependencies = ["marker-pdf"]
# ///
"""Convert a PDF to JSON using marker-pdf with ConfigParser."""

import json
import sys
from pathlib import Path

from marker.config.parser import ConfigParser
from marker.converters.pdf import PdfConverter
from marker.models import create_model_dict
from marker.output import text_from_rendered


def convert_json(pdf_path: str, **config_overrides: object) -> str:
    config_parser = ConfigParser({"output_format": "json", **config_overrides})
    converter = PdfConverter(
        config=config_parser.generate_config_dict(),
        artifact_dict=create_model_dict(),
        processor_list=config_parser.get_processors(),
        renderer=config_parser.get_renderer(),
    )
    rendered = converter(pdf_path)
    text, _, _ = text_from_rendered(rendered)
    return text


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input.pdf> [output.json]")
        sys.exit(1)
    pdf = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else Path(pdf).with_suffix(".json")
    result = convert_json(pdf)
    parsed = json.loads(result)
    Path(out).write_text(json.dumps(parsed, indent=2))
    print(f"Wrote {out}")
