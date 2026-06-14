#!/usr/bin/env python3
"""CI gate: catalog with bad schema / missing version / branch URL → exit 1.

Validation rules live in the published `neoplay` package — install it first:
    pip install --no-deps neo-play
"""
import json
import sys
from pathlib import Path

from neoplay.catalog.parser import CatalogError, parse_catalog


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_catalog.py <catalog.json>", file=sys.stderr)
        return 2
    try:
        catalog = parse_catalog(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")))
    except CatalogError as e:
        print(f"INVALID CATALOG: {e}", file=sys.stderr)
        return 1
    print(f"OK — {len(catalog.apps)} apps, {len(catalog.featured)} featured")
    return 0


if __name__ == "__main__":
    sys.exit(main())
