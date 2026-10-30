"""Decode the golf minigame's game data (WL3-050): its framesets, holes, and stroke digits.

Question: what does the golf minigame's state depend on in ROM?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM):
- UpdateGolfObjectAnimation (src/home/load_golf_sprite.asm) steps a golf object through a frameset
  of (frame, duration) pairs, restarting at its first pair on $ff. The lobby, the holes' interface,
  the Para-Goom, the overlay texts, and the clear cutscene name their framesets in bank $72
  (src/engine/golf/lobby.asm, hole.asm); UpdateGolfWarioAnimation picks Golf Wario's by state and
  direction from Wario's own framesets in banks $05, $35, $7f, and home (bank $00).
- PickAndLoadGolfHole (hole.asm) reads GolfHoles (72:4ac3, 20 entries of 5 pointers): the first
  points at the hole's data in "Golf Gfx 1" ($70), whose 70 bytes go to wGolfHoleData (65 terrain
  blocks, the par, the hole's x position, and two water spawns). The others are its tile and
  attribute maps (presentation, not decoded here).
- PrintGolfStrokeNumber copies two tiles a digit from GolfStrokeNumbersGfx (72:640f) into w1db90,
  which is golf RAM, so the digits' bytes are part of the state.
- The screens' graphics (InitGolfLobby.LoadGolfLobby, InitGolfHole and PickAndLoadGolfHole,
  InitGolfClearCutscene.LoadCutsceneGfx) are decompressed with the levels' RLE (Decompress): the
  lobby's tiles (71:4f0d) and maps, the holes' tiles (70:4000), flag tiles (70:4c5f), the two
  backgrounds' maps and each hole's four (bank $70), the cutscene's tiles (35:5124) and maps. Raw:
  Golf Wario's tile sets by state (128 tiles each, by DMA), the flag, par, and stroke digits, the
  hole flag, the pin flag's four frames, and the screens' palettes (8 BG or OBJ palettes each).
- LoadGolfSprite draws an object's frame from the OAM table in wGolfOAMPtr (LoadSprite: frame
  pointers, then (y, x, tile, attributes) entries up to $80, as Wario's): the lobby's (72:72d3), the
  holes' (72:66cf), the clear cutscene's and the golf building menu's (72:73e0), and Golf Wario's by
  state (banks $05, $35, $72, $7f).
- The golf building (src/engine/golf/building/building.asm): Func_1c8604 decompresses the menu's
  tiles (GolfMenuGfx, the cutscene's 35:5124), its attribute map (71:4ea8), and its tile map (71:4c60,
  or 71:4d83 with every musical coin); Func_1c87db copies a course's 7 rows of attributes (labelled
  GolfBuildingCourse1Tilemap to 4, 71:48e0 on, $e0 bytes each) into golf RAM and its palettes
  (72:624f on); a scroll copies GolfBuildingCourseScrollingAttrmap (71:4800) into golf RAM; the menu's
  sprites are animated with framesets 72:7598 to 72:75e1.
Research note: docs/02-research/golf.md.
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
from .rle import decompress
from .wario_sprites import decode_oam_table

FORMAT = "wl3pc.golf"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 4
# Every frameset the golf code names (lobby.asm, hole.asm, load_golf_sprite.asm), by its label.
FRAMESETS = tuple(BankedAddress.parse(text) for text in (
    "72:6f6f", "72:6f81", "72:6f84", "72:6f87", "72:6f8a", "72:6f8d", "72:6fa0", "72:6fb1", "72:6fb6",
    "72:6fc7", "72:6fe8", "72:7005", "72:7016", "72:7035", "72:7068", "72:7089", "72:70a4", "72:70a9",
    "72:70c2", "72:70d7", "72:70da", "72:7285", "72:72ac", "72:73b3", "72:73c4", "72:73d1", "72:73d4",
    "72:73d7", "72:75cc", "72:75cf", "72:5b87", "72:5b8a",
    # The golf building's menu (Func_1c86f8): its objects, Golf Wario by course, and the Para-Goom.
    "72:7598", "72:759b", "72:759e", "72:75a1", "72:75c3", "72:75d8", "72:75db", "72:75de", "72:75e1",
    # UpdateGolfParaGoom's table has six entries; state 6 reads the next two bytes as its pointer
    # (Frameset_1c8e21's first pair, $4e23): its last pair and the terminator.
    "72:4e23",
    "05:4252", "05:425f", "05:49b4", "05:49c5", "05:4cf6", "05:51e4", "05:51fd", "35:4d1b", "35:4d5f",
    "7f:4473", "7f:447c", "00:2da4", "00:2da7", "00:2daa", "00:2dad", "00:2db0", "00:2db5",
))
GOLF_HOLES = BankedAddress(0x72, 0x4AC3)
NUM_GOLF_HOLES = 20
GOLF_HOLE_ENTRY_SIZE = 10
GOLF_HOLE_DATA_BANK = 0x70  # BANK("Golf Gfx 1"), which PickAndLoadGolfHole maps for the copy
GOLF_HOLE_DATA_SIZE = 70  # wGolfHoleDataEnd - wGolfHoleData
STROKE_NUMBERS = BankedAddress(0x72, 0x640F)
STROKE_NUMBERS_SIZE = 10 * 2 * 16  # two tiles a digit, 0-9
# Compressed with Decompress: tiles, then BG maps (tile and attribute maps).
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "71:4f0d", "70:4000", "70:4c5f", "35:5124",
    "71:5b4e", "71:5cbe", "71:5d6c", "71:5dc6", "70:55c5", "70:5651", "70:568a", "70:5716",
    "71:4c60", "71:4d83", "71:4ea8",
))
DECOMPRESS_CAPACITY = 0x2000
# Golf Wario's tiles by state (LoadGolfWarioStateGfx), copied raw by DMA, 128 tiles each.
WARIO_TILES = tuple(BankedAddress.parse(text) for text in ("04:4000", "04:4800", "04:5800", "71:4000", "0b:7000"))
WARIO_TILES_SIZE = 0x80 * 16
# Raw tiles: the flag digits, the par digits, the hole flag (four copies of six), the pin flag's
# four frames; the golf building menu's attribute rows (the scroll's, then each course's, 7 rows of
# 32); and the palettes (64 bytes: 8 palettes of 4 colours).
COURSE_ROWS_SIZE = 7 * 32
RAW = ((BankedAddress(0x72, 0x638F), 0x50), (BankedAddress(0x72, 0x63DF), 0x30),
       (BankedAddress(0x72, 0x654F), 0x180), (BankedAddress(0x72, 0x5D8D), 0x100),
       *((BankedAddress(0x71, address), COURSE_ROWS_SIZE) for address in range(0x4800, 0x4C60, COURSE_ROWS_SIZE)))
PALETTES = tuple(BankedAddress(0x72, address) for address in range(0x608F, 0x638F, 0x40))
OAM_TABLES = tuple(BankedAddress.parse(text) for text in (
    "72:66cf", "72:72d3", "72:73e0",
    "05:4000", "05:426c", "05:4d1b", "72:70dd", "35:49cc", "05:4a82", "7f:431b",
))
# UpdateGolfObjectAnimation keeps a frameset's offset in a byte, so a frameset has at most 128 pairs
# (Golf Wario's clear, 35:4d5f, has more than Wario's own decoder allows).
MAX_GOLF_FRAMESET_PAIRS = 128


def decode_frameset(view: RomView, start: BankedAddress) -> list[list[int]]:
    """(frame, duration) pairs up to the $ff terminator, which must lie in the same bank."""
    limit = 0x4000 if start.bank == 0 else 0x8000
    data = view.read_banked(start, min(2 * MAX_GOLF_FRAMESET_PAIRS + 1, limit - start.address))
    pairs: list[list[int]] = []
    for index in range(0, len(data) - 1, 2):
        if data[index] == 0xFF:
            return pairs
        pairs.append([data[index], data[index + 1]])
    if data[len(pairs) * 2:len(pairs) * 2 + 1] == b"\xff":
        return pairs
    raise MalformedDataError(f"frameset {start}: no $ff terminator within {len(data)} bytes")


def decode_holes(view: RomView) -> list[dict[str, Any]]:
    holes = []
    for index in range(NUM_GOLF_HOLES):
        entry = view.read_banked(BankedAddress(GOLF_HOLES.bank, GOLF_HOLES.address + index * GOLF_HOLE_ENTRY_SIZE),
                                 GOLF_HOLE_ENTRY_SIZE)
        pointers = [entry[i] | (entry[i + 1] << 8) for i in range(0, GOLF_HOLE_ENTRY_SIZE, 2)]
        data = BankedAddress(GOLF_HOLE_DATA_BANK, pointers[0])
        holes.append({"data_location": str(data), "data": view.read_banked(data, GOLF_HOLE_DATA_SIZE).hex(),
                      "maps": [f"{pointer:04x}" for pointer in pointers[1:]]})
    return holes


def decode_gfx(view: RomView, holes: list[dict[str, Any]]) -> dict[str, Any]:
    compressed = list(COMPRESSED)
    for hole in holes:  # each hole's maps, in bank $70 (PickAndLoadGolfHole maps "Golf Gfx 1")
        compressed.extend(BankedAddress(GOLF_HOLE_DATA_BANK, int(pointer, 16)) for pointer in hole["maps"])
    return {"compressed": {str(where): decompress(view, where, DECOMPRESS_CAPACITY)[0].hex() for where in compressed},
            "wario_tiles": {str(where): view.read_banked(where, WARIO_TILES_SIZE).hex() for where in WARIO_TILES},
            "raw": {str(where): view.read_banked(where, size).hex() for where, size in RAW},
            "palettes": {str(where): view.read_banked(where, 0x40).hex() for where in PALETTES}}


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    holes = decode_holes(view)
    return {"framesets": {str(where): decode_frameset(view, where) for where in FRAMESETS},
            "holes": holes,
            "gfx": decode_gfx(view, holes),
            "oam_tables": {str(where): decode_oam_table(view, where) for where in OAM_TABLES},
            "stroke_numbers": {"location": str(STROKE_NUMBERS),
                               "bytes": view.read_banked(STROKE_NUMBERS, STROKE_NUMBERS_SIZE).hex()}}


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
                       "extractor": "wl3pc.extract.golf", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "golf.json", payload)
    return {"path": str(target / "golf.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-golf", description=__doc__.splitlines()[0])
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
    print(f"  {len(document['framesets'])} framesets, {len(document['holes'])} holes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
