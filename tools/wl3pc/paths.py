"""Project-relative locations shared by the command-line tools."""

from __future__ import annotations

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]

# The user's original dump. Never written to; see AGENTS.md.
DEFAULT_ROM = PROJECT_ROOT / "Original_ROM" / "Wario Land 3 (World) (En,Ja).gbc"
EDITOR_REF_DIR = PROJECT_ROOT / "WL3 Editor" / "ref"

EXTERNAL_DIR = PROJECT_ROOT / "external"
LOCAL_DIR = PROJECT_ROOT / "local"
BUILD_DIR = PROJECT_ROOT / "build"
CONTENT_OUT_DIR = LOCAL_DIR / "content"

REFERENCES_LOCK = PROJECT_ROOT / "references.lock.json"
TOOLCHAIN_LOCK = PROJECT_ROOT / "toolchain.lock.json"


def rom_path_from_env() -> Path:
    """Return the ROM path selected by WL3PC_ROM, or the default location."""
    value = os.environ.get("WL3PC_ROM")
    return Path(value).expanduser() if value else DEFAULT_ROM
