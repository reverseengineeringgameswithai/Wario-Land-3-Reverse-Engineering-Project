"""Decode a room's background graphics: tiles, block layouts, attributes, and CGB palettes (WL3-018).

Question: what does each block of a room look like?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM):
- LoadRoomGfx (30:4000) and the home loaders (src/home/load_room.asm) copy the room's block tiles
  ($200 bytes, 4 tile numbers per block) to wRoomBlockTiles, Decompress its block attributes into
  wRoomBlockAttributes ($200 bytes, 4 per block), its main tiles ($800 bytes) to v0Tiles2 ($9000,
  VRAM bank 0), its special tiles ($800) to the same address in VRAM bank 1, and its 8 palettes
  (64 bytes) to wTempPals1. The sources are resolved by tools/wl3pc/extract/rooms.py.
- The block queue (src/engine/level/block_queue.asm) writes a block's four tiles and attributes
  to the BG map top-left, top-right, bottom-left, bottom-right.
- A BG attribute byte is the CGB's: palette in bits 0-2, VRAM bank in bit 3, X flip in bit 5,
  Y flip in bit 6, priority over sprites in bit 7 (Pan Docs, "BG Map Attributes").
- With LCDC bit 4 clear (the level's BG tile data at $8800-$97ff), tile numbers 0-127 address
  $9000-$97ff, where the room's main and special tiles go. Numbers 128 and above address
  $8800-$8fff, which other loaders fill; the decoder reports any it meets instead of guessing.
Research note: docs/02-research/room-graphics.md.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..address import BankedAddress, RomView
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..png import encode_rgb, encode_rgba
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from . import block_functions as bf
from . import level_collision
from . import level_maps as lm
from . import rooms
from .block_functions import MalformedDataError
from .rle import DecompressError, decompress

FORMAT = "wl3pc.room-gfx"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 3
BLOCKS = 0x80
TILES_PER_SET = 0x80
TILE_BYTES = 16
PALETTES = 8
# Block tile order in the BG map (block_queue.asm): (x, y) of each of the four tiles in tiles.
TILE_POSITIONS = ((0, 0), (1, 0), (0, 1), (1, 1))

# Room animation (WL3-037; src/data/levels/rooms1.asm, src/engine/level/update_animated_tiles.asm,
# home/load_room.asm). A level room's header names an animated-tiles group and a palette cycle.
ANIMATED_TILES_GROUPS = BankedAddress(0x30, 0x4CE5)  # (frame duration, gfx) pairs
NUM_ANIMATED_TILES_GROUPS = 29
ANIMATED_TILES_GFX = BankedAddress(0x34, 0x4071)  # $200 bytes a gfx: 4 frames of 8 tiles
ANIMATED_TILES_GFX_SIZE = 0x200
ANIMATED_TILES_FIRST = 0x70  # UpdateRoomAnimatedTiles copies to v1Tiles2 tile $70
ROOM_PAL_CYCLES = BankedAddress(0x30, 0x4C51)  # pointers to 8 RoomPals indices and a duration
NUM_ROOM_PAL_CYCLES = 20
ROOM_PALCYCLE_LENGTH = 8
ROOM_PALS = BankedAddress(0x30, 0x4B1B)  # pointers into "Level Palettes", 8 BG palettes each
NUM_ROOM_PALS = (0x4C51 - 0x4B1B) // 2
LEVEL_PALETTES_BANK = 0x33


def decode_tile(data: bytes) -> list[int]:
    """64 colour indices (row by row) of one 2bpp tile: low bit plane first in each row."""
    pixels = []
    for y in range(8):
        low, high = data[2 * y], data[2 * y + 1]
        pixels.extend(((high >> (7 - x)) & 1) << 1 | ((low >> (7 - x)) & 1) for x in range(8))
    return pixels


def decode_palettes(data: bytes) -> list[list[list[int]]]:
    """8 palettes of 4 colours as [r, g, b] in 5-bit units (little-endian words, red lowest)."""
    colours = [data[i] | (data[i + 1] << 8) for i in range(0, len(data), 2)]
    rgb = [[c & 0x1F, (c >> 5) & 0x1F, (c >> 10) & 0x1F] for c in colours]
    return [rgb[4 * p:4 * p + 4] for p in range(PALETTES)]


def decode(rom: bytes, room: int) -> dict[str, Any]:
    record = rooms.decode(rom)["rooms"][room]
    if record.get("status") == "reset-sentinel" or "sources" not in record:
        raise MalformedDataError(f"room {room} has no record")
    view = RomView(rom)
    sources = record["sources"]
    block_tiles = view.read_banked(BankedAddress.parse(sources["block_tiles"]["location"]), 4 * BLOCKS)
    try:
        attributes, _ = decompress(view, BankedAddress.parse(sources["block_attributes"]["location"]), 4 * BLOCKS)
    except DecompressError as error:
        raise MalformedDataError(f"room {room} block attributes: {error}") from error
    if len(attributes) != 4 * BLOCKS:
        raise MalformedDataError(f"room {room} block attributes expand to {len(attributes)} bytes, not {4 * BLOCKS}")
    main = view.read_banked(BankedAddress.parse(sources["main_tiles"]["location"]), TILES_PER_SET * TILE_BYTES)
    special = view.read_banked(BankedAddress.parse(sources["special_tiles"]["location"]), TILES_PER_SET * TILE_BYTES)
    palettes = view.read_banked(BankedAddress.parse(sources["palettes"]["location"]), PALETTES * 8)
    high_tiles = sorted({block_tiles[i] for i in range(4 * BLOCKS) if block_tiles[i] >= TILES_PER_SET})
    return {
        "room": room,
        "sources": sources,
        "block_tiles": block_tiles.hex(),
        "block_attributes": bytes(attributes).hex(),
        "main_tiles": main.hex(),
        "special_tiles": special.hex(),
        "palettes": decode_palettes(palettes),
        "audit": {"tile_numbers_outside_room_tiles": high_tiles},
    }


def decode_animation(rom: bytes) -> dict[str, Any]:
    """The animated-tiles groups and their graphics, and the palette cycles with every RoomPals
    entry they name (InitRoomAnimatedTiles/Pals, UpdateRoomAnimatedTiles/Pals)."""
    view = RomView(rom)
    raw = view.read_banked(ANIMATED_TILES_GROUPS, 2 * NUM_ANIMATED_TILES_GROUPS)
    groups = [[raw[2 * i], raw[2 * i + 1]] for i in range(NUM_ANIMATED_TILES_GROUPS)]
    gfx = {}
    for index in sorted({g for _, g in groups}):
        start = BankedAddress(ANIMATED_TILES_GFX.bank, ANIMATED_TILES_GFX.address + index * ANIMATED_TILES_GFX_SIZE)
        gfx[str(index)] = view.read_banked(start, ANIMATED_TILES_GFX_SIZE).hex()
    pointers = view.read_banked(ROOM_PAL_CYCLES, 2 * NUM_ROOM_PAL_CYCLES)
    cycles = []
    for i in range(NUM_ROOM_PAL_CYCLES):
        pointer = pointers[2 * i] | (pointers[2 * i + 1] << 8)
        data = view.read_banked(BankedAddress(ROOM_PAL_CYCLES.bank, pointer), ROOM_PALCYCLE_LENGTH + 1)
        cycles.append({"palettes": list(data[:ROOM_PALCYCLE_LENGTH]), "duration": data[ROOM_PALCYCLE_LENGTH]})
    pal_pointers = view.read_banked(ROOM_PALS, 2 * NUM_ROOM_PALS)
    room_pals = {}
    for index in sorted({p for cycle in cycles for p in cycle["palettes"]}):
        pointer = pal_pointers[2 * index] | (pal_pointers[2 * index + 1] << 8)
        room_pals[str(index)] = decode_palettes(view.read_banked(BankedAddress(LEVEL_PALETTES_BANK, pointer), PALETTES * 8))
    return {"animated_tiles_groups": groups, "animated_tiles_gfx": gfx, "pal_cycles": cycles, "room_pals": room_pals}


def block_pixel_info(document: dict[str, Any], block: int) -> list[tuple[tuple[int, int, int], int, bool] | None]:
    """256 pixels (16 x 16, row by row) of a block as (5-bit RGB, colour index, priority over sprites);
    None where a tile is outside the room's sets."""
    tiles = bytes.fromhex(document["block_tiles"])
    attributes = bytes.fromhex(document["block_attributes"])
    sets = (bytes.fromhex(document["main_tiles"]), bytes.fromhex(document["special_tiles"]))
    out: list[tuple[tuple[int, int, int], int, bool] | None] = [None] * 256
    for k, (tx, ty) in enumerate(TILE_POSITIONS):
        number, attribute = tiles[4 * block + k], attributes[4 * block + k]
        if number >= TILES_PER_SET:
            continue
        data = sets[(attribute >> 3) & 1][number * TILE_BYTES:(number + 1) * TILE_BYTES]
        indices = decode_tile(data)
        palette = document["palettes"][attribute & 7]
        for y in range(8):
            for x in range(8):
                sx = 7 - x if attribute & 0x20 else x
                sy = 7 - y if attribute & 0x40 else y
                index = indices[sy * 8 + sx]
                out[(ty * 8 + y) * 16 + tx * 8 + x] = (tuple(palette[index]), index, bool(attribute & 0x80))
    return out


def block_pixels(document: dict[str, Any], block: int) -> list[tuple[int, int, int] | None]:
    """256 pixels (16 x 16, row by row) of a block in 5-bit RGB; None where a tile is outside the room's sets."""
    return [None if info is None else info[0] for info in block_pixel_info(document, block)]


def _to_8bit(colour: tuple[int, int, int] | None) -> bytes:
    if colour is None:
        return bytes([255, 0, 255])
    return bytes((c << 3) | (c >> 2) for c in colour)


def blocks_png(document: dict[str, Any]) -> bytes:
    """All 128 blocks, 16 a row (256 x 128 px); magenta marks tiles outside the room's sets."""
    width, height = 16 * 16, 8 * 16
    canvas = bytearray(width * height * 3)
    for block in range(BLOCKS):
        bx, by = (block % 16) * 16, (block // 16) * 16
        for i, colour in enumerate(block_pixels(document, block)):
            x, y = bx + i % 16, by + i // 16
            canvas[(y * width + x) * 3:(y * width + x) * 3 + 3] = _to_8bit(colour)
    return encode_rgb(width, height, bytes(canvas))


def priority_png(document: dict[str, Any]) -> bytes:
    """The blocks as blocks_png lays them out, keeping only pixels drawn over sprites (a tile with
    attribute bit 7 and a colour index other than 0); everything else is transparent."""
    width, height = 16 * 16, 8 * 16
    canvas = bytearray(width * height * 4)
    for block in range(BLOCKS):
        bx, by = (block % 16) * 16, (block // 16) * 16
        for i, info in enumerate(block_pixel_info(document, block)):
            if info is None or not info[2] or info[1] == 0:
                continue
            x, y = bx + i % 16, by + i // 16
            canvas[(y * width + x) * 4:(y * width + x) * 4 + 4] = _to_8bit(info[0]) + b"\xff"
    return encode_rgba(width, height, bytes(canvas))


def tiles_png(document: dict[str, Any]) -> bytes:
    """Main tiles (left) and special tiles (right), 16 a row, as grey levels of their colour indices."""
    width, height = 2 * 16 * 8, 8 * 8
    canvas = bytearray(width * height * 3)
    grey = (255, 170, 85, 0)
    for side, key in enumerate(("main_tiles", "special_tiles")):
        data = bytes.fromhex(document[key])
        for number in range(TILES_PER_SET):
            indices = decode_tile(data[number * TILE_BYTES:(number + 1) * TILE_BYTES])
            ox, oy = side * 128 + (number % 16) * 8, (number // 16) * 8
            for i, index in enumerate(indices):
                x, y = ox + i % 8, oy + i // 8
                canvas[(y * width + x) * 3:(y * width + x) * 3 + 3] = bytes([grey[index]] * 3)
    return encode_rgb(width, height, bytes(canvas))


def rooms_of_level(rom: bytes, level: int) -> list[int]:
    return sorted({r["fields"]["room"] for r in level_collision.build(rom, level)["rooms"]})


def extract(rom_path: Path, out_dir: Path, level: int, exploratory: bool = False) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, lm.WL3_WORLD_MAP_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original") / "rooms"
    written = []
    for room in rooms_of_level(rom, level):
        document = decode(rom, room)
        document.update({
            "format": FORMAT, "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
            "exploratory": is_exploratory,
            "provenance": {"rom_sha256": report.hashes.sha256, "rom_id": report.identity.rom_id,
                           "extractor": "wl3pc.extract.room_gfx", "extractor_version": EXTRACTOR_VERSION,
                           "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
        })
        payload = canonical_json(document)
        name = f"room-{room:03d}"
        write_immutable(target / f"{name}.gfx.json", payload)
        write_immutable(target / f"{name}-blocks.png", blocks_png(document))
        write_immutable(target / f"{name}-priority.png", priority_png(document))
        write_immutable(target / f"{name}-tiles.png", tiles_png(document))
        written.append({"room": room, "sha256": sha256_bytes(payload),
                        "outside": document["audit"]["tile_numbers_outside_room_tiles"]})
    animation = decode_animation(rom)
    animation.update({"format": "wl3pc.room-animation", "format_version": 1, "marker": ROM_DERIVED_MARKER,
                      "exploratory": is_exploratory,
                      "provenance": {"rom_sha256": report.hashes.sha256, "rom_id": report.identity.rom_id,
                                     "extractor": "wl3pc.extract.room_gfx", "extractor_version": EXTRACTOR_VERSION,
                                     "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY}})
    write_immutable(target / "animation.json", canonical_json(animation))
    return {"directory": str(target), "rooms": written}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-room-gfx", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--level", type=lambda text: int(text, 0), default=0, help="extract the rooms of this level")
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    try:
        result = extract(args.rom or rom_path_from_env(), args.out, args.level, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    for item in result["rooms"]:
        note = f"; tile numbers outside the room's sets: {item['outside']}" if item["outside"] else ""
        print(f"wrote room {item['room']:3d} graphics to {result['directory']} sha256 {item['sha256'][:12]}{note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
