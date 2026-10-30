"""Parsers for local reference material: RGBDS .sym files and WL3 Editor ref tables.

Neither source is redistributed; both are read at extraction time from ignored
locations and only used to label decoded values.
"""

from __future__ import annotations

import re
from pathlib import Path

from .address import BankedAddress

_SYM_RE = re.compile(r"^([0-9A-Fa-f]{2,3}):([0-9A-Fa-f]{4})\s+(\S+)")
_REF_RE = re.compile(r"^(.*?)=\s*([0-9A-Fa-f]+)\s*$")


def parse_sym(text: str, include_local: bool = False) -> dict[BankedAddress, str]:
    """Map ROM addresses to the first global label at each address."""
    labels: dict[BankedAddress, str] = {}
    for line in text.splitlines():
        match = _SYM_RE.match(line)
        if not match:
            continue
        bank, address, name = int(match.group(1), 16), int(match.group(2), 16), match.group(3)
        if not include_local and "." in name:
            continue
        if address >= 0x8000:
            continue  # RAM/HRAM symbols
        try:
            key = BankedAddress(bank, address)
        except ValueError:
            continue
        labels.setdefault(key, name)
    return labels


def load_sym(path: Path, include_local: bool = False) -> dict[BankedAddress, str]:
    return parse_sym(path.read_text(encoding="utf-8", errors="replace"), include_local)


def parse_editor_ref(text: str) -> list[tuple[str, int]]:
    """Parse a WL3 Editor ref file: `name= hex` lines, `;` comments, `[section]` headers ignored."""
    entries: list[tuple[str, int]] = []
    for raw in text.splitlines():
        line = raw.rstrip()
        if not line.strip() or line.lstrip().startswith(";") or line.lstrip().startswith("["):
            continue
        match = _REF_RE.match(line)
        if match:
            entries.append((match.group(1).strip(), int(match.group(2), 16)))
    return entries
