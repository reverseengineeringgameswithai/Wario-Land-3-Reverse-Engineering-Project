"""Decode the credits' data (WL3-052): their framesets, OAM tables, palettes, graphics, maps, and text.

Question: what do the credits, from the epilogue's save screen to the music box's close-up, load?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM): the
credits run in _CreditsStateTable (58:4000, src/engine/credits/state_table.asm) in bank $58.
InitCredits (src/engine/credits/credits.asm) loads LoadCreditsPals' Pals_1604cc and Pals_16050c
into the temporary palette sets; LoadCreditsGfx decompresses PrologueGfx (2c:5780) to VRAM 1's
$8000, copies $30 tiles of MusicBoxGfx (2c:4000, uncompressed) to VRAM 1's $8800, and decompresses
CreditsFontGfx and then CreditsMusicBoxGfx to VRAM 0's $8000; Func_16041f decompresses CreditsAttrmap
and CreditsTilemap to BG map 1 (all with Decompress). ShowCredits copies CreditsText a line at a time
(each line ends with $7f, the credits charmap's "\n") and CreditsPalsMap 13 bytes at a time (one
BG attribute a letter); the two are contiguous in bank $58. The music box and its winding key are
animated with UpdateObjAnim through the framesets InitCredits and the later sub-states name
(Frameset_161caf to Frameset_161cee, bank $58; the close-up's Frameset_15e7ed in "Credits OAM",
bank $57), and drawn by LoadCreditsSprite (OAM_1617e8) and LoadCreditsMusicBoxSprite (the table
wCreditsMusicBoxOAMPtr names: OAM_1617e8, or OAM_15e44a in bank $57). Func_1603be and Func_1603cb
load the close-up's palettes (Pals_16054c and Pals_16058c, then Pals_1605cc and Pals_16060c).
Research note: docs/02-research/credits.md.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..address import BankedAddress, RomView
from ..known_roms import WL3_WORLD_EN_JA
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from . import block_functions as bf
from .block_functions import MalformedDataError
from .clear import decode_oam_table
from .golf import decode_frameset
from .rle import decompress

FORMAT = "wl3pc.credits"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1
# The credits' framesets: the winding key's (Frameset_161caf), the music box's (Frameset_161cc4, and
# Frameset_161cee when it plays again), the close-up's (Frameset_161ce5, _161ce8, _161ceb in bank $58,
# Frameset_15e7ed in bank $57).
FRAMESETS = tuple(BankedAddress.parse(text) for text in (
    "58:5caf", "58:5cc4", "58:5ce5", "58:5ce8", "58:5ceb", "58:5cee", "57:67ed",
))
OAM_TABLES = tuple(BankedAddress.parse(text) for text in (
    "58:57e8",  # OAM_1617e8 (LoadCreditsSprite, and the music box's first table)
    "57:644a",  # OAM_15e44a (the close-up's music box)
))
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "2c:5780",  # PrologueGfx (to VRAM 1's $8000)
    "58:464c",  # CreditsFontGfx (to VRAM 0's $8000)
    "58:4af9",  # CreditsMusicBoxGfx (to VRAM 0's $8000, after the font)
    "58:5744",  # CreditsTilemap (BG map 1)
    "58:579c",  # CreditsAttrmap (BG map 1's attributes)
))
RAW = {
    "2c:4000": 0x300,  # MusicBoxGfx: the $30 tiles LoadCreditsGfx copies to VRAM 1's $8800
}
PALETTES = {
    "58:44cc": 0x40,  # Pals_1604cc (LoadCreditsPals, wTempPals1)
    "58:450c": 0x40,  # Pals_16050c (wTempPals2)
    "58:454c": 0x40,  # Pals_16054c (Func_1603be, wTempPals1)
    "58:458c": 0x40,  # Pals_16058c (wTempPals2)
    "58:45cc": 0x40,  # Pals_1605cc (Func_1603cb, wTempPals1)
    "58:460c": 0x40,  # Pals_16060c (wTempPals2)
}
# NUM_CREDITS_PAGES - 1 pages of 32 lines (one a BG map row), CREDITS_TEXT_LENGTH palettes each.
CREDITS_LINES = 9 * 32
CREDITS_TEXT_LENGTH = 13
TEXT_END = 0x7F  # the credits charmap's "\n"
CREDITS_TEXT = BankedAddress.parse("58:5d0f")
CREDITS_PALS_MAP = BankedAddress.parse("58:60e5")


def decode_text(view: RomView) -> bytes:
    """CreditsText: CREDITS_LINES lines, each up to and with its $7f."""
    data = view.read_banked(CREDITS_TEXT, CREDITS_PALS_MAP.address - CREDITS_TEXT.address)
    if data.count(TEXT_END) != CREDITS_LINES or data[-1] != TEXT_END:
        raise MalformedDataError(f"CreditsText {CREDITS_TEXT}: not {CREDITS_LINES} lines ending with ${TEXT_END:02x}")
    return data


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    text = decode_text(view)
    return {"framesets": {str(where): decode_frameset(view, where) for where in FRAMESETS},
            "oam_tables": {str(where): decode_oam_table(view, where) for where in OAM_TABLES},
            "tables": {"CreditsText": {"location": str(CREDITS_TEXT), "bytes": text.hex()},
                       "CreditsPalsMap": {"location": str(CREDITS_PALS_MAP), "bytes": view.read_banked(
                           CREDITS_PALS_MAP, CREDITS_LINES * CREDITS_TEXT_LENGTH).hex()}},
            "gfx": {"compressed": {str(where): decompress(view, where, 0x2000)[0].hex() for where in COMPRESSED},
                    "raw": {key: view.read_banked(BankedAddress.parse(key), size).hex() for key, size in RAW.items()},
                    "palettes": {key: view.read_banked(BankedAddress.parse(key), size).hex()
                                 for key, size in PALETTES.items()}}}


def extract(rom_path: Path, out_dir: Path, exploratory: bool = False) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_EN_JA.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"
    document = decode(rom)
    document.update({
        "format": FORMAT, "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {"rom_sha256": report.hashes.sha256, "rom_id": report.identity.rom_id,
                       "extractor": "wl3pc.extract.credits", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "credits.json", payload)
    return {"path": str(target / "credits.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-credits", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    try:
        result = extract(args.rom or rom_path_from_env(), args.out, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    document = result["document"]
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(f"  {len(document['framesets'])} framesets, {len(document['oam_tables'])} OAM tables, "
          f"{CREDITS_LINES} lines of text")
    return 0


if __name__ == "__main__":
    sys.exit(main())
