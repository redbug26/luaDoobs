#!/usr/bin/env python3
"""Combine per-script metadata into a deterministic databases/all.json catalog."""

import json
from pathlib import Path


def build_catalog(root: Path) -> list[dict]:
    """Validate script/metadata pairs and add each script's directory relative to root."""
    if not root.is_dir():
        raise ValueError(f"Database directory does not exist: {root}")
    catalog = []
    seen = set()
    for metadata in sorted(root.rglob("*.json")):
        if metadata == root / "all.json":
            continue  # Never consume the generated catalog as a metadata source.
        entry = json.loads(metadata.read_text(encoding="utf-8"))
        if not isinstance(entry, dict):
            raise ValueError(f"{metadata}: expected one metadata object")
        filename = entry.get("file")
        if (not isinstance(filename, str) or "/" in filename or "\\" in filename
                or Path(filename).suffix.lower() != ".luadoobs"):
            raise ValueError(f"{metadata}: invalid script file name: {filename!r}")
        script = metadata.parent / filename
        if script.with_suffix(".json") != metadata:
            raise ValueError(f"{metadata}: metadata and script must have the same base name")
        if not script.is_file():
            raise ValueError(f"{metadata}: script not found: {filename}")
        for key in ("title", "description"):
            translations = entry.get(key)
            if not isinstance(translations, dict) or any(
                not isinstance(translations.get(lang), str)
                or not translations[lang].strip() for lang in ("en", "fr")
            ):
                raise ValueError(f"{metadata}: {filename}: {key} needs en/fr text")
        seen.add(script)
        directory = metadata.parent.relative_to(root).as_posix()
        catalog.append({**entry, "directory": directory})
    for script in sorted(root.rglob("*")):
        if script.is_file() and script.suffix.lower() == ".luadoobs" and script not in seen:
            raise ValueError(f"{script}: missing metadata: {script.with_suffix('.json').name}")
    return sorted(catalog, key=lambda entry: (entry["directory"], entry["file"]))


def main() -> None:
    root = Path(__file__).resolve().parents[1] / "databases"
    catalog = build_catalog(root)
    target = root / "all.json"
    content = json.dumps(catalog, ensure_ascii=False, indent=2) + "\n"
    if target.exists() and target.read_text(encoding="utf-8") == content:
        print(f"{target}: already up to date ({len(catalog)} scripts)")
        return
    # Validate every script/metadata pair before replacing the last valid catalog.
    temporary = target.with_suffix(".json.tmp")
    temporary.write_text(content, encoding="utf-8")
    temporary.replace(target)
    print(f"{target}: generated {len(catalog)} scripts")


if __name__ == "__main__":
    main()
