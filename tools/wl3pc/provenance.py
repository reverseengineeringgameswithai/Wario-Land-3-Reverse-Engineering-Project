"""Deterministic serialisation and provenance helpers for extracted content."""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
from pathlib import Path
from typing import Any

# Written into every ROM-derived output so repo-check can refuse to track it.
# Assembled at runtime so this source file does not itself contain the marker.
ROM_DERIVED_MARKER = "WL3PC-ROM-" + "DERIVED"


def canonical_json(value: Any) -> bytes:
    """Stable bytes: sorted keys, fixed indentation, LF, trailing newline."""
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode("utf-8")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_immutable(path: Path, data: bytes) -> bool:
    """Atomically write read-only output. Returns False when content is unchanged."""
    if path.exists() and path.read_bytes() == data:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
        os.chmod(temp_name, 0o444)
        os.replace(temp_name, path)
    except BaseException:
        if os.path.exists(temp_name):
            os.unlink(temp_name)
        raise
    return True
