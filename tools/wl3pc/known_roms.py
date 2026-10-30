"""Identified ROM revisions. Only hashes and evidence live here, never payload bytes.

New provenance uses SHA-256. MD5 and SHA-1 are retained only to compare with
upstream READMEs. Details: docs/02-research/rom-identity.md.
"""

from __future__ import annotations

from dataclasses import dataclass

# SHA-256 of the 48-byte boot logo region ($0104-$0133). Confirmed on 2026-10-01
# to equal the Pan Docs logo bytes; the bytes themselves are deliberately not stored.
LOGO_SHA256 = "daf4cabdc852baa0291849203f0b41fd0b4ecd58e0d7aff4a509f5de4d7f9a2e"


@dataclass(frozen=True)
class KnownRom:
    rom_id: str
    name: str
    size: int
    md5: str
    sha1: str
    sha256: str
    evidence: tuple[str, ...]


WL3_WORLD_EN_JA = KnownRom(
    rom_id="wl3-world-en-ja",
    name="Wario Land 3 (World) (En,Ja)",
    size=2_097_152,
    md5="16bb3fb83e8cbbf2c4c510b9f50cf4ee",
    sha1="bb7877309834441fd03adb7fa65738e5d5b2d7ba",
    sha256="b625ed03e7553cc29ebc4203d919838312fc9f9f85915f5d2eddfe14aec77406",
    evidence=(
        "MD5 equals froggestspirit/wland3 rom.md5 at 29f1df63322efc635074c532e335896edf630515",
        "SHA-1 equals ElectroDeoxys/warioland3 rom.sha1 at 560fce6faf50df4a48c0448f00105b6075f8f231",
        "ElectroDeoxys/warioland3 @560fce6 built with RGBDS v1.0.0 is byte-identical (local reference build, 2026-10-01)",
    ),
)

KNOWN_ROMS: tuple[KnownRom, ...] = (WL3_WORLD_EN_JA,)
