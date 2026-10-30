"""Development oracle: run the identified ROM in PyBoy with deterministic per-frame input (WL3-014).

ADR-0001: the emulator is a local development oracle, never part of the shipped runtime.
Everything it produces from the ROM is ROM-derived and goes to the ignored local/ tree.
PyBoy is always given the ROM as bytes and never a ROM path, so it cannot create .ram,
.state, or .replay files next to the original ROM (it does that for paths).

Input model: a held-button set per frame, applied before the frame runs, in the
`input-trace.v1` format the native runtime also uses. On a movie's first frame every
button is set explicitly (released unless held), so the start's own button state never
leaks in. PyBoy (pinned version) must be importable by the interpreter running this
module; the rest of tools/ does not need it.

Starts: power-on (PyBoy's bundled boot ROM or the user's own dump; empty cartridge
RAM or the user's battery save), a tracked route, or an emulator save state. User
files are copied into a content-addressed store under local/oracle/ and named by
SHA-256 in every document. Research note: docs/02-research/emulator-oracle.md.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Any, Callable

from .known_roms import WL3_WORLD_EN_JA
from .paths import LOCAL_DIR, PROJECT_ROOT, rom_path_from_env
from .provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, sha256_file, write_immutable
from .rom import read_rom

PYBOY_VERSION = "2.7.0"
FORMAT_VERSION = 2  # routes, captures, and recordings (version 2 moved boot ROM and cartridge RAM into the start)
BUTTONS = ("up", "down", "left", "right", "a", "b", "start", "select")
ROUTES_DIR = Path(__file__).resolve().parent / "data" / "oracle"
CAPTURES_DIR = LOCAL_DIR / "captures"
RECORDINGS_DIR = LOCAL_DIR / "recordings"
STORE_DIR = LOCAL_DIR / "oracle"
# kind -> (directory, suffix). Sizes: a CGB boot ROM maps $0000-$08FF; PyBoy's own is a 256-byte stub.
# Cartridge RAM is 32 KiB (header RAM code $03, docs/02-research/rom-identity.md).
STORE_KINDS = {"boot-rom": ("bootroms", ".bin"), "save": ("saves", ".sav"), "state": ("states", ".state")}
BOOT_ROM_SIZES = (0x100, 0x900)
CARTRIDGE_RAM_SIZE = 0x8000
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
CHECKPOINT_EVERY = 60
LCD_HZ = 4194304 / 70224  # one LCD frame (Pan Docs); matches SimClock

# WRAM bank 0 addresses from the reference-build .sym (ElectroDeoxys @560fce6); tests check them.
# Multi-byte values are stored high byte first (GetNextLevelRoomID reads hi then lo).
SAMPLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wLevelRoomID", 0xC0A0, 1), ("wRoom", 0xC0C9, 1),
    ("wWarioSlopeInteraction", 0xC189, 1), ("wLevel", 0xCA06, 1), ("wWarioYPos", 0xCA61, 2),
    ("wWarioXPos", 0xCA63, 2), ("wDirection", 0xCA69, 1), ("wJumpVelTable", 0xCA74, 1),
    ("wJumpVelIndex", 0xCA75, 1), ("wWarioState", 0xCA83, 1), ("wWalkVelIndex", 0xCA86, 1),
    ("wTransformation", 0xCA8E, 1), ("wCameraSCY", 0xCAC4, 2), ("wCameraSCX", 0xCAC6, 2),
    ("wIsOnSteppableObject", 0xCAC9, 1), ("wNumCoins", 0xCA04, 2), ("wNumCollectedTreasures", 0xCA39, 2),
    ("wPowerUpLevel", 0xCA3C, 1), ("wKeyAndTreasureFlags", 0xCA5B, 1), ("wTransformationProgress", 0xCA8F, 1),
)
SAMPLE_ADDRESSES = {name: address for name, address, _ in SAMPLES}
SAMPLE_SIZES = {name: size for name, _, size in SAMPLES}
# Counters kept as binary-coded decimal, high byte first (`add`/`daa` in ObjInteraction_RegularCoin,
# UpdateNumCollectedTreasures), so raw $0021 means 21.
BCD_SAMPLES = frozenset({"wNumCoins", "wNumCollectedTreasures"})


def from_bcd(value: int) -> int | None:
    """Decimal value of a big-endian BCD number (0x0021 -> 21), or None if a nibble is above 9."""
    result, scale = 0, 1
    while True:
        digit = value & 0xF
        if digit > 9:
            return None
        result += digit * scale
        value >>= 4
        if not value:
            return result
        scale *= 10


def sample_value(name: str, raw: int) -> int:
    """A sample as the game means it: BCD counters in decimal; other samples, or invalid BCD, unchanged."""
    decoded = from_bcd(raw) if name in BCD_SAMPLES else None
    return raw if decoded is None else decoded


class OracleError(RuntimeError):
    """The oracle cannot run, or a replay did not reproduce what was recorded."""


# --- Emulator ------------------------------------------------------------------

def emulator_config() -> dict[str, Any]:
    return {"name": "PyBoy", "version": PYBOY_VERSION, "cgb": True, "sound_emulated": True}


def _pyboy_class() -> Any:
    try:
        import importlib.metadata
        from pyboy import PyBoy
    except ImportError as error:
        raise OracleError(f"PyBoy is not importable by {sys.executable}; the oracle needs PyBoy "
                          f"{PYBOY_VERSION} (see docs/02-research/emulator-oracle.md)") from error
    version = importlib.metadata.version("pyboy")
    if version != PYBOY_VERSION:
        raise OracleError(f"PyBoy {version} found; routes, movies, and states are pinned to {PYBOY_VERSION}")
    return PyBoy


def bundled_boot_rom() -> tuple[Path, str]:
    """PyBoy's own CGB boot ROM (used when no boot ROM is given) and its SHA-256."""
    _pyboy_class()
    import pyboy.core

    path = Path(os.path.dirname(pyboy.core.__file__)) / "bootrom_cgb.bin"
    return path, sha256_file(path)


def open_emulator(rom: bytes, boot_rom: dict[str, Any], cartridge_ram: dict[str, Any] | None = None) -> Any:
    """A powered-on emulator. The ROM is passed as bytes, so PyBoy derives no files next to it."""
    PyBoy = _pyboy_class()
    if boot_rom["source"] == "pyboy-bundled":
        boot_path, digest = bundled_boot_rom()
        if digest != boot_rom["sha256"]:
            raise OracleError("PyBoy's bundled boot ROM is not the one this file was made with")
    else:
        store_get("boot-rom", boot_rom["sha256"])  # integrity check
        boot_path = store_path("boot-rom", boot_rom["sha256"])
    ram = None
    if cartridge_ram is not None and cartridge_ram["source"] == "file":
        ram = io.BytesIO(store_get("save", cartridge_ram["sha256"]))
    config = emulator_config()
    pyboy = PyBoy(io.BytesIO(rom), window="null", cgb=config["cgb"], sound_emulated=config["sound_emulated"],
                  bootrom=str(boot_path), ram_file=ram, no_input=True, log_level="ERROR")
    pyboy.set_emulation_speed(0)
    return pyboy


def read_value(pyboy: Any, address: int, size: int) -> int:
    value = 0
    for byte in pyboy.memory[address:address + size]:
        value = (value << 8) | byte
    return value


def ram_digest(pyboy: Any) -> str:
    """SHA-256 over CPU registers and every RAM the game can write (not the ROM, IO, or palettes)."""
    digest = hashlib.sha256()
    regs = pyboy.register_file
    digest.update(bytes([regs.A, regs.F, regs.B, regs.C, regs.D, regs.E]))
    digest.update(b"".join(value.to_bytes(2, "little") for value in (regs.HL, regs.SP, regs.PC)))
    memory = pyboy.memory
    digest.update(bytes(memory[0xC000:0xD000]))  # WRAM bank 0 is not switchable
    for bank in range(1, 8):
        digest.update(_read_bank(memory, bank, 0xD000, 0xE000))
    for bank in range(2):
        digest.update(_read_bank(memory, bank, 0x8000, 0xA000))
    for bank in range(4):
        digest.update(_read_bank(memory, bank, 0xA000, 0xC000))
    digest.update(bytes(memory[0xFE00:0xFEA0]) + bytes(memory[0xFF80:0x10000]))
    return digest.hexdigest()


def _read_bank(memory: Any, bank: int, start: int, end: int) -> bytes:
    # PyBoy 2.7.0 rejects a banked slice whose (exclusive) end equals the region end,
    # so the last byte is read on its own.
    return bytes(memory[bank, start:end - 1]) + bytes([memory[bank, end - 1]])


def cartridge_ram_bytes(pyboy: Any) -> bytes:
    """The battery-backed cartridge RAM as a raw 32 KiB save file."""
    return b"".join(_read_bank(pyboy.memory, bank, 0xA000, 0xC000) for bank in range(CARTRIDGE_RAM_SIZE // 0x2000))


# --- Local content-addressed store (boot ROMs, battery saves, save states) --------

def store_path(kind: str, sha256: str) -> Path:
    if not SHA256_RE.match(sha256):
        raise OracleError(f"{sha256!r} is not a SHA-256")
    directory, suffix = STORE_KINDS[kind]
    return STORE_DIR / directory / f"{sha256}{suffix}"


def _check_store_data(kind: str, data: bytes) -> None:
    if kind == "boot-rom" and len(data) not in BOOT_ROM_SIZES:
        raise OracleError(f"a boot ROM is 2304 bytes (CGB) or 256 bytes; this file is {len(data)} bytes")
    if kind == "save" and len(data) != CARTRIDGE_RAM_SIZE:
        raise OracleError(f"a Wario Land 3 battery save is a raw {CARTRIDGE_RAM_SIZE}-byte cartridge RAM image; "
                          f"this file is {len(data)} bytes")
    if kind == "state" and not data:
        raise OracleError("the state file is empty")


def store_put(kind: str, data: bytes, metadata: dict[str, Any] | None = None) -> str:
    """Keep `data` under its SHA-256 (read-only); return the hash. Metadata goes in a .json beside it once."""
    _check_store_data(kind, data)
    digest = sha256_bytes(data)
    path = store_path(kind, digest)
    write_immutable(path, data)
    sidecar = path.with_suffix(".json")
    if metadata is not None and not sidecar.exists():
        write_immutable(sidecar, canonical_json(metadata))
    return digest


def store_get(kind: str, sha256: str) -> bytes:
    path = store_path(kind, sha256)
    if not path.exists():
        raise OracleError(f"no {kind} {sha256[:12]}… in {path.parent}; import it first")
    data = path.read_bytes()
    if sha256_bytes(data) != sha256:
        raise OracleError(f"{path} no longer matches its SHA-256")
    return data


def store_metadata(kind: str, sha256: str) -> dict[str, Any] | None:
    sidecar = store_path(kind, sha256).with_suffix(".json")
    return json.loads(sidecar.read_text(encoding="utf-8")) if sidecar.exists() else None


def import_file(kind: str, path: Path) -> str:
    """Copy one of the user's own files into the store (the original is only read)."""
    data = path.expanduser().read_bytes()
    warning = None
    if kind == "boot-rom" and len(data) == 0x100:
        warning = ("256-byte boot ROM: fine if it is a CGB stub such as PyBoy's own, but a DMG boot ROM leaves "
                   "the console identifying as a DMG and Wario Land 3 shows its GB-incompatible screen")
    digest = store_put(kind, data, {"imported_from": path.name, "bytes": len(data), "warning": warning})
    if warning:
        print(f"oracle: warning: {warning}", file=sys.stderr)
    return digest


# --- Starts -----------------------------------------------------------------------------

def power_on_start(boot_rom_sha: str | None = None, save_sha: str | None = None) -> dict[str, Any]:
    boot = ({"source": "file", "sha256": boot_rom_sha} if boot_rom_sha
            else {"source": "pyboy-bundled", "sha256": bundled_boot_rom()[1]})
    ram = {"source": "file", "sha256": save_sha} if save_sha else {"source": "empty"}
    return {"kind": "power-on", "boot_rom": boot, "cartridge_ram": ram}


def route_start(route_id: str) -> dict[str, Any]:
    route, digest = load_route(route_id)
    return {"kind": "route", "id": route["id"], "sha256": digest}


def state_start(sha256: str, boot_rom: dict[str, Any], origin: dict[str, Any] | None) -> dict[str, Any]:
    return {"kind": "state", "sha256": sha256, "boot_rom": boot_rom, "origin": origin}


def boot_rom_of(start: dict[str, Any]) -> dict[str, Any]:
    if start["kind"] == "route":
        return load_route(start["id"])[0]["start"]["boot_rom"]
    return start["boot_rom"]


def describe_start(start: dict[str, Any]) -> str:
    if start["kind"] == "route":
        return f"route {start['id']}"
    boot = start["boot_rom"]
    boot_text = "PyBoy boot ROM" if boot["source"] == "pyboy-bundled" else f"boot ROM {boot['sha256'][:8]}"
    if start["kind"] == "power-on":
        ram = start["cartridge_ram"]
        ram_text = "empty save" if ram["source"] == "empty" else f"save {ram['sha256'][:8]}"
        return f"power-on ({boot_text}, {ram_text})"
    origin = start.get("origin")
    where = f" from {origin.get('movie') or 'a movie'} at frame {origin['frame']}" if origin else ""
    return f"state {start['sha256'][:8]}{where}"


def start_label(start: dict[str, Any]) -> str:
    """A short file-name-safe name for a start."""
    if start["kind"] == "route":
        return start["id"]
    if start["kind"] == "state":
        return f"state-{start['sha256'][:12]}"
    label = "power-on"
    if start["cartridge_ram"]["source"] == "file":
        label += f"-save-{start['cartridge_ram']['sha256'][:8]}"
    if start["boot_rom"]["source"] == "file":
        label += f"-boot-{start['boot_rom']['sha256'][:8]}"
    return label


def check_document(document: dict[str, Any], kind: str) -> None:
    if document.get("format") != f"wl3pc.oracle-{kind}":
        raise OracleError(f"not a wl3pc.oracle-{kind} document")
    if document.get("format_version") != FORMAT_VERSION:
        raise OracleError(f"oracle {kind} format {document.get('format_version')} is not supported "
                          f"(this tool reads version {FORMAT_VERSION}); re-create it")


# --- Input traces ----------------------------------------------------------------

def check_trace(trace: dict[str, Any]) -> list[tuple[int, frozenset[str]]]:
    """Validate an input-trace.v1 document (same rules as tools/wl3pc/content.py) and return its events."""
    if trace.get("format") != "wl3pc.input-trace" or trace.get("format_version") != 1:
        raise OracleError("input must be a wl3pc.input-trace version 1 document")
    ticks = trace.get("ticks")
    if not isinstance(ticks, int) or isinstance(ticks, bool) or not 1 <= ticks <= 1_000_000:
        raise OracleError("input ticks must be an integer in 1..1000000")
    events, last = [], -1
    for event in trace.get("events", []):
        tick, held = event.get("tick"), event.get("held")
        if not isinstance(tick, int) or isinstance(tick, bool) or not last < tick < ticks:
            raise OracleError("input event ticks must be strictly increasing and below ticks")
        if not isinstance(held, list) or len(set(held)) != len(held) or set(held) - set(BUTTONS):
            raise OracleError(f"input event at tick {tick} has invalid held buttons {held!r}")
        events.append((tick, frozenset(held)))
        last = tick
    return events


def make_trace(held_per_tick: list[frozenset[str]], description: str) -> dict[str, Any]:
    """Compress per-tick held sets into input-trace.v1 events (one event per change)."""
    events, previous = [], frozenset()
    for tick, held in enumerate(held_per_tick):
        if tick == 0 or held != previous:
            events.append({"tick": tick, "held": sorted(held, key=BUTTONS.index)})
        previous = held
    return {"format": "wl3pc.input-trace", "format_version": 1, "description": description,
            "ticks": len(held_per_tick), "events": events}


def apply_held(pyboy: Any, previous: frozenset[str] | None, held: frozenset[str]) -> None:
    """Change the held buttons; PyBoy applies them from the next tick on.

    With `previous` unknown (None), every button is set: released unless held. PyBoy raises
    the joypad interrupt only when a released button is pressed, so setting a button to the
    state it already has changes nothing.
    """
    if previous is None:
        for button in BUTTONS:
            (pyboy.button_press if button in held else pyboy.button_release)(button)
        return
    for button in sorted(previous - held, key=BUTTONS.index):
        pyboy.button_release(button)
    for button in sorted(held - previous, key=BUTTONS.index):
        pyboy.button_press(button)


def play(pyboy: Any, trace: dict[str, Any], on_tick: Callable[[int], None] | None = None,
         render: Callable[[int], bool] | None = None) -> frozenset[str]:
    """Run every tick of `trace` from a fresh start; `on_tick(t)` runs after tick t, and tick t renders the
    screen when `render(t)` is true. Returns the final held set."""
    pending = check_trace(trace)
    held: frozenset[str] | None = None
    index = 0
    for tick in range(trace["ticks"]):
        if index < len(pending) and pending[index][0] == tick:
            apply_held(pyboy, held, pending[index][1])
            held = pending[index][1]
            index += 1
        elif held is None:
            apply_held(pyboy, None, frozenset())
            held = frozenset()
        pyboy.tick(1, render is not None and render(tick))
        if on_tick is not None:
            on_tick(tick)
    return held or frozenset()


# --- Routes (tracked; from power-on to a defined state) -----------------------

def load_route(route_id: str) -> tuple[dict[str, Any], str]:
    path = ROUTES_DIR / f"{route_id}.route.json"
    if not path.exists():
        raise OracleError(f"no route {route_id!r} in {ROUTES_DIR}")
    return json.loads(path.read_text(encoding="utf-8")), sha256_file(path)


def check_rom(rom: bytes, expected_sha256: str) -> None:
    if sha256_bytes(rom) != expected_sha256:
        raise OracleError("the ROM is not the one this route or recording was made with")


def start_from(rom: bytes, start: dict[str, Any]) -> Any:
    """A running emulator at the given start: power-on, the verified end of a route, or a save state."""
    kind = start["kind"]
    if kind == "power-on":
        return open_emulator(rom, start["boot_rom"], start["cartridge_ram"])
    if kind == "route":
        route, digest = load_route(start["id"])
        if start.get("sha256") not in (None, digest):
            raise OracleError(f"route {start['id']!r} changed since this file was made")
        check_document(route, "route")
        check_rom(rom, route["rom_sha256"])
        pyboy = start_from(rom, route["start"])
        play(pyboy, route["input"])
        verify_route_end(pyboy, route)
        return pyboy
    if kind == "state":
        pyboy = open_emulator(rom, start["boot_rom"])
        try:
            pyboy.load_state(io.BytesIO(store_get("state", start["sha256"])))
        except OracleError:
            raise
        except Exception as error:
            raise OracleError(f"PyBoy could not load state {start['sha256'][:12]}…: {error}") from error
        return pyboy
    raise OracleError(f"unknown start kind {kind!r}")


def verify_state(rom: bytes, sha256: str) -> str:
    """Load a stored state; if it records where it came from, rebuild it from there and compare memory."""
    metadata = store_metadata("state", sha256) or {}
    origin = metadata.get("origin")
    boot = boot_rom_of(origin["start"]) if origin else power_on_start()["boot_rom"]
    loaded = start_from(rom, state_start(sha256, boot, origin))
    digest = ram_digest(loaded)
    loaded.stop(save=False)
    if origin is None:
        return f"state {sha256[:12]}… loads (no origin recorded, so it cannot be rebuilt)"
    rebuilt = start_from(rom, origin["start"])
    if origin.get("level_poke"):
        from .oracle_levels import install_level_poke
        room = origin["level_poke"].get("room")
        install_level_poke(rebuilt, int(origin["level_poke"]["level"]), None if room is None else int(room["value"]))
    if origin["input"] is not None:
        play(rebuilt, origin["input"])
    if origin.get("end_pokes"):
        from .oracle_levels import apply_end_pokes
        apply_end_pokes(rebuilt, origin)
    rebuilt_digest = ram_digest(rebuilt)
    rebuilt.stop(save=False)
    if not digest == rebuilt_digest == origin["ram_sha256"]:
        raise OracleError(f"state {sha256[:12]}… does not match its origin when rebuilt")
    return (f"state {sha256[:12]}… matches its origin ({describe_start(origin['start'])} plus "
            f"{origin['frame']} frames) when rebuilt")


def verify_route_end(pyboy: Any, route: dict[str, Any]) -> None:
    for name, expected in route["expect"].items():
        actual = read_value(pyboy, SAMPLE_ADDRESSES[name], SAMPLE_SIZES[name])
        if actual != expected:
            raise OracleError(f"route {route['id']}: {name} is {actual:#x} after replay, expected {expected:#x}")
    if ram_digest(pyboy) != route["ram_sha256"]:
        raise OracleError(f"route {route['id']}: memory after replay differs from the recorded digest")


def build_ootw_day1_route(rom: bytes) -> dict[str, Any]:
    """Regenerate the tracked route by the documented policy (see the research note)."""
    start = power_on_start()
    pyboy = start_from(rom, start)
    memory = pyboy.memory
    held_per_tick: list[frozenset[str]] = []
    queue: list[frozenset[str]] = []  # scripted ticks still to play
    selected = False
    tick = 0
    while True:
        state, substate = memory[0xC09B], memory[0xC09C]
        if state == 0x02 and substate == 0x03 and not queue:
            break
        if not queue:
            if (state, substate) == (0x01, 0x0B) and not selected:
                selected = True  # the level map: wait, move to Out of the Woods, select it, then hands off
                queue = [frozenset()] * 30 + [frozenset({"left"})] * 4 + [frozenset()] * 90 + [frozenset({"a"})] * 2
            elif tick % 60 == 0 and not selected:
                button = "b" if (state, substate) == (0x01, 0x1D) else "a"  # B leaves the temple dialogue
                queue = [frozenset({button})] * 2
            else:
                queue = [frozenset()]
        held = queue.pop(0)
        apply_held(pyboy, held_per_tick[-1] if held_per_tick else None, held)
        held_per_tick.append(held)
        pyboy.tick(1, False)
        tick += 1
        if tick > 50_000:
            raise OracleError("route policy did not reach the level")
    settle = [frozenset()] * 60  # let the level start settle before the route ends
    for held in settle:
        apply_held(pyboy, held_per_tick[-1], held)
        held_per_tick.append(held)
        pyboy.tick(1, False)
    trace = make_trace(held_per_tick, "Power-on to Out of the Woods, day 1, Wario idle in ROOM_001")
    expect = {name: read_value(pyboy, SAMPLE_ADDRESSES[name], SAMPLE_SIZES[name])
              for name in ("wState", "wSubState", "wLevel", "wRoom", "wLevelRoomID", "wWarioState",
                           "wWarioYPos", "wWarioXPos")}
    return {
        "format": "wl3pc.oracle-route", "format_version": FORMAT_VERSION, "id": "ootw-day1-start",
        "description": "From power-on (PyBoy's boot ROM, empty cartridge RAM) to Out of the Woods, day 1, after the level "
                       "starts. Policy: A for 2 ticks every 60 ticks (B in the temple dialogue); on the map, "
                       "wait 30, Left for 4, wait 90, A for 2; then 60 idle ticks.",
        "rom_sha256": sha256_bytes(rom), "emulator": emulator_config(), "start": start,
        "input": trace, "expect": expect, "ram_sha256": ram_digest(pyboy),
    }


# --- Captures (local; per-tick samples for comparison with the native runtime) ----

def capture(rom: bytes, start: dict[str, Any], trace: dict[str, Any]) -> dict[str, Any]:
    pyboy = start_from(rom, start)
    rows: list[list[int]] = []
    digests: list[str] = []

    def sample(_tick: int) -> None:
        rows.append([read_value(pyboy, address, size) for _, address, size in SAMPLES])
        digests.append(ram_digest(pyboy))

    play(pyboy, trace, sample)
    pyboy.stop(save=False)
    stream = hashlib.sha256("".join(digests).encode("ascii")).hexdigest()
    return {
        "format": "wl3pc.oracle-capture", "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "rom_sha256": sha256_bytes(rom), "emulator": emulator_config(), "start": start, "input": trace,
        "samples": [{"name": name, "address": f"{address:04x}", "size": size} for name, address, size in SAMPLES],
        "rows": rows, "ram_sha256": digests, "stream_sha256": stream,
    }


def compare_captures(first: dict[str, Any], second: dict[str, Any]) -> int | None:
    """First tick at which two captures differ (samples or memory), or None if identical."""
    for tick, (a, b) in enumerate(zip(first["ram_sha256"], second["ram_sha256"])):
        if a != b or first["rows"][tick] != second["rows"][tick]:
            return tick
    if len(first["ram_sha256"]) != len(second["ram_sha256"]):
        return min(len(first["ram_sha256"]), len(second["ram_sha256"]))
    return None


# --- Recording (interactive) and replay -------------------------------------------

KEYMAP = {"up": "SDL_SCANCODE_UP", "down": "SDL_SCANCODE_DOWN", "left": "SDL_SCANCODE_LEFT",
          "right": "SDL_SCANCODE_RIGHT", "a": "SDL_SCANCODE_X", "b": "SDL_SCANCODE_Z",
          "start": "SDL_SCANCODE_RETURN", "select": "SDL_SCANCODE_BACKSPACE"}


def record(rom: bytes, start: dict[str, Any], scale: int = 4, max_ticks: int | None = None) -> dict[str, Any]:
    """Play in a window; every tick's held buttons are recorded. Esc or closing the window ends it.

    P pauses; while paused, `.` advances exactly one tick with the keys held at that moment.
    """
    import ctypes

    import sdl2

    pyboy = start_from(rom, start)
    if sdl2.SDL_Init(sdl2.SDL_INIT_VIDEO) != 0:
        raise OracleError(f"SDL could not start: {sdl2.SDL_GetError().decode()}")
    window = sdl2.SDL_CreateWindow(b"WL3PC oracle recorder (Esc: save and quit, P: pause, .: step)",
                                   sdl2.SDL_WINDOWPOS_CENTERED, sdl2.SDL_WINDOWPOS_CENTERED,
                                   160 * scale, 144 * scale, sdl2.SDL_WINDOW_SHOWN)
    renderer = sdl2.SDL_CreateRenderer(window, -1, 0) or sdl2.SDL_CreateRenderer(window, -1, sdl2.SDL_RENDERER_SOFTWARE)
    texture = sdl2.SDL_CreateTexture(renderer, sdl2.SDL_PIXELFORMAT_RGBA32, sdl2.SDL_TEXTUREACCESS_STREAMING, 160, 144)
    if not (window and renderer and texture):
        raise OracleError(f"SDL window setup failed: {sdl2.SDL_GetError().decode()}")
    scancodes = {name: getattr(sdl2, code) for name, code in KEYMAP.items()}
    held_per_tick: list[frozenset[str]] = []
    checkpoints: list[dict[str, Any]] = []
    held: frozenset[str] | None = None
    paused, step, running = False, False, True
    event = sdl2.SDL_Event()
    next_frame = time.perf_counter()
    try:
        while running and (max_ticks is None or len(held_per_tick) < max_ticks):
            while sdl2.SDL_PollEvent(ctypes.byref(event)):
                if event.type == sdl2.SDL_QUIT:
                    running = False
                elif event.type == sdl2.SDL_KEYDOWN and not event.key.repeat:
                    key = event.key.keysym.scancode
                    if key == sdl2.SDL_SCANCODE_ESCAPE:
                        running = False
                    elif key == sdl2.SDL_SCANCODE_P:
                        paused = not paused
                    elif key == sdl2.SDL_SCANCODE_PERIOD and paused:
                        step = True
            if not running:
                break
            if paused and not step:
                time.sleep(0.01)
                continue
            step = False
            keys = sdl2.SDL_GetKeyboardState(None)
            now = frozenset(name for name, code in scancodes.items() if keys[code])
            apply_held(pyboy, held, now)
            held = now
            held_per_tick.append(now)
            pyboy.tick(1, True)
            if len(held_per_tick) % CHECKPOINT_EVERY == 0:
                checkpoints.append({"tick": len(held_per_tick) - 1, "ram_sha256": ram_digest(pyboy)})
            pixels = pyboy.screen.ndarray
            sdl2.SDL_UpdateTexture(texture, None, pixels.ctypes.data_as(ctypes.c_void_p), 160 * 4)
            sdl2.SDL_RenderClear(renderer)
            sdl2.SDL_RenderCopy(renderer, texture, None, None)
            sdl2.SDL_RenderPresent(renderer)
            next_frame += 1 / LCD_HZ
            delay = next_frame - time.perf_counter()
            if delay > 0 and not paused:
                time.sleep(delay)
            elif delay < -0.25 or paused:
                next_frame = time.perf_counter()
    finally:
        sdl2.SDL_DestroyTexture(texture)
        sdl2.SDL_DestroyRenderer(renderer)
        sdl2.SDL_DestroyWindow(window)
        sdl2.SDL_Quit()
    if not held_per_tick:
        raise OracleError("nothing was recorded")
    final = {"tick": len(held_per_tick) - 1, "ram_sha256": ram_digest(pyboy)}
    if not checkpoints or checkpoints[-1]["tick"] != final["tick"]:
        checkpoints.append(final)
    pyboy.stop(save=False)
    return {
        "format": "wl3pc.oracle-recording", "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "rom_sha256": sha256_bytes(rom), "emulator": emulator_config(), "start": start,
        "input": make_trace(held_per_tick, "Recorded in the WL3PC oracle recorder"),
        "checkpoints": checkpoints,
    }


def replay(rom: bytes, recording: dict[str, Any]) -> dict[str, Any]:
    """Re-run a recording headlessly; raise at the first checkpoint whose memory digest differs."""
    check_document(recording, "recording")
    check_rom(rom, recording["rom_sha256"])
    pyboy = start_from(rom, recording["start"])
    expected = {c["tick"]: c["ram_sha256"] for c in recording["checkpoints"]}
    seen = []

    def check(tick: int) -> None:
        if tick in expected:
            actual = ram_digest(pyboy)
            if actual != expected[tick]:
                raise OracleError(f"replay desynchronised by tick {tick} (checkpoint {len(seen)})")
            seen.append(tick)

    play(pyboy, recording["input"], check)
    pyboy.stop(save=False)
    return {"ticks": recording["input"]["ticks"], "checkpoints": len(seen)}


# --- Command line ---------------------------------------------------------------------

def parse_start(text: str, save: Path | None = None, boot_rom: Path | None = None) -> dict[str, Any]:
    """`power-on`, a route id, or `state:<sha256 or file>`; `save` and `boot_rom` are the user's own files."""
    if save is not None and text != "power-on":
        raise OracleError("a battery save applies only to a power-on start")
    boot_sha = import_file("boot-rom", boot_rom) if boot_rom is not None else None
    if text == "power-on":
        return power_on_start(boot_sha, import_file("save", save) if save is not None else None)
    if text.startswith("state:"):
        reference = text[len("state:"):]
        sha = reference if SHA256_RE.match(reference) else import_file("state", Path(reference))
        store_get("state", sha)
        origin = (store_metadata("state", sha) or {}).get("origin")
        boot = ({"source": "file", "sha256": boot_sha} if boot_sha
                else boot_rom_of(origin["start"]) if origin else power_on_start()["boot_rom"])
        return state_start(sha, boot, origin)
    if boot_rom is not None:
        raise OracleError("a boot ROM applies only to power-on and state starts")
    return route_start(text)


def _rom(path: Path | None) -> bytes:
    rom = read_rom(path or rom_path_from_env())
    if sha256_bytes(rom) != WL3_WORLD_EN_JA.sha256:
        raise OracleError("the oracle only runs the identified ROM")
    return rom


def _add_start_options(cmd: argparse.ArgumentParser, default: str) -> None:
    cmd.add_argument("--start", default=default, help="power-on, a route id, or state:<sha256 or file>")
    cmd.add_argument("--save", type=Path, default=None, help="your own raw 32 KiB battery save (power-on only)")
    cmd.add_argument("--bootrom", type=Path, default=None, help="your own boot ROM dump (power-on or state)")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="oracle", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("route-build", help="regenerate the tracked ootw-day1-start route by its policy")
    check = sub.add_parser("route-check", help="replay a tracked route and check its end state and digest")
    check.add_argument("route", nargs="?", default="ootw-day1-start")
    for name in ("capture", "verify"):
        cmd = sub.add_parser(name, help="capture per-tick samples" if name == "capture"
                             else "capture twice in separate emulators and require identical results")
        cmd.add_argument("--trace", type=Path, default=PROJECT_ROOT / "game/assets/traces/walk-right-300.json")
        _add_start_options(cmd, "ootw-day1-start")
        cmd.add_argument("--out", type=Path, default=None)
    rec = sub.add_parser("record", help="play in a window and record per-tick input (Esc saves)")
    rec.add_argument("name", help="file name under local/recordings/ (no extension)")
    _add_start_options(rec, "power-on")
    rec.add_argument("--scale", type=int, default=4)
    lvl = sub.add_parser("level-movie", help="store a level's start (wLevel set at InitLevel) and record a scripted"
                                             " movie from it under local/recordings/")
    lvl.add_argument("--level", required=True, help="wLevel: level * 8 + variant (day 1-4, night 1-4), e.g. 0x10")
    lvl.add_argument("--script", default="right", help="idle, right, right-jump, left, left-jump, right-attack, left-attack, right-crouch,"
                                                " wander, wander-sN (seed N), or search-sN (a seeded coverage search)")
    lvl.add_argument("--ticks", type=int, default=1200, help="the movie's length; other than 1200 it is named -tN")
    lvl.add_argument("--power-up", type=int, default=None,
                     help="set wPowerUpLevel (0-9) once the level has settled; the movie is named -puN")
    lvl.add_argument("--room", type=lambda text: int(text, 0), default=None,
                     help="start in this room-list entry (wLevelRoomID) at its spawn; the movie is named level-LLrRR")
    ahm = sub.add_parser("action-help-movie", help="branch a movie at Action Help's start with the power-up (and a"
                                                   " transformation) poked, and record its demo (WL3-051)")
    ahm.add_argument("--movie", type=Path, required=True, help="a recording that reaches Action Help")
    ahm.add_argument("--power-up-level", type=lambda text: int(text, 0), required=True,
                     help="wPowerUpLevel: the power-up (0-9) with $80 for after a level's clear")
    ahm.add_argument("--transformation", choices=("owl", "rail", "vampire"), default=None)
    ahm.add_argument("--script", choices=("idle", "browse"), default="idle")
    ahm.add_argument("--ticks", type=int, default=2400)
    rep = sub.add_parser("replay", help="replay a recording headlessly and check every checkpoint")
    rep.add_argument("recording", type=Path)
    for kind in ("boot-rom", "save", "state"):
        imp = sub.add_parser(f"import-{kind}", help=f"copy your own {kind.replace('-', ' ')} file into local/oracle/")
        imp.add_argument("path", type=Path)
    state_check = sub.add_parser("state-check", help="load a stored state and rebuild it from its recorded origin")
    state_check.add_argument("sha256")
    sub.add_parser("starts-check", help="check every start kind against straight replays")
    probes_cmd = sub.add_parser("probes", help="trace every collision probe of a movie or trace (hooks ProcessBlock)")
    probes_cmd.add_argument("movie", type=Path, help="a recording, or an input trace (run from the route)")
    probes_cmd.add_argument("--out", type=Path, default=None)
    wario_cmd = sub.add_parser("wario-trace", help="record Wario's variables every frame of a movie (WL3-012)")
    wario_cmd.add_argument("movie", type=Path, help="a recording, or an input trace (run from the route)")
    wario_cmd.add_argument("--out", type=Path, default=None)
    screen_cmd = sub.add_parser("screen-check", help="compare the background on screen with decoded room graphics")
    screen_cmd.add_argument("movie", type=Path, help="a recording, or an input trace (run from the route)")
    screen_cmd.add_argument("--ticks", required=True, help="comma-separated ticks to compare after")
    screen_cmd.add_argument("--rooms", type=Path, default=LOCAL_DIR / "content" / "wl3-original" / "rooms")
    screen_cmd.add_argument("--out", type=Path, default=None)
    sprite_cmd = sub.add_parser("sprite-check", help="check Wario's sprite on screen against his decoded graphics")
    sprite_cmd.add_argument("movie", type=Path, help="a recording, or an input trace (run from the route)")
    sprite_cmd.add_argument("--sprites", type=Path,
                            default=LOCAL_DIR / "content" / "wl3-original" / "wario_sprites.json")
    sprite_cmd.add_argument("--rooms", type=Path, default=LOCAL_DIR / "content" / "wl3-original" / "rooms")
    sprite_cmd.add_argument("--out", type=Path, default=None)
    window_cmd = sub.add_parser("window-check", help="compare the native window with the original's screen")
    window_cmd.add_argument("trace", type=Path, help="an input trace from level 0's start (the ootw-day1-start route)")
    window_cmd.add_argument("--ticks", required=True, help="comma-separated ticks to compare after")
    window_cmd.add_argument("--sprites", type=Path,
                            default=LOCAL_DIR / "content" / "wl3-original" / "wario_sprites.json")
    window_cmd.add_argument("--out", type=Path, default=None)
    review_cmd = sub.add_parser("review", help="timeline, contact sheets, and probe summary of a movie")
    review_cmd.add_argument("movie", type=Path)
    review_cmd.add_argument("--every", type=int, default=30, help="frames between contact-sheet thumbnails")
    review_cmd.add_argument("--out", type=Path, default=None)
    sub.add_parser("tas-check", help="check the TAS editor's seeking and editing against straight replays")
    tas_cmd = sub.add_parser("tas", help="open the TAS editor on local/recordings/NAME (created if missing)")
    tas_cmd.add_argument("name", help="file name under local/recordings/ (no extension)")
    _add_start_options(tas_cmd, "power-on")
    tas_cmd.add_argument("--scale", type=int, default=3)
    selftest_cmd = sub.add_parser("tas-selftest", help="drive the TAS editor window through its main actions")
    selftest_cmd.add_argument("--out", type=Path, required=True, help="where the test movie is saved")
    selftest_cmd.add_argument("--screenshot", type=Path, default=None, help="PNG of the editor window (ImageMagick)")
    args = parser.parse_args(argv)
    try:
        if args.command.startswith("import-"):
            kind = args.command[len("import-"):]
            digest = import_file(kind, args.path)
            usage = {"boot-rom": f"BOOTROM={args.path}", "save": f"SAVE={args.path}", "state": f"STATE={digest}"}[kind]
            print(f"stored {store_path(kind, digest)}\nuse it with, for example: make tas NAME=my-run {usage}")
            return 0
        rom = _rom(args.rom)
        if args.command == "route-build":
            route = build_ootw_day1_route(rom)
            path = ROUTES_DIR / f"{route['id']}.route.json"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(canonical_json(route))
            print(f"wrote {path.relative_to(PROJECT_ROOT)}: {route['input']['ticks']} ticks, "
                  f"{len(route['input']['events'])} events, end {route['expect']}")
        elif args.command == "route-check":
            route, _ = load_route(args.route)
            pyboy = start_from(rom, route_start(args.route))
            pyboy.stop(save=False)
            print(f"route {args.route}: OK ({route['input']['ticks']} ticks; end state and memory digest match)")
        elif args.command in ("capture", "verify"):
            trace = json.loads(args.trace.read_text(encoding="utf-8"))
            start = parse_start(args.start, args.save, args.bootrom)
            first = capture(rom, start, trace)
            if args.command == "verify":
                differs = compare_captures(first, capture(rom, start, trace))
                if differs is not None:
                    raise OracleError(f"two runs differ from tick {differs}")
                print(f"verify: OK (two separate emulators, {len(first['rows'])} ticks, identical samples and "
                      f"memory digests; stream {first['stream_sha256'][:16]}…)")
            out = args.out or CAPTURES_DIR / f"{start_label(start)}--{args.trace.stem}.capture.json"
            changed = write_immutable(out, canonical_json(first))
            last = dict(zip((s[0] for s in SAMPLES), first["rows"][-1]))
            print(f"wrote {out} ({'updated' if changed else 'unchanged'}); last tick: "
                  f"y={last['wWarioYPos']} x={last['wWarioXPos']} wWarioState={last['wWarioState']:#04x}")
        elif args.command == "level-movie":
            from .oracle_levels import script_trace, scripted_recording, store_level_start
            from .oracle_search import search_seed, search_trace
            level = int(args.level, 0)
            start = store_level_start(rom, level, args.power_up, args.room)
            seed = search_seed(args.script)
            trace = (script_trace(args.script, args.ticks) if seed is None
                     else search_trace(rom, start, args.ticks, seed))
            recording = scripted_recording(rom, start, trace)
            suffix = "" if args.power_up is None else f"-pu{args.power_up}"
            room = "" if args.room is None else f"r{args.room:02x}"
            suffix += "" if args.ticks == 1200 else f"-t{args.ticks}"
            out = LOCAL_DIR / "recordings" / f"level-{level:02x}{room}-{args.script}{suffix}.recording.json"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(recording, indent=1, sort_keys=True) + "\n", encoding="utf-8")
            print(f"level-movie: level {level:#04x} start stored as state {start['sha256'][:12]}…;"
                  f" {args.ticks} ticks of {args.script} written to {out}")
        elif args.command == "action-help-movie":
            from .oracle_action_help import TRANSFORMATIONS, browse_trace, store_action_help_start
            from .oracle_levels import scripted_recording
            movie = json.loads(args.movie.read_text(encoding="utf-8"))
            check_document(movie, "recording")
            transformation = None if args.transformation is None else TRANSFORMATIONS[args.transformation]
            start = store_action_help_start(rom, movie, args.power_up_level, transformation)
            trace = (browse_trace(args.ticks) if args.script == "browse"
                     else make_trace([frozenset()] * args.ticks, f"{args.ticks} idle ticks"))
            recording = scripted_recording(rom, start, trace)
            name = f"action-help-{args.power_up_level:02x}" + (f"-{args.transformation}" if args.transformation else "")
            out = LOCAL_DIR / "recordings" / "action-help" / f"{name}-{args.script}.recording.json"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(recording, indent=1, sort_keys=True) + "\n", encoding="utf-8")
            print(f"action-help-movie: {args.movie.name}'s Action Help start (wPowerUpLevel {args.power_up_level:#04x}"
                  f"{', ' + args.transformation if args.transformation else ''}) stored as state"
                  f" {start['sha256'][:12]}…; {args.ticks} ticks of {args.script} written to {out}")
        elif args.command == "record":
            result = record(rom, parse_start(args.start, args.save, args.bootrom), args.scale)
            out = RECORDINGS_DIR / f"{args.name}.recording.json"
            write_immutable(out, canonical_json(result))
            print(f"wrote {out}: {result['input']['ticks']} ticks, {len(result['checkpoints'])} checkpoints")
        elif args.command == "replay":
            summary = replay(rom, json.loads(args.recording.read_text(encoding="utf-8")))
            print(f"replay: OK ({summary['ticks']} ticks, {summary['checkpoints']} checkpoints matched)")
        elif args.command == "state-check":
            print(f"state-check: OK ({verify_state(rom, args.sha256)})")
        elif args.command in ("probes", "review"):
            from .oracle_review import check_block_map, describe_change, level_at, movie_parts, probe_trace, timeline
            start, trace = movie_parts(args.movie)
            name = args.movie.name.split(".")[0]
            if args.command == "probes":
                document = probe_trace(rom, start, trace)
                out = args.out or CAPTURES_DIR / f"{name}.probes.json"
                write_immutable(out, canonical_json(document))
                print(f"wrote {out}: {document['summary']['calls']} probes over {trace['ticks']} ticks; "
                      f"hooks left memory unchanged")
            else:
                out = args.out or LOCAL_DIR / "reviews" / name
                result = timeline(rom, start, trace, args.every, out / "sheets")
                probes = probe_trace(rom, start, trace)
                start_level = start_from(rom, start)
                level = start_level.memory[SAMPLE_ADDRESSES["wLevel"]]
                start_level.stop(save=False)
                # A movie that starts outside a level (on the map) reads the level where the probes begin.
                if probes["calls"]:
                    level = level_at(level, result["events"], probes["calls"][0][0])
                result["block_map_check"] = check_block_map(rom, probes, level)
                write_immutable(out / "timeline.json", canonical_json(result))
                write_immutable(out / "probes.json", canonical_json(probes))
                print(f"review of {args.movie.name}: {trace['ticks']} ticks from {describe_start(start)}; "
                      f"{len(result['events'])} events; coins {result['coins_start_end']}; "
                      f"{probes['summary']['calls']} collision probes; {len(result['sheets'])} contact sheet(s) in {out}")
                check = result["block_map_check"]
                kinds = check["kinds"]
                print(f"  live blocks vs decoded map {check['map']} (level {check['level']}): {check['cells_checked']} "
                      f"cells; {kinds.get('object_spawned', 0)} differ only in bit 7 (their object was on screen), "
                      f"{kinds.get('block_changed', 0)} changed otherwise (for example a broken block)")
                for event in result["events"][:60]:
                    changes = ", ".join(describe_change(k, a, b) for k, (a, b) in event["changed"].items())
                    print(f"  frame {event['tick']:6d} at x={event['wario'][0]} y={event['wario'][1]}: {changes}")
                if len(result["events"]) > 60:
                    print(f"  ... {len(result['events']) - 60} more events in {out / 'timeline.json'}")
        elif args.command == "wario-trace":
            from .oracle_review import movie_parts
            from .oracle_wario import wario_trace
            start, trace = movie_parts(args.movie)
            document = wario_trace(rom, start, trace)
            out = args.out or CAPTURES_DIR / f"{args.movie.name.split('.')[0]}.wario.json"
            write_immutable(out, canonical_json(document))
            print(f"wrote {out}: {len(document['variables'])} variables over {len(document['frames'])} frames")
        elif args.command == "screen-check":
            from .oracle_review import movie_parts
            from .oracle_screen import screen_check
            start, trace = movie_parts(args.movie)
            documents = {int(path.name[5:8]): json.loads(path.read_text())
                         for path in sorted(args.rooms.glob("room-*.gfx.json"))}
            if not documents:
                raise OracleError(f"no decoded room graphics in {args.rooms}; run `make extract`")
            animation_path = args.rooms / "animation.json"
            animation = json.loads(animation_path.read_text()) if animation_path.exists() else None
            result = screen_check(rom, start, trace, [int(t) for t in args.ticks.split(",")], documents, animation)
            out = args.out or LOCAL_DIR / "reviews" / args.movie.name.split(".")[0] / "screen-check.json"
            write_immutable(out, canonical_json(result))
            compared = sum(r.get("compared", 0) for r in result["frames"].values())
            matched = sum(r.get("matched", 0) for r in result["frames"].values())
            for tick, frame in result["frames"].items():
                print(f"  tick {tick}: room {frame.get('room')}, camera {frame.get('camera')}: "
                      f"{frame['matched']} of {frame['compared']} background pixels match"
                      + (f" (animated tiles {frame['animation'][0]}/{frame['animation'][1]}, palettes"
                         f" {frame['animation'][2]})" if frame.get("animation") else "")
                      + (f"; {frame['skipped']}" if "skipped" in frame else ""))
            print(f"screen-check: {matched} of {compared} background pixels match ({out})")
            if matched != compared:
                return 1
        elif args.command == "sprite-check":
            from .oracle_review import movie_parts
            from .oracle_screen import sprite_check
            start, trace = movie_parts(args.movie)
            if not args.sprites.exists():
                raise OracleError(f"no decoded Wario sprites at {args.sprites}; run `make extract`")
            documents = {int(path.name[5:8]): json.loads(path.read_text())
                         for path in sorted(args.rooms.glob("room-*.gfx.json"))}
            objects_path = args.sprites.parent / "objects.json"
            objects = json.loads(objects_path.read_text()) if objects_path.exists() else None
            result = sprite_check(rom, start, trace, json.loads(args.sprites.read_text()), documents, objects)
            out = args.out or LOCAL_DIR / "reviews" / args.movie.name.split(".")[0] / "sprite-check.json"
            write_immutable(out, canonical_json(result))
            oam, vram, screen = result["oam"], result["vram"], result["screen"]
            print(f"  OAM: {oam['matched']} of {oam['checked']} V-Blank transfers carry Wario's decoded frame"
                  f" ({oam['invisible']} with Wario not drawn; tables not decoded: {oam['not_decoded'] or 'none'})")
            print(f"  tiles: {vram['matched']} of {vram['checked']} transfers leave the named set in VRAM"
                  f" ({vram['not_decoded']} with a set not decoded)")
            print(f"  screen: {screen['matched']} of {screen['compared']} of Wario's pixels match over"
                  f" {screen['frames']} frames ({screen['behind_bg']} behind BG priority,"
                  f" {screen['hidden_by_other_sprites']} under other sprites left out,"
                  f" {screen['lines_with_a_palette_change']} lines at a palette change left out,"
                  f" {screen['lines_with_an_undecoded_palette']} lines with a palette not decoded;"
                  f" frames skipped: {screen['skipped'] or 'none'})")
            objects_report = result["objects"]
            print(f"  objects: {objects_report['matched']} of {objects_report['checked']} drawn objects' OAM entries equal"
                  f" their decoded frames (tables not decoded: {objects_report['not_decoded'] or 'none'});"
                  f" VRAM bank 1 equals the decoded enemy graphics for object groups"
                  f" {sorted(g for g, same in objects_report['vram_groups'].items() if same)}"
                  f" (differs for {sorted(g for g, same in objects_report['vram_groups'].items() if not same) or 'none'})")
            particles = result["particles"]
            print(f"  particles: {particles['matched']} of {particles['checked']} drawn particles' OAM entries equal"
                  f" their decoded frames (not decoded: {particles['not_decoded'] or 'none'})")
            ok = (oam["matched"] == oam["checked"] and vram["matched"] == vram["checked"]
                  and screen["matched"] == screen["compared"] and objects_report["matched"] == objects_report["checked"]
                  and all(objects_report["vram_groups"].values()) and particles["matched"] == particles["checked"])
            print(f"sprite-check: {'OK' if ok else 'DIFFERENCES'} ({out})")
            if not ok:
                return 1
        elif args.command == "window-check":
            import subprocess
            import tempfile
            from .godot import GAME, ORIGINAL_CONTENT, _godot
            from .oracle_review import movie_parts
            from .oracle_screen import route_lead_in, window_check
            start, trace = movie_parts(args.trace)
            if start != route_start("ootw-day1-start"):
                raise OracleError("window-check needs an input trace from level 0's start (the window starts there)")
            # The route ends some loops into the level: the window plays them first.
            lead_in, start_counter = route_lead_in(rom, load_route("ootw-day1-start")[0])
            if not args.sprites.exists():
                raise OracleError(f"no decoded Wario sprites at {args.sprites}; run `make extract`")
            shots: dict[int, bytes] = {}
            with tempfile.TemporaryDirectory() as scratch:
                for tick in [int(t) for t in args.ticks.split(",")]:
                    shot = Path(scratch) / f"window-{tick}.rgb"
                    # After n frames the window shows what the original's screen shows after tick n.
                    subprocess.run([str(_godot()), "--path", str(GAME), "--", f"--original-dir={ORIGINAL_CONTENT}",
                                    "--level=0", f"--trace={args.trace.resolve()}", f"--screenshot={shot}",
                                    f"--frames={tick}", f"--lead-in={lead_in}", f"--start-counter={start_counter}"],
                                   capture_output=True, text=True, timeout=300, check=False)
                    if not shot.exists() or shot.stat().st_size != 160 * 144 * 3:
                        raise OracleError(f"the window saved no 160x144 screenshot after tick {tick}")
                    shots[tick] = shot.read_bytes()
            result = window_check(rom, start, trace, shots, json.loads(args.sprites.read_text()))
            out = args.out or LOCAL_DIR / "reviews" / args.trace.name.split(".")[0] / "window-check.json"
            write_immutable(out, canonical_json(result))
            ok = True
            for tick, item in result["ticks"].items():
                if "skipped" in item:
                    print(f"  tick {tick}: SKIPPED ({item['skipped']})")
                    continue
                ok = ok and item["matched"] == item["compared"]
                print(f"  tick {tick}: {item['matched']} of {item['compared']} pixels equal, {item['object_pixels']} of them"
                      f" objects' and {item.get('particle_pixels', 0)} particles' (Wario"
                      f" {'drawn' if item['wario_drawn'] else 'not drawn'})")
            print(f"window-check: {'OK' if ok else 'DIFFERENCES'} ({out}; the window first ran the route's"
                  f" {lead_in} loops from wGlobalCounter {start_counter})")
            if not ok:
                return 1
        elif args.command == "starts-check":
            from .tas import check_starts
            print(f"starts-check: OK ({check_starts(rom)})")
        elif args.command == "tas-check":
            from .tas import check_with_emulator
            print(f"tas-check: OK ({check_with_emulator(rom)})")
        elif args.command == "tas-selftest":
            from .tas_gui import selftest
            print(f"tas-selftest: OK ({selftest(rom, args.out, args.screenshot)})")
        elif args.command == "tas":
            from .tas_gui import run_editor
            path = RECORDINGS_DIR / f"{args.name}.recording.json"
            start = None if path.exists() else parse_start(args.start, args.save, args.bootrom)
            run_editor(rom, path, start, args.scale)
    except OracleError as error:
        print(f"oracle: {error}", file=sys.stderr)
        return 3
    except FileNotFoundError as error:
        print(f"oracle: missing input: {error.filename}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
