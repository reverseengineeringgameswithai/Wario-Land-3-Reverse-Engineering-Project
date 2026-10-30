"""Decode Wario's sprite graphics: tile sets, OAM layouts, and palettes (WL3-038).

Question: what does Wario look like in each frame of the states the port runs?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM):
- LoadWarioGfx (src/home/load_wario_gfx.asm) queues a V-Blank transfer of 128 tiles (length 127,
  so $800 bytes) from wDMASourceBank:wDMASourcePtr to v0Tiles0 ($8000, VRAM bank 0); each state
  names its set (WarioIdleGfx, WarioWalkGfx, ...), and LevelVBlankFunc performs the transfer.
- DrawWario (src/home/sprite.asm) passes wWarioOAMBank:wWarioOAMPtr, wWarioFrame, Wario's screen
  position, and wWarioAttributes to LoadSprite, which reads the frame's pointer from the table and
  copies (y, x, tile, attributes) entries, offset by the position and with the attributes XORed,
  until a $80 byte (src/macros/gfx.asm `frame_oam`). Sprites are 8x16 (LCDC_DEFAULT has
  LCDC_OBJ_16), so an entry's tile number names a pair: the even tile on top, the odd one below.
- An OBJ attribute byte is the CGB's: palette in bits 0-2, VRAM bank in bit 3, X flip in bit 5,
  Y flip in bit 6, behind BG colours 1-3 in bit 7 (Pan Docs, "OAM").
- StartRoom and SetWarioPal copy 2 palettes from wWarioPalsPtr ("Wario Palettes") to OBJ palettes
  0 and 1; colour 0 of an OBJ palette is transparent.
A table's frame count is not stored: its pointers come first and its frame data follows, so the
table ends where the lowest frame pointer points (checked against the reference build's labels).
Research note: docs/02-research/wario-sprites.md.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..address import BankedAddress, RomBoundsError, RomView
from ..known_roms import WL3_WORLD_EN_JA
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..png import encode_rgb
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from . import block_functions as bf
from .block_functions import MalformedDataError
from .room_gfx import TILE_BYTES, decode_palettes, decode_tile

FORMAT = "wl3pc.wario-sprites"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 25
TILES_PER_SET = 0x80  # LoadWarioGfx: wPendingDMALength 127 -> 128 tiles
FRAME_END = 0x80  # LoadSprite: `cp $80 / ret z`
OAM_ENTRIES = 40  # LoadSprite stops at OAM_SIZE; no frame can hold more
PALETTE_COUNT = 2  # StartRoom / SetWarioPal: `ld b, 2 palettes`


@dataclass(frozen=True)
class SpriteLayout:
    rom_id: str
    # (name, location): the sets the ported states write to wDMASourceBank:wDMASourcePtr
    tile_sets: tuple[tuple[str, BankedAddress], ...]
    # (name, location): the tables the ported states write to wWarioOAMBank:wWarioOAMPtr
    oam_tables: tuple[tuple[str, BankedAddress], ...]
    # (name, location): what wWarioPalsPtr points to in the ported states
    palettes: tuple[tuple[str, BankedAddress], ...]


WL3_WORLD_SPRITE_LAYOUT = SpriteLayout(
    rom_id=WL3_WORLD_EN_JA.rom_id,
    tile_sets=(
        ("WarioIdleGfx", BankedAddress(0x04, 0x4000)),
        ("WarioWalkGfx", BankedAddress(0x04, 0x4800)),
        ("WarioDizzyGfx", BankedAddress(0x04, 0x5000)),
        ("WarioAttackGfx", BankedAddress(0x04, 0x5800)),
        ("WarioSwimGfx", BankedAddress(0x04, 0x6000)),
        ("WarioLadderGfx", BankedAddress(0x04, 0x6800)),
        ("WarioAirborneGfx", BankedAddress(0x04, 0x7800)),
        ("WarioHotGfx", BankedAddress(0x09, 0x4000)),
        ("WarioBurntGfx", BankedAddress(0x09, 0x4800)),
        ("WarioSlideGfx", BankedAddress(0x09, 0x5000)),
        ("WarioStringGfx", BankedAddress(0x09, 0x5800)),
        ("WarioElectricGfx", BankedAddress(0x09, 0x6800)),
        ("WarioClearGfx", BankedAddress(0x0B, 0x7000)),
        ("WarioFatGfx", BankedAddress(0x09, 0x6000)),
        ("WarioBubbleGfx", BankedAddress(0x0B, 0x6800)),
        ("WarioHangGfx", BankedAddress(0x0B, 0x7800)),
        ("WarioZombieGfx", BankedAddress(0x0B, 0x4000)),
        ("WarioBouncyGfx", BankedAddress(0x0B, 0x4800)),
        ("WarioThrowGfx", BankedAddress(0x04, 0x7000)),
        ("WarioCrazyGfx", BankedAddress(0x0B, 0x5000)),
        ("WarioPuffyGfx", BankedAddress(0x09, 0x7000)),
        ("WarioSnowballGfx", BankedAddress(0x7A, 0x4800)),
        ("WarioBatGfx", BankedAddress(0x0B, 0x5800)),
        ("WarioVampireGfx", BankedAddress(0x0B, 0x6000)),
        ("WarioSnowmanGfx", BankedAddress(0x7A, 0x4000)),
        ("WarioFanGfx", BankedAddress(0x7A, 0x5000)),
        ("WarioMagicGfx", BankedAddress(0x7A, 0x6000)),
        ("WarioBallGfx", BankedAddress(0x7A, 0x6800)),
        ("WarioLaunchGfx", BankedAddress(0x7A, 0x5800)),
    ),
    oam_tables=(
        ("OAM_14000", BankedAddress(0x05, 0x4000)),  # idling
        ("OAM_1426c", BankedAddress(0x05, 0x426C)),  # walking, crouching
        ("OAM_14a82", BankedAddress(0x05, 0x4A82)),  # turning, doors
        ("OAM_14d1b", BankedAddress(0x05, 0x4D1B)),  # attacking
        ("OAM_15254", BankedAddress(0x05, 0x5254)),  # swimming
        ("OAM_155cc", BankedAddress(0x05, 0x55CC)),  # ladders
        ("OAM_15955", BankedAddress(0x05, 0x5955)),  # airborne, bumping, stung
        ("OAM_1644a", BankedAddress(0x05, 0x644A)),  # sliding, rolling
        ("OAM_16e9d", BankedAddress(0x05, 0x6E9D)),  # Flat Wario
        ("OAM_1673c", BankedAddress(0x05, 0x673C)),  # on fire, hot
        ("OAM_16b6c", BankedAddress(0x05, 0x6B6C)),  # burnt
        ("OAM_171c0", BankedAddress(0x05, 0x71C0)),  # ball o' string
        ("OAM_1790e", BankedAddress(0x05, 0x790E)),  # electric
        ("OAM_17bbc", BankedAddress(0x05, 0x7BBC)),  # dizzy
        ("OAM_1742d", BankedAddress(0x05, 0x742D)),  # Fat Wario
        ("OAM_1fc000", BankedAddress(0x7F, 0x4000)),  # treasure: laughing, opening
        ("OAM_1fc31b", BankedAddress(0x7F, 0x431B)),  # treasure: turning
        ("OAM_1fdb6d", BankedAddress(0x7F, 0x5B6D)),  # Ice Skatin'
        ("OAM_1fee05", BankedAddress(0x7F, 0x6E05)),  # hanging from a rail
        ("OAM_1fc48b", BankedAddress(0x7F, 0x448B)),  # Zombie Wario
        ("OAM_1fc95e", BankedAddress(0x7F, 0x495E)),  # Bouncy Wario
        ("OAM_1606a", BankedAddress(0x05, 0x606A)),  # picking up, throwing
        ("OAM_1fccd5", BankedAddress(0x7F, 0x4CD5)),  # Crazy Wario
        ("OAM_1dc93f", BankedAddress(0x77, 0x493F)),  # Puffy Wario
        ("OAM_1ffa12", BankedAddress(0x7F, 0x7A12)),  # split Wario
        ("OAM_1fd031", BankedAddress(0x7F, 0x5031)),  # the bat
        ("OAM_1fd498", BankedAddress(0x7F, 0x5498)),  # Vampire Wario
        ("OAM_1fd87c", BankedAddress(0x7F, 0x587C)),  # in a bubble
        ("OAM_1fddb4", BankedAddress(0x7F, 0x5DB4)),  # Owl Wario
        ("OAM_1feec7", BankedAddress(0x7F, 0x6EC7)),  # Snowman Wario
        ("OAM_1ff64a", BankedAddress(0x7F, 0x764A)),  # the snowball
        ("OAM_1dc000", BankedAddress(0x77, 0x4000)),  # Fan Wario
        ("OAM_17cf7", BankedAddress(0x05, 0x7CF7)),  # turning invisible
        ("OAM_1dcd60", BankedAddress(0x77, 0x4D60)),  # Magic Wario
        ("OAM_1dcff1", BankedAddress(0x77, 0x4FF1)),  # the ball
        ("OAM_1dc449", BankedAddress(0x77, 0x4449)),  # launched
    ),
    palettes=(
        ("WarioDefaultPal", BankedAddress(0x03, 0x4800)),
        ("WarioInvisiblePal", BankedAddress(0x03, 0x4810)),
        ("WarioOnFirePal", BankedAddress(0x03, 0x4820)),
        ("WarioHot1Pal", BankedAddress(0x03, 0x4830)),
        ("WarioHot2Pal", BankedAddress(0x03, 0x4840)),
        ("WarioHot3Pal", BankedAddress(0x03, 0x4850)),
        ("WarioStringPal", BankedAddress(0x03, 0x4860)),
        ("WarioElectricPal", BankedAddress(0x03, 0x4870)),
        ("WarioIceSkatinPal", BankedAddress(0x03, 0x4990)),
        # Zombie Wario, and the seven after it that UpdateState_ZombieRecovering steps through by
        # offset (labelled unused in the disassembly)
        ("WarioZombiePal", BankedAddress(0x03, 0x4890)),
        ("WarioUnused2Pal", BankedAddress(0x03, 0x48A0)), ("WarioUnused3Pal", BankedAddress(0x03, 0x48B0)),
        ("WarioUnused4Pal", BankedAddress(0x03, 0x48C0)), ("WarioUnused5Pal", BankedAddress(0x03, 0x48D0)),
        ("WarioUnused6Pal", BankedAddress(0x03, 0x48E0)), ("WarioUnused7Pal", BankedAddress(0x03, 0x48F0)),
        ("WarioUnused8Pal", BankedAddress(0x03, 0x4900)),
        ("WarioBouncyPal", BankedAddress(0x03, 0x4910)), ("WarioBouncyRedPal", BankedAddress(0x03, 0x4920)),
        ("WarioSplitPal", BankedAddress(0x03, 0x49E0)),
        ("WarioVampirePal", BankedAddress(0x03, 0x4950)),
        ("WarioBubblePal", BankedAddress(0x03, 0x4980)),
        ("WarioSnowmanPal", BankedAddress(0x03, 0x49A0)),
        ("WarioMagicPal", BankedAddress(0x03, 0x49B0)),
        ("WarioBallPal", BankedAddress(0x03, 0x49C0)), ("WarioBallShotPal", BankedAddress(0x03, 0x49D0)),
    ),
)


def _read(view: RomView, start: BankedAddress, length: int, what: str) -> bytes:
    try:
        return view.read_banked(start, length)
    except RomBoundsError as error:
        raise MalformedDataError(f"{what}: {error}") from error


def _signed(byte: int) -> int:
    return byte - 0x100 if byte >= 0x80 else byte


def decode_frame(view: RomView, start: BankedAddress) -> list[list[int]]:
    """[y, x, tile, attributes] entries (y and x signed) up to the $80 terminator."""
    entries: list[list[int]] = []
    for index in range(OAM_ENTRIES + 1):
        where = BankedAddress(start.bank, start.address + 4 * index)
        if _read(view, where, 1, f"OAM frame {start}")[0] == FRAME_END:
            return entries
        y, x, tile, attributes = _read(view, where, 4, f"OAM frame {start}")
        entries.append([_signed(y), _signed(x), tile, attributes])
    raise MalformedDataError(f"OAM frame {start}: no $80 terminator within {OAM_ENTRIES} entries")


def decode_oam_table(view: RomView, start: BankedAddress) -> list[list[list[int]]]:
    """Each frame's entries; the pointer list ends where the lowest frame pointer points."""
    pointers: list[int] = []
    end = 0x8000
    offset = start.address
    while offset < end:
        low, high = _read(view, BankedAddress(start.bank, offset), 2, f"OAM table {start}")
        pointer = low | (high << 8)
        if not start.address < pointer < 0x8000:
            raise MalformedDataError(f"OAM table {start}: frame {len(pointers)} points to {pointer:04x}")
        pointers.append(pointer)
        end = min(end, pointer)
        offset += 2
    if offset != end:
        raise MalformedDataError(f"OAM table {start}: the pointer list overlaps frame data at {end:04x}")
    return [decode_frame(view, BankedAddress(start.bank, pointer)) for pointer in pointers]


def decode(rom: bytes, layout: SpriteLayout = WL3_WORLD_SPRITE_LAYOUT) -> dict[str, Any]:
    view = RomView(rom)
    return {
        # Keyed "BB:AAAA", the bank and pointer the game stores (wDMASourceBank:wDMASourcePtr, ...).
        "tile_sets": {str(where): {"name": name, "tiles": _read(view, where, TILES_PER_SET * TILE_BYTES, name).hex()}
                      for name, where in layout.tile_sets},
        "oam_tables": {str(where): {"name": name, "frames": decode_oam_table(view, where)}
                       for name, where in layout.oam_tables},
        "palettes": {str(where): {"name": name,
                                  "colours": decode_palettes(_read(view, where, 8 * PALETTE_COUNT, name))[:PALETTE_COUNT]}
                     for name, where in layout.palettes},
    }


def sprite_pixels(document: dict[str, Any], tile_set: str, oam_table: str, frame: int, palette: str,
                  attributes: int = 0) -> dict[tuple[int, int], tuple[int, int, int]]:
    """Opaque pixels of one frame, as (x, y) offsets from Wario's position -> 5-bit RGB.

    Offsets are as DrawWario places them: an entry at (y, x) covers the screen pixels from
    (position x + x, position y + y). Earlier entries are drawn over later ones (the CGB's OAM
    order), so the first opaque pixel at a point wins. Entries using VRAM bank 1 are not Wario's
    tiles and are rejected.
    """
    tiles = bytes.fromhex(document["tile_sets"][tile_set]["tiles"])
    colours = document["palettes"][palette]["colours"]
    out: dict[tuple[int, int], tuple[int, int, int]] = {}
    for y, x, tile, entry_attributes in document["oam_tables"][oam_table]["frames"][frame]:
        attribute = entry_attributes ^ attributes
        if attribute & 0x08:
            raise MalformedDataError(f"{oam_table} frame {frame}: an entry uses VRAM bank 1")
        if (attribute & 7) >= PALETTE_COUNT:
            raise MalformedDataError(f"{oam_table} frame {frame}: an entry uses OBJ palette {attribute & 7}")
        pair = [decode_tile(tiles[n * TILE_BYTES:(n + 1) * TILE_BYTES]) for n in (tile & 0xFE, tile | 1)]
        for py in range(16):
            for px in range(8):
                sx = 7 - px if attribute & 0x20 else px
                sy = 15 - py if attribute & 0x40 else py
                index = pair[sy // 8][(sy % 8) * 8 + sx]
                if index != 0 and (x + px, y + py) not in out:
                    out[(x + px, y + py)] = tuple(colours[attribute & 7][index])
    return out


def tiles_png(document: dict[str, Any]) -> bytes:
    """Every tile set, one under another, 16 tiles a row, as grey levels of the colour indices."""
    names = list(document["tile_sets"])
    width, height = 16 * 8, len(names) * 8 * 8
    canvas = bytearray(width * height * 3)
    grey = (255, 170, 85, 0)
    for set_index, key in enumerate(names):
        data = bytes.fromhex(document["tile_sets"][key]["tiles"])
        for number in range(TILES_PER_SET):
            indices = decode_tile(data[number * TILE_BYTES:(number + 1) * TILE_BYTES])
            ox, oy = (number % 16) * 8, set_index * 64 + (number // 16) * 8
            for i, index in enumerate(indices):
                x, y = ox + i % 8, oy + i // 8
                canvas[(y * width + x) * 3:(y * width + x) * 3 + 3] = bytes([grey[index]] * 3)
    return encode_rgb(width, height, bytes(canvas))


def extract(rom_path: Path, out_dir: Path, exploratory: bool = False) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_SPRITE_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"
    document = decode(rom)
    document.update({
        "format": FORMAT, "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {"rom_sha256": report.hashes.sha256, "rom_id": report.identity.rom_id,
                       "extractor": "wl3pc.extract.wario_sprites", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "wario_sprites.json", payload)
    write_immutable(target / "wario-tiles.png", tiles_png(document))
    return {"path": str(target / "wario_sprites.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-wario-sprites", description=__doc__.splitlines()[0])
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
    frames = sum(len(table["frames"]) for table in document["oam_tables"].values())
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(f"  {len(document['tile_sets'])} tile sets, {len(document['oam_tables'])} OAM tables ({frames} frames), "
          f"{len(document['palettes'])} palettes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
