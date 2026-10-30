"""Review tools for the emulator oracle: collision-probe traces, event timelines, and frame sheets.

Probe traces use PyBoy execution hooks. A hook replaces the instruction at an address
with opcode $DB in the emulated ROM, runs a callback, then executes the original
instruction; a run with hooks keeps the same memory, frame by frame, as one without
(checked by `probe_trace`, which compares memory digests with a plain run).
`ProcessBlock` (06:4000) is hooked on entry, and the `ld b, a` after each of its 10
`call` sites in src/engine/level/collisions.asm is hooked to read the handler's result.
Research note: docs/02-research/emulator-oracle.md.
"""

from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from . import oracle

PROCESS_BLOCK = 0x4000  # bank 06
CALL_SITES = (0x5B5C, 0x5B86, 0x5B96, 0x5BA6, 0x5BB2, 0x5BBE, 0x5BCE, 0x5BF6, 0x5C06, 0x5C16)
PROBE_NAMES = {0x01: "down", 0x02: "unk1", 0x04: "unk2", 0x08: "unk3",
               0x10: "unk4", 0x20: "unk5", 0x40: "unk6", 0x80: "unk7"}
# WRAM/HRAM addresses from the reference .sym (ElectroDeoxys @560fce6); tests check them.
W_COLLISION_POINTS, W_BREAK, W_SPECIAL, W_WARIO = 0xC0D6, 0xC0D8, 0xC0D9, 0xC0DA
W_BLOCK_PTR_BANK, W_BLOCK_PTR, W_BLOCK_FUNCTION_TABLE, H_POS = 0xCCE9, 0xCCEA, 0xCD00, 0xFFA8
# Map bit 7 means "this block's object is not spawned": SpawnObject clears it and DespawnObject sets it
# again (src/engine/level/load_objects.asm, block_queue.asm), so live blocks may differ from the
# decoded map in this bit alone while their objects are on screen.
OBJECT_NOT_SPAWNED = 0x80
PROBE_COLUMNS = ("tick", "probe", "wario", "break", "special", "y", "x", "sram_bank", "pointer", "block",
                 "handler", "result", "y_after", "x_after")
# wState values, from src/constants/state_constants.asm (ElectroDeoxys @560fce6); a test checks them.
STATE_NAMES = ("ST_TITLE", "ST_OVERWORLD", "ST_LEVEL", "ST_CLEAR", "ST_PAUSE_MENU", "ST_GOLF", "ST_EPILOGUE",
               "ST_ACTION_HELP", "ST_COLLECT_KEY", "ST_CREDITS", "ST_GOLF_BUILDING", "ST_GB_INCOMPATIBLE",
               "ST_GAME_OVER", "ST_PERFECT", "ST_LANGUAGE_SELECTION")
TIMELINE_FIELDS = ("wState", "wSubState", "wLevel", "wLevelRoomID", "wRoom", "wKeyAndTreasureFlags",
                   "wNumCollectedTreasures", "wTransformation", "wPowerUpLevel")


def check_call_sites(rom: bytes) -> None:
    """Refuse to hook unless the ROM has `call ProcessBlock` + `ld b, a` exactly at the recorded sites."""
    bank6 = rom[6 * 0x4000:7 * 0x4000]
    for site in CALL_SITES:
        offset = site - 0x4000
        if bank6[offset:offset + 4] != bytes([0xCD, 0x00, 0x40, 0x47]):
            raise oracle.OracleError(f"06:{site:04x} is not `call ProcessBlock; ld b, a` in this ROM")


class ProbeTracer:
    """Records every ProcessBlock call: inputs on entry, result and probe position on return."""

    def __init__(self, pyboy: Any, rom: bytes) -> None:
        check_call_sites(rom)
        self.pyboy, self.tick = pyboy, 0
        self.pending: list[list[int]] = []
        self.calls: list[list[int]] = []
        pyboy.hook_register(0x06, PROCESS_BLOCK, self._enter, None)
        for site in CALL_SITES:
            pyboy.hook_register(0x06, site + 3, self._return, None)

    def _pos(self) -> tuple[int, int]:
        m = self.pyboy.memory
        return (m[H_POS] << 8) | m[H_POS + 1], (m[H_POS + 2] << 8) | m[H_POS + 3]

    def _enter(self, _context: Any) -> None:
        m = self.pyboy.memory
        bank, pointer = m[W_BLOCK_PTR_BANK], (m[W_BLOCK_PTR] << 8) | m[W_BLOCK_PTR + 1]
        block = m[bank, pointer] if 0xA000 <= pointer < 0xC000 else -1
        index = W_BLOCK_FUNCTION_TABLE + 2 * (block & 0x7F) if block >= 0 else W_BLOCK_FUNCTION_TABLE
        handler = m[index] | (m[index + 1] << 8)
        y, x = self._pos()
        self.pending.append([self.tick, m[W_COLLISION_POINTS], m[W_WARIO], m[W_BREAK], m[W_SPECIAL], y, x,
                             bank, pointer, block, handler])

    def _return(self, _context: Any) -> None:
        if not self.pending:
            return
        y, x = self._pos()
        self.calls.append(self.pending.pop() + [self.pyboy.register_file.A, y, x])

    def close(self) -> None:
        self.pyboy.hook_deregister(0x06, PROCESS_BLOCK)
        for site in CALL_SITES:
            self.pyboy.hook_deregister(0x06, site + 3)


def probe_trace(rom: bytes, start: dict[str, Any], trace: dict[str, Any], digest_every: int = 60) -> dict[str, Any]:
    """Collision probes of a run, after proving the hooks leave memory unchanged against a plain run."""
    plain, hooked = oracle.start_from(rom, start), oracle.start_from(rom, start)
    tracer = ProbeTracer(hooked, rom)
    plain_digests: list[str] = []
    oracle.play(plain, trace, lambda t: plain_digests.append(oracle.ram_digest(plain))
                if t % digest_every == digest_every - 1 or t == trace["ticks"] - 1 else None)
    hooked_digests: list[str] = []

    def after(t: int) -> None:
        tracer.tick = t + 1
        if t % digest_every == digest_every - 1 or t == trace["ticks"] - 1:
            hooked_digests.append(oracle.ram_digest(hooked))

    oracle.play(hooked, trace, after)
    tracer.close()
    plain.stop(save=False)
    hooked.stop(save=False)
    if plain_digests != hooked_digests:
        raise oracle.OracleError("the probe hooks changed the run; the trace would not describe the original")
    by_handler: dict[str, Counter] = defaultdict(Counter)
    for call in tracer.calls:
        row = dict(zip(PROBE_COLUMNS, call))
        by_handler[f"h06_{row['handler']:04x}"][f"{PROBE_NAMES.get(row['probe'], hex(row['probe']))}"
                                                 f"{'' if row['wario'] else '/object'}->{row['result']:#04x}"] += 1
    return {
        "format": "wl3pc.oracle-probes", "format_version": 1, "marker": oracle.ROM_DERIVED_MARKER,
        "rom_sha256": oracle.sha256_bytes(rom), "emulator": oracle.emulator_config(), "start": start,
        "input": trace, "columns": list(PROBE_COLUMNS), "calls": tracer.calls,
        "hooks_unchanged_memory": True,
        "summary": {"calls": len(tracer.calls),
                    "by_handler": {k: dict(sorted(v.items())) for k, v in sorted(by_handler.items())}},
    }


def timeline(rom: bytes, start: dict[str, Any], trace: dict[str, Any], every: int = 30,
             sheet_dir: Path | None = None, columns: int = 6, rows: int = 6) -> dict[str, Any]:
    """Frames where tracked WRAM fields change, plus contact sheets of every `every`-th frame.

    BCD counters (oracle.BCD_SAMPLES) are reported as their decimal values (oracle.sample_value).
    """
    pyboy = oracle.start_from(rom, start)
    sizes = oracle.SAMPLE_SIZES
    previous: dict[str, int] | None = None
    events: list[dict[str, Any]] = []
    thumbnails: list[tuple[int, Any]] = []
    coins = []

    def after(t: int) -> None:
        nonlocal previous
        values = {name: oracle.read_value(pyboy, oracle.SAMPLE_ADDRESSES[name], sizes[name]) for name in TIMELINE_FIELDS}
        values = {name: oracle.sample_value(name, v) for name, v in values.items()}
        coins.append(oracle.sample_value("wNumCoins", oracle.read_value(pyboy, oracle.SAMPLE_ADDRESSES["wNumCoins"], 2)))
        if previous is not None:
            changed = {k: [previous[k], v] for k, v in values.items() if v != previous[k]}
            if changed:
                x = oracle.read_value(pyboy, oracle.SAMPLE_ADDRESSES["wWarioXPos"], 2)
                y = oracle.read_value(pyboy, oracle.SAMPLE_ADDRESSES["wWarioYPos"], 2)
                events.append({"tick": t, "changed": changed, "wario": [x, y]})
        previous = values
        if sheet_dir is not None and t % every == 0:
            thumbnails.append((t, pyboy.screen.image.copy()))

    oracle.play(pyboy, trace, after, render=(lambda t: t % every == 0) if sheet_dir is not None else None)
    pyboy.stop(save=False)
    sheets = _sheets(thumbnails, sheet_dir, columns, rows) if sheet_dir is not None else []
    return {"ticks": trace["ticks"], "events": events, "coins_start_end": [coins[0], coins[-1]] if coins else [],
            "sheets": [str(p) for p in sheets]}


def _sheets(thumbnails: list[tuple[int, Any]], directory: Path, columns: int, rows: int) -> list[Path]:
    from PIL import Image, ImageDraw

    directory.mkdir(parents=True, exist_ok=True)
    paths, per_sheet = [], columns * rows
    for first in range(0, len(thumbnails), per_sheet):
        chunk = thumbnails[first:first + per_sheet]
        used_rows = (len(chunk) + columns - 1) // columns
        sheet = Image.new("RGB", (columns * 162, used_rows * 158), "white")
        draw = ImageDraw.Draw(sheet)
        for i, (tick, image) in enumerate(chunk):
            x, y = (i % columns) * 162 + 1, (i // columns) * 158 + 13
            sheet.paste(image.convert("RGB"), (x, y))
            draw.text((x + 2, y - 12), f"frame {tick}", fill="black")
        path = directory / f"sheet-{chunk[0][0]:06d}-{chunk[-1][0]:06d}.png"
        sheet.save(path)
        paths.append(path)
    return paths


def movie_parts(path: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    """(start, input trace) of a recording, or of a bare input trace (which then starts at the route)."""
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("format") == "wl3pc.oracle-recording":
        oracle.check_document(document, "recording")
        return document["start"], document["input"]
    oracle.check_trace(document)
    return oracle.route_start("ootw-day1-start"), document


def check_block_map(rom: bytes, probes: dict[str, Any], level: int) -> dict[str, Any]:
    """Compare every probed live block with the statically decoded level block map (WL3-025)."""
    from .extract import level_maps

    level_map = next(m for m in level_maps.decode(rom)["maps"] if level in m["used_by_levels"])
    rows = [bytes.fromhex(row) for row in level_map["block_rows"]]
    return {"map": level_map["location"], "level": level, **compare_blocks(rows, probes)}


def compare_blocks(rows: list[bytes], probes: dict[str, Any]) -> dict[str, Any]:
    """Compare the first probe of each map cell with `rows`.

    The game keeps the map in SRAM banks 1-2 from $a000, one 256-byte page per row (32 rows per
    bank), so a probe's (bank, pointer) gives its row and column. A cell that differs only in
    OBJECT_NOT_SPAWNED is an object on screen; any other difference is a changed block (for
    example a broken one) or a wrong decode.
    """
    columns = dict(zip(PROBE_COLUMNS, range(len(PROBE_COLUMNS))))
    seen: dict[tuple[int, int], int] = {}
    mismatches: list[dict[str, Any]] = []
    for call in probes["calls"]:
        bank, pointer, block = call[columns["sram_bank"]], call[columns["pointer"]], call[columns["block"]]
        if block < 0 or not 1 <= bank <= 2:
            continue
        row, column = (bank - 1) * 32 + ((pointer - 0xA000) >> 8), pointer & 0xFF
        if column >= len(rows[0]) or row >= len(rows) or (row, column) in seen:
            continue
        seen[(row, column)] = block
        if rows[row][column] != block:
            kind = "object_spawned" if rows[row][column] ^ block == OBJECT_NOT_SPAWNED else "block_changed"
            mismatches.append({"tick": call[0], "row": row, "column": column, "live": block,
                               "decoded": rows[row][column], "kind": kind})
    return {"cells_checked": len(seen), "mismatches": mismatches,
            "kinds": dict(Counter(m["kind"] for m in mismatches))}


def describe_change(name: str, before: int, after: int) -> str:
    """`name before->after`, with state names for wState."""
    text = f"{name} {before}->{after}"
    if name == "wState":
        names = [STATE_NAMES[v] if v < len(STATE_NAMES) else "?" for v in (before, after)]
        text += f" ({names[0]}->{names[1]})"
    return text


def level_at(start_level: int, events: list[dict[str, Any]], tick: int) -> int:
    """wLevel at `tick`, from its value at the start and the timeline's changes up to that tick."""
    level = start_level
    for event in events:
        if event["tick"] > tick:
            break
        if "wLevel" in event["changed"]:
            level = event["changed"]["wLevel"][1]
    return level
