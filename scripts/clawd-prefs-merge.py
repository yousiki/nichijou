#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///

import json
import os
import sys
import tempfile
from typing import Optional, cast

JsonObject = dict[str, object]


def load_json_object(path: str, default: Optional[JsonObject] = None) -> JsonObject:
    try:
        with open(path, encoding="utf-8") as f:
            loaded = cast(object, json.load(f))
    except FileNotFoundError:
        loaded = {} if default is None else default

    if not isinstance(loaded, dict):
        raise TypeError(f"{path} must contain a JSON object")
    return cast(JsonObject, loaded)


def merge(base: JsonObject, override: JsonObject) -> None:
    for key, value in override.items():
        current = base.get(key)
        if isinstance(value, dict) and isinstance(current, dict):
            merge(cast(JsonObject, current), cast(JsonObject, value))
        else:
            base[key] = value


def main():
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} <prefs-path> <patch-json>")

    prefs_path, patch_path = sys.argv[1:3]

    prefs = load_json_object(prefs_path)
    patch = load_json_object(patch_path)

    merge(prefs, patch)

    prefs_dir = os.path.dirname(prefs_path)
    os.makedirs(prefs_dir, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(
        prefix=".clawd-prefs.", suffix=".json", dir=prefs_dir
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(prefs, f, indent=2, ensure_ascii=False)
            _ = f.write("\n")
        os.replace(tmp_path, prefs_path)
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


if __name__ == "__main__":
    main()
