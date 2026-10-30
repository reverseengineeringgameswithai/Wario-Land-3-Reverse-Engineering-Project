"""Validate content packs, data-only mods, and input traces against schemas/ and semantic rules.

The Godot runtime enforces the same rules in game/scripts/content/content_loader.gd;
shared fixtures in tests/fixtures/content keep the two implementations aligned.
Requires the dev dependency `jsonschema` (make venv).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from .paths import PROJECT_ROOT

SCHEMA_DIR = PROJECT_ROOT / "schemas"
MAX_JSON_BYTES = 1024 * 1024
MAX_MOD_BYTES = 256 * 1024
MAX_MODS = 64


class ContentError(ValueError):
    pass


def _validator(name: str) -> Any:
    import jsonschema  # dev dependency; imported lazily so other tools stay stdlib-only

    schema = json.loads((SCHEMA_DIR / name).read_text(encoding="utf-8"))
    return jsonschema.Draft202012Validator(schema)


def _load(path: Path, limit: int = MAX_JSON_BYTES) -> Any:
    if path.is_symlink():
        raise ContentError(f"{path}: symbolic links are not accepted")
    if path.stat().st_size > limit:
        raise ContentError(f"{path}: larger than {limit} bytes")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ContentError(f"{path}:{error.lineno}: invalid JSON: {error.msg}") from error


def _schema_check(document: Any, schema: str, where: Path) -> None:
    errors = sorted(_validator(schema).iter_errors(document), key=lambda e: list(e.path))
    if errors:
        first = errors[0]
        location = "/".join(str(p) for p in first.path) or "(root)"
        raise ContentError(f"{where}: {location}: {first.message}")


def _inside(base: Path, relative: str) -> Path:
    current = base
    for part in Path(relative).parts:
        current = current / part
        if current.is_symlink():
            raise ContentError(f"{current}: symbolic links are not accepted")
    target = (base / relative).resolve()
    if not target.is_relative_to(base.resolve()):
        raise ContentError(f"{relative!r} escapes {base}")
    return target


PACK_SCHEMAS = {1: "content-pack.v1.schema.json", 2: "content-pack.v2.schema.json"}


def load_pack(pack_dir: Path) -> dict[str, Any]:
    manifest_path = pack_dir / "pack.json"
    pack = _load(manifest_path)
    version = pack.get("format_version") if isinstance(pack, dict) else None
    schema = PACK_SCHEMAS.get(version) if isinstance(version, int) and not isinstance(version, bool) else None
    _schema_check(pack, schema or PACK_SCHEMAS[1], manifest_path)
    movement_path = _inside(pack_dir, pack["movement"])
    movement = _load(movement_path)
    _schema_check(movement, "movement.v1.schema.json", movement_path)
    rooms: dict[str, dict[str, Any]] = {}
    for relative in pack["rooms"]:
        room_path = _inside(pack_dir, relative)
        room = _load(room_path)
        _schema_check(room, "room.v1.schema.json", room_path)
        widths = {len(row) for row in room["rows"]}
        if len(widths) != 1:
            raise ContentError(f"{room_path}: rows have different lengths {sorted(widths)}")
        unknown = {ch for row in room["rows"] for ch in row} - set(room["legend"])
        if unknown:
            raise ContentError(f"{room_path}: characters not in legend: {''.join(sorted(unknown))!r}")
        if room["id"] in rooms:
            raise ContentError(f"{room_path}: duplicate room id {room['id']!r}")
        rooms[room["id"]] = room
    start = pack["start"]
    if start["room"] not in rooms:
        raise ContentError(f"{manifest_path}: start room {start['room']!r} is not in the pack")
    room = rooms[start["room"]]
    tile = room["tile_size_px"]
    if start["x_px"] + movement["body_width_px"] > len(room["rows"][0]) * tile or \
            start["y_px"] + movement["body_height_px"] > len(room["rows"]) * tile:
        raise ContentError(f"{manifest_path}: start position places the body outside room {room['id']!r}")
    _check_approximations(pack.get("approximations", []), rooms, manifest_path)
    return {"pack": pack, "movement": movement, "rooms": rooms}


def _check_approximations(approximations: list[dict[str, Any]], rooms: dict[str, Any], where: Path) -> None:
    """ADR-0002: subjects are unique, and a room subject names a legend entry with the stated material."""
    seen: set[str] = set()
    for entry in approximations:
        subject = entry["subject"]
        if subject in seen:
            raise ContentError(f"{where}: approximation subject {subject!r} appears twice")
        seen.add(subject)
        if not subject.startswith("room/"):
            continue
        room_id, char = subject[len("room/"):-len("/legend/x")], subject[-1]
        room = rooms.get(room_id)
        if room is None or char not in room["legend"]:
            raise ContentError(f"{where}: approximation subject {subject!r} names no room legend entry")
        if room["legend"][char] != entry["behaves_as"]:
            raise ContentError(f"{where}: approximation {subject!r} behaves as {entry['behaves_as']!r}, "
                               f"but the legend says {room['legend'][char]!r}")


def apply_mod(content: dict[str, Any], mod_path: Path) -> None:
    mod = _load(mod_path, MAX_MOD_BYTES)
    _schema_check(mod, "mod.v1.schema.json", mod_path)
    if mod["target_pack"] != content["pack"]["id"]:
        raise ContentError(f"{mod_path}: targets {mod['target_pack']!r}, not {content['pack']['id']!r}")
    content["movement"].update(mod.get("movement", {}))
    for patch in mod.get("tile_patches", []):
        room = content["rooms"].get(patch["room"])
        if room is None:
            raise ContentError(f"{mod_path}: unknown room {patch['room']!r}")
        rows = room["rows"]
        for dy, patch_row in enumerate(patch["rows"]):
            y, x = patch["y"] + dy, patch["x"]
            if y >= len(rows) or x + len(patch_row) > len(rows[0]):
                raise ContentError(f"{mod_path}: patch at ({x}, {y}) exceeds room {patch['room']!r}")
            if set(patch_row) - set(room["legend"]):
                raise ContentError(f"{mod_path}: patch uses characters outside the room legend")
            rows[y] = rows[y][:x] + patch_row + rows[y][x + len(patch_row):]


def mod_files(mods_dir: Path) -> list[Path]:
    found = sorted(p / "mod.json" for p in mods_dir.iterdir() if p.is_dir() and (p / "mod.json").exists())
    if len(found) > MAX_MODS:
        raise ContentError(f"{mods_dir}: {len(found)} mods exceeds the limit of {MAX_MODS}")
    return found


def load_trace(path: Path) -> dict[str, Any]:
    trace = _load(path)
    _schema_check(trace, "input-trace.v1.schema.json", path)
    ticks = [event["tick"] for event in trace["events"]]
    if ticks != sorted(set(ticks)) or any(t >= trace["ticks"] for t in ticks):
        raise ContentError(f"{path}: event ticks must be strictly increasing and below `ticks`")
    return trace


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="content-check", description=__doc__.splitlines()[0])
    parser.add_argument("--pack", type=Path, default=PROJECT_ROOT / "game/assets/content/synthetic")
    parser.add_argument("--mods", type=Path, default=PROJECT_ROOT / "mods/examples")
    parser.add_argument("--traces", type=Path, default=PROJECT_ROOT / "game/assets/traces")
    parser.add_argument("--pack-only", action="store_true", help="validate only --pack (no mods or traces)")
    args = parser.parse_args(argv)
    try:
        content = load_pack(args.pack)
        approximations = len(content["pack"].get("approximations", []))
        print(f"pack {content['pack']['id']}: {len(content['rooms'])} room(s) OK"
              + (f"; {approximations} labelled approximation(s)" if approximations else ""))
        if args.pack_only:
            return 0
        for mod_path in mod_files(args.mods):
            apply_mod(load_pack(args.pack), mod_path)
            print(f"mod {mod_path.parent.name}: OK")
        for trace_path in sorted(args.traces.glob("*.json")):
            load_trace(trace_path)
            print(f"trace {trace_path.name}: OK")
    except (ContentError, OSError) as error:
        print(f"content-check: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
