"""Decode Action Help's data (WL3-051): its framesets, OAM tables, tables, and graphics.

Question: what does Action Help's state depend on in ROM, and what does it draw?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM):
- _ActionHelpStateTable (7e:4000, src/engine/action_help/) shows a power-up's demo. Its objects
  animate with UpdateObjAnim (src/home/object_animation.asm) in the bank mapped: the cursor, d-pad,
  and buttons with `farcall $79`, the demo's Wario with `farcall $5` (the level's Wario framesets),
  and the demo's other objects in the bank their struct names (hcall with wMenuObj4FramesetBank:
  bank $79's, or $03's block debris and vanishing enemy, or $7f's owl).
- Its sprites are drawn through LoadSprite from OAM_1e697c (LoadActionHelpSprite), the level's
  Wario OAM tables in bank $05 (LoadActionHelpWarioSprite) or bank $7f's
  (LoadActionHelpWarioSprite_FromBank), and the objects' own tables (LoadActionHelpSprite_Far).
- Jumps step wActionHelpWarioVar through JumpVelTable_Normal or _HighJump (home bank 0), read as a
  byte index past the tables' ends; PowerUpOBPals (7e:7780) colours the cursor's power-up.
- Its graphics: ActionHelpObjects1Gfx or 2Gfx (bank 1's $8000), ActionHelpHUDGfx (bank 0's $8000),
  ActionHelpTilemap and Attrmap (BG map 1), decompressed with the levels' RLE; Wario's tiles
  (WarioIdleGfx and the others, $80 tiles each) by DMA to $8000; the palettes Pals_1e4e6f to
  Pals_1e4fbf (8 palettes each; Pals_1e4f6f and Pals_1e4fbf 2).
Research note: docs/02-research/action-help.md.
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

FORMAT = "wl3pc.action_help"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1
FRAMESETS = tuple(BankedAddress.parse(text) for text in (
    # bank $05: the level's Wario framesets
    "05:425f", "05:49c5", "05:4a0f", "05:4a23", "05:51fd", "05:522d", "05:5554", "05:555b", "05:556c",
    "05:558b", "05:55c5", "05:5f7f", "05:5f91", "05:5f94", "05:5f97", "05:5fa1", "05:5fc5", "05:6009",
    "05:6055", "05:640c", "05:6415", "05:641e", "05:6423", "05:642f", "05:6435", "05:6441", "05:66f7",
    "05:671d",
    # bank $79: the cursor, d-pad, buttons, blocks, and enemies
    "79:6b64", "79:6b67", "79:6b6a", "79:6b6d", "79:6b70", "79:6b73", "79:6b76", "79:6b79", "79:6b7c",
    "79:6b7f", "79:6b82", "79:6b85", "79:6b88", "79:6b8b", "79:6b8e", "79:6b93", "79:6b96", "79:6b99",
    "79:6b9c", "79:6ba2", "79:6ba5", "79:6ba8", "79:6f36", "79:6f3f", "79:6f48", "79:6f4d", "79:6f55",
    "79:6f5e", "79:6f66", "79:6f6b", "79:6f78", "79:6f7d", "79:6fc2", "79:6fcb",
    # bank $7f: the special power-ups' Wario
    "7f:542c", "7f:5439", "7f:546c", "7f:5479", "7f:582e", "7f:6d7c", "7f:6d91", "7f:6da6", "7f:6dbb",
    "7f:6dd0", "7f:6dfe", "7f:6eb4", "7f:6ec4",
    # bank $03: the block debris, the vanishing enemy, the owl
    "03:549a", "03:54a5", "03:57b4",
))
OAM_TABLES = tuple(BankedAddress.parse(text) for text in (
    "05:4000", "05:426c", "05:4d1b", "05:5254", "05:5955", "05:606a", "05:644a", "79:697c", "79:6bab",
    "79:6f86", "7f:5031", "7f:5498", "7f:5db4", "7f:6e05", "03:520e", "03:5763",
))
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "79:4fcf",  # ActionHelpHUDGfx
    "79:5871",  # ActionHelpObjects1Gfx
    "79:626b",  # ActionHelpObjects2Gfx
    "79:6796",  # ActionHelpTilemap
    "79:68bd",  # ActionHelpAttrmap
))
# Wario's tiles, $80 tiles each (`$80 dma_tiles`): idle, walk, swim, attack, throw, airborne, slide,
# bat, vampire, hang.
WARIO_GFX = ("04:4000", "04:4800", "04:6000", "04:5800", "04:7000", "04:7800", "09:5000", "0b:5800",
             "0b:6000", "0b:7800")
WARIO_GFX_SIZE = 0x80 * 0x10
PALETTES = {
    "79:4e6f": 0x40, "79:4eaf": 0x40, "79:4eef": 0x40, "79:4f2f": 0x40, "79:4f6f": 0x10, "79:4f7f": 0x40,
    "79:4fbf": 0x10,
}
TABLES = {
    # a byte index reaches 255 entries past the tables' starts
    "jump_vel_table_normal": (BankedAddress(0x00, 0x18A7), 0x100),
    "jump_vel_table_high_jump": (BankedAddress(0x00, 0x18CF), 0x100),
    "power_up_ob_pals": (BankedAddress(0x7E, 0x7780), 10),
}


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    return {"framesets": {str(where): decode_frameset(view, where) for where in FRAMESETS},
            "oam_tables": {str(where): decode_oam_table(view, where) for where in OAM_TABLES},
            "tables": {name: {"location": str(where), "bytes": view.read_banked(where, size).hex()}
                       for name, (where, size) in TABLES.items()},
            "gfx": {"compressed": {str(where): decompress(view, where, 0x2000)[0].hex() for where in COMPRESSED},
                    "wario": {key: view.read_banked(BankedAddress.parse(key), WARIO_GFX_SIZE).hex()
                              for key in WARIO_GFX},
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
                       "extractor": "wl3pc.extract.action_help", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "action_help.json", payload)
    return {"path": str(target / "action_help.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-action-help", description=__doc__.splitlines()[0])
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
    print(f"  {len(document['framesets'])} framesets, {len(document['oam_tables'])} OAM tables")
    return 0


if __name__ == "__main__":
    sys.exit(main())
