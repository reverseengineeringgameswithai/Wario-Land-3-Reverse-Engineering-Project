"""Decode the level clear screen's data (WL3-043): its framesets, OAM tables, and tables.

Question: what does the clear screen's state depend on in ROM?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM):
- UpdateObjAnim (src/home/object_animation.asm) steps a menu object through a frameset of
  (frame, duration) pairs in the ROM bank mapped at the time; at $ff it resets the object's offset
  and duration (wObjAnimWasReset) without changing its frame. The clear screen (bank $35,
  src/engine/clear/, bank78.asm's object set-up) names its framesets in bank $35, and the musical
  coin screen's counter animates with one in bank $7c (`farcall $7c, UpdateObjAnim`).
- Its sprites are drawn by LoadClearScreenSprite (OAM_d4e26), LoadClearScreenWarioSprite
  (OAM_d49cc), LoadPencilSprite (OAM_d65e1), and LoadPauseMenuSprite (OAM_1f156c, bank $7c),
  through LoadSprite (frame pointers, then (y, x, tile, attributes) entries up to $80).
- The pencil scribbles by PencilScribbleXOffsets/YOffsets (52 bytes each), the musical coin screen
  colours a level's flag with MusicalCoinLevelBGPals (one BG attribute a level), and
  SetTreasureTransitionParam reads the level's treasure from LevelTreasureIDs_WithoutTemple (4 a
  level, in home bank 0).
- Its graphics (InitClearScreen and bank78.asm's loaders, InitTimeAttackClearScreen,
  InitMusicalCoinScreen) are decompressed with the levels' RLE: the treasure screen's tiles
  (ClearScreen1Gfx to $8800, ClearScreen2Gfx to bank 1's $8000) and maps, Time Attack's maps, the
  musical coin screen's tiles and maps (GolfMenuGfx, GolfMenuTilemap/Attrmap); raw: Clear Wario's
  tiles (WarioClearGfx), the treasures' (TreasureGfx, four tiles each, LoadTreasureTiles), each
  treasure's palette index (TreasureOBPals) and the four treasure palettes (TreasurePals), the
  levels' treasures with the Temple's first (LevelTreasureIDs, by wOWLevel), and the screens'
  palettes.
Research note: docs/02-research/clear-screen.md.
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
from .golf import decode_frameset
from .rle import decompress
from .wario_sprites import decode_frame

FORMAT = "wl3pc.clear"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 2
FRAMESETS = tuple(BankedAddress.parse(text) for text in (
    "35:4d18", "35:4d1b", "35:4d58", "35:4d5f", "35:5045", "35:504a", "35:504f", "35:5054", "35:5059",
    "35:505c", "35:505f", "35:5062", "35:5065", "35:5068", "35:506b", "35:5080", "35:5095", "35:5098",
    "35:509b", "35:509e", "35:50a1", "35:65f0", "7c:5cd4",
))
OAM_TABLES = tuple(BankedAddress.parse(text) for text in ("35:4e26", "35:49cc", "35:65e1", "7c:556c"))
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "78:4478", "78:51e8", "78:57fa", "78:5962", "78:5ae5", "78:5c5b", "35:5124", "35:63fd", "35:6502",
))
RAW = {
    "0b:7000": 0x800,  # WarioClearGfx
    "26:4000": 0x65 * 0x40,  # TreasureGfx: 4 tiles for each of the 101 treasures
    "26:6bf7": 0x65,  # TreasureOBPals
    "26:6d65": 0x20,  # TreasurePals
    "00:198b": 100,  # LevelTreasureIDs
}
PALETTES = tuple(BankedAddress.parse(text) for text in (
    "78:4378", "78:43b8", "78:43f8", "78:4438", "35:50a4", "35:50e4",
))
TABLES = {
    "pencil_x_offsets": (BankedAddress(0x35, 0x4964), 52),
    "pencil_y_offsets": (BankedAddress(0x35, 0x4998), 52),
    "musical_coin_level_bg_pals": (BankedAddress(0x35, 0x494B), 25),
    "level_treasure_ids": (BankedAddress(0x00, 0x198F), 100),
}


def decode_oam_table(view: RomView, start: BankedAddress) -> list[list[list[int]]]:
    """Each frame's entries (as wario_sprites' tables), a frame in home bank 0 allowed: the pause
    menu's table points one frame at EmptyOAMFrame. The pointer list ends where the lowest pointer
    into the table's own bank points."""
    pointers: list[int] = []
    end = 0x8000
    offset = start.address
    while offset < end:
        data = view.read_banked(BankedAddress(start.bank, offset), 2)
        pointer = data[0] | (data[1] << 8)
        if pointer >= 0x8000 or (0x4000 <= pointer <= start.address):
            raise MalformedDataError(f"OAM table {start}: frame {len(pointers)} points to {pointer:04x}")
        pointers.append(pointer)
        if pointer >= 0x4000:
            end = min(end, pointer)
        offset += 2
    if offset != end:
        raise MalformedDataError(f"OAM table {start}: the pointer list overlaps frame data at {end:04x}")
    return [decode_frame(view, BankedAddress(start.bank if pointer >= 0x4000 else 0, pointer)) for pointer in pointers]


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    return {"framesets": {str(where): decode_frameset(view, where) for where in FRAMESETS},
            "oam_tables": {str(where): decode_oam_table(view, where) for where in OAM_TABLES},
            "tables": {name: {"location": str(where), "bytes": view.read_banked(where, size).hex()}
                       for name, (where, size) in TABLES.items()},
            "gfx": {"compressed": {str(where): decompress(view, where, 0x2000)[0].hex() for where in COMPRESSED},
                    "raw": {key: view.read_banked(BankedAddress.parse(key), size).hex() for key, size in RAW.items()},
                    "palettes": {str(where): view.read_banked(where, 0x40).hex() for where in PALETTES}}}


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
                       "extractor": "wl3pc.extract.clear", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "clear.json", payload)
    return {"path": str(target / "clear.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-clear", description=__doc__.splitlines()[0])
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
