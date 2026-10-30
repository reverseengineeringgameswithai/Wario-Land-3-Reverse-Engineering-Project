"""Build an original-extracted content pack for the room a level starts in (WL3-013).

Chain: level header list entry 0 (StartRoom_FromLevelStart) -> room header ->
room record -> block function table -> per-block materials (tracked mapping)
-> the room's sections of the level block map, plus the spawn found in the
object map. Everything is decoded from the ROM by the other extractors.

Rules (ADR-0002): a block whose material is `unknown`, or not implemented by
the runtime, stops the build. A block with extra original behaviour on an
implemented material becomes a labelled approximation. The pack goes to the
ignored local/content/packs/ and is marked as ROM-derived.
Research note: docs/02-research/first-room-pack.md.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..paths import CONTENT_OUT_DIR, PROJECT_ROOT, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_file, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from . import block_functions as bf
from . import block_materials as bm
from . import level_headers as lh
from . import level_maps as lm
from . import rooms
from .block_functions import MalformedDataError

EXTRACTOR_VERSION = 1
PACKS_DIR = CONTENT_OUT_DIR / "packs"
# Materials game/scripts/sim/collision_grid.gd implements (CollisionGrid.MATERIAL_IDS).
RUNTIME_MATERIALS = {"empty": ".", "solid": "#", "platform": "="}
APPROXIMATION_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
# Movement is not decoded yet (WL3-012); the synthetic prototype's provisional values stand in.
SYNTHETIC_MOVEMENT = PROJECT_ROOT / "game" / "assets" / "content" / "synthetic" / "movement.json"
# Tasks that will remove an approximation, by flag prefix.
FLAG_TASKS = {"breakable-": "WL3-026", "room-transition": "WL3-027", "door": "WL3-027"}
SECTION_PX = lm.SECTION_BLOCKS * 16


class PackError(ValueError):
    """The room cannot be expressed without hiding a difference from the original."""


def _task_for(flags: list[str]) -> str | None:
    for flag in flags:
        for prefix, task in FLAG_TASKS.items():
            if flag.startswith(prefix):
                return task
    return None


def _describe(block: dict[str, Any]) -> str:
    parts = [block["material"], *block["flags"]]
    if "replacement_block" in block:
        parts.append(f"becomes block ${block['replacement_block']:02x} when broken")
    if "room_transition" in block:
        parts.append(f"sets wRoomTransitionParam ${block['room_transition']:02x}")
    return ", ".join(parts)


def legend_for(blocks: list[dict[str, Any]], used: list[int]) -> tuple[dict[int, str], dict[str, str],
                                                                       list[dict[str, Any]]]:
    """Map used block IDs to legend characters; return (char per block ID, legend, approximations)."""
    char_of: dict[int, str] = {}
    legend: dict[str, str] = {}
    approximations: list[dict[str, Any]] = []
    kinds: dict[str, str] = {}  # description -> char, so identical behaviour shares a character
    for block_id in sorted(set(used)):
        block = blocks[block_id]
        material = block["material"]
        if material == bm.UNKNOWN:
            raise PackError(f"block {block_id:#04x} uses a handler with no mapping row (unknown)")
        if material not in RUNTIME_MATERIALS:
            raise PackError(f"block {block_id:#04x} is {material!r}, which the runtime does not implement")
        if not block["flags"]:
            char = RUNTIME_MATERIALS[material]
            legend[char] = material
            char_of[block_id] = char
            continue
        description = _describe(block)
        if description not in kinds:
            if len(kinds) == len(APPROXIMATION_CHARS):
                raise PackError("more distinct approximated blocks than legend characters")
            char = APPROXIMATION_CHARS[len(kinds)]
            kinds[description] = char
            legend[char] = material
            entry = {"subject": char, "behaves_as": material, "original": description}
            task = _task_for(block["flags"])
            if task:
                entry["task"] = task
            approximations.append(entry)
        char_of[block_id] = kinds[description]
    return char_of, legend, approximations


def build(rom: bytes, mapping: dict[str, Any], level: int, movement: dict[str, Any]) -> dict[str, Any]:
    """Return the pack's documents. Raises PackError or MalformedDataError instead of guessing."""
    headers = lh.decode(rom)
    entry = headers["levels"][level]
    if entry["status"] != "decoded" or entry["start_header"] is None:
        raise PackError(f"level {level:#04x} has no start room")
    fields = next(h["fields"] for h in headers["headers"] if h["location"] == entry["start_header"])
    room_number = fields["room"]
    record = rooms.decode(rom)["rooms"][room_number]
    table_index = record["fields"]["block_function_table"]
    blocks = bm.apply(bf.decode(rom), mapping)["tables"][table_index]["blocks"]
    level_map = next(m for m in lm.decode(rom)["maps"] if level in m["used_by_levels"])
    block_rows = [bytes.fromhex(row) for row in level_map["block_rows"]]
    object_rows = [bytes.fromhex(row) for row in level_map["object_rows"]]

    # Header limits as half-open section ranges (interpretation, docs/02-research/level-headers.md).
    top, bottom = fields["upper_y_limit"] * lm.SECTION_BLOCKS, fields["lower_y_limit"] * lm.SECTION_BLOCKS
    left, right = fields["left_x_limit"] * lm.SECTION_BLOCKS, fields["right_x_limit"] * lm.SECTION_BLOCKS
    if bottom > len(block_rows) or any(len(block_rows[y]) < right for y in range(top, bottom)):
        raise PackError(f"room {room_number} limits exceed the decoded block map")
    region = [[lm.block_id(block_rows[y][x]) for x in range(left, right)] for y in range(top, bottom)]
    char_of, legend, approximations = legend_for(blocks, [b for row in region for b in row])
    room_id = f"room-{room_number:03d}"
    for item in approximations:
        item["subject"] = f"room/{room_id}/legend/{item['subject']}"

    spawn_x, spawn_y = lm.find_spawn(object_rows, fields["spawn_x"], fields["spawn_y"])
    if not (left <= spawn_x < right and top <= spawn_y < bottom):
        raise PackError(f"spawn block ({spawn_x}, {spawn_y}) lies outside room {room_number}")
    point_x, point_y = lm.spawn_point_px(spawn_x, spawn_y)
    start_x = point_x - left * 16 - movement["body_width_px"] // 2
    start_y = point_y - top * 16 - movement["body_height_px"]
    if start_x < 0 or start_y < 0:
        raise PackError("the prototype body does not fit above and around the spawn point")
    approximations += [
        {"subject": "start", "behaves_as": "prototype body box with its bottom centre on the spawn point",
         "original": f"wWarioPos = ({point_x}, {point_y}) px in the level, from spawn block "
                     f"({spawn_x}, {spawn_y}); then UpdateFloor"},
        {"subject": "movement", "behaves_as": "synthetic prototype movement (provisional)",
         "original": "WalkVelTable, JumpVelTable_Normal and their consumers", "task": "WL3-012"},
    ]

    pack_id = f"wl3-level-{level:02x}-room-{room_number:03d}"
    pack = {
        "format": "wl3pc.content-pack", "format_version": 2, "id": pack_id,
        "title": f"Level ${level:02x} start room ROOM_{room_number:03d} (collision only)",
        "origin": "original-extracted",
        "license": f"{ROM_DERIVED_MARKER}: extracted from your own ROM for local use; do not redistribute.",
        "movement": "movement.json", "rooms": [f"rooms/{room_id}.json"],
        "start": {"room": room_id, "x_px": start_x, "y_px": start_y},
        "approximations": approximations,
    }
    room = {
        "format": "wl3pc.room", "format_version": 1, "id": room_id, "tile_size_px": 16, "legend": legend,
        "rows": ["".join(char_of[b] for b in row) for row in region],
    }
    movement = dict(movement, provisional=True,
                    source=f"{ROM_DERIVED_MARKER} pack; values copied from the synthetic prototype "
                           "(provisional until WL3-012)")
    details = {
        "level": level, "start_header": entry["start_header"], "room": room_number,
        "block_function_table": table_index, "block_map": level_map["location"],
        "region_blocks": {"left": left, "top": top, "right": right, "bottom": bottom},
        "spawn_block": [spawn_x, spawn_y], "spawn_point_px": [point_x, point_y],
    }
    return {"pack": pack, "room": room, "movement": movement, "details": details}


def extract(
    rom_path: Path,
    out_dir: Path = PACKS_DIR,
    level: int = 0,
    mapping_path: Path = bm.MAPPING_PATH,
    exploratory: bool = False,
) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, bf.WL3_WORLD_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"

    movement = json.loads(SYNTHETIC_MOVEMENT.read_text(encoding="utf-8"))
    built = build(rom, bm.load_mapping(mapping_path), level, movement)
    pack_dir = out_dir / ("exploratory" if is_exploratory else "") / built["pack"]["id"]
    provenance = {
        "marker": ROM_DERIVED_MARKER, "exploratory": is_exploratory,
        "rom_sha256": report.hashes.sha256, "rom_id": report.identity.rom_id,
        "extractor": "wl3pc.extract.room_pack", "extractor_version": EXTRACTOR_VERSION,
        "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY,
        "mapping_sha256": sha256_file(mapping_path), "movement_source": "game/assets/content/synthetic/movement.json",
        **built["details"],
    }
    room_file = built["pack"]["rooms"][0]
    changed = [
        write_immutable(pack_dir / "pack.json", canonical_json(built["pack"])),
        write_immutable(pack_dir / "movement.json", canonical_json(built["movement"])),
        write_immutable(pack_dir / room_file, canonical_json(built["room"])),
        # Not referenced by pack.json; loaders never read it.
        write_immutable(pack_dir / "provenance.json", canonical_json(provenance)),
    ]
    return {"path": str(pack_dir), "changed": any(changed), **built}


def summarise(result: dict[str, Any]) -> str:
    details, pack, room = result["details"], result["pack"], result["room"]
    region = details["region_blocks"]
    return "\n".join([
        f"room ROOM_{details['room']:03d}: {len(room['rows'][0])} x {len(room['rows'])} blocks from block map "
        f"{details['block_map']} columns {region['left']}-{region['right'] - 1}, rows {region['top']}-{region['bottom'] - 1}",
        f"block function table: {details['block_function_table']:#04x}; legend: {len(room['legend'])} characters",
        f"spawn block {tuple(details['spawn_block'])} -> start box at ({pack['start']['x_px']}, {pack['start']['y_px']}) px",
        f"labelled approximations: {len(pack['approximations'])}",
        *(f"  {a['subject']}: behaves as {a['behaves_as']}; original: {a['original']}"
          + (f" ({a['task']})" if "task" in a else "") for a in pack["approximations"]),
    ])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-room-pack", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=PACKS_DIR)
    parser.add_argument("--level", type=lambda text: int(text, 0), default=0, help="wLevel (default 0)")
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    rom_path = args.rom or rom_path_from_env()
    try:
        result = extract(rom_path, args.out, args.level, exploratory=args.exploratory)
    except FileNotFoundError as error:
        print(f"room-pack: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError, bm.MappingError, PackError) as error:
        print(f"room-pack: {error}", file=sys.stderr)
        return 3
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'})")
    print(summarise(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
