"""The save's load at power-on, in the oracle (WL3-055).

`Init` (00:015e, src/home/start.asm) clears the RAM, runs `ValidateSaveData` (7c:4cad,
src/engine/pause/save/validate_save.asm), which checks the battery save's slots and loads the winner
into the RAM, then `InitGameState` (00:1690). This records the RAM and the cartridge RAM at both
points, so a port of the load can be compared byte for byte:

- `collect`: replay the owner's movies to their ends and keep the cartridge RAM each leaves (its save)
  in the oracle's store; a load the game makes during a movie (a reset after the level's save) is
  captured as it happens;
- `capture`: power on with each kept save, and with none, and capture the load;
- `continue_movie`: a movie from a save through the title's Continue to the map;
- `invent_time_attack`: an invented save, a stored one with Time Attack on (WL3-058);
- `invent_crayons`: an invented save, a stored one with all seven crayons (WL3-050);
- `invent_musical_coins`: an invented save, a stored one with every musical coin and 999 coins (WL3-050);
- `invent_treasures`: an invented save, a stored one with given treasures got (WL3-052).

Captures go to local/captures/save-load/NAME.json: for "before" (ValidateSaveData's first instruction)
and "after" (InitGameState's), WRAM0, WRAMX banks 1-7, SRAM banks 0-3, and HRAM, as hex.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from . import oracle
from .provenance import ROM_DERIVED_MARKER

FORMAT = "wl3pc.save-load-capture"
FORMAT_VERSION = 1
VALIDATE_SAVE_DATA = (0x7C, 0x4CAD)
INIT_GAME_STATE = (0x00, 0x1690)
CAPTURES = oracle.PROJECT_ROOT / "local" / "captures" / "save-load"
RECORDINGS = oracle.PROJECT_ROOT / "local" / "recordings"
MAX_POWER_ON_TICKS = 3000


def snapshot(pyboy: Any) -> dict[str, str]:
    """The RAM a load reads and writes, as hex: WRAM0, WRAMX banks 1-7, SRAM banks 0-3, HRAM."""
    memory = pyboy.memory
    record = {"wram0": bytes(memory[0xC000:0xD000]).hex(), "hram": bytes(memory[0xFF80:0xFFFF]).hex()}
    for bank in range(1, 8):
        record[f"wram{bank}"] = oracle._read_bank(memory, bank, 0xD000, 0xE000).hex()
    for bank in range(4):
        record[f"sram{bank}"] = oracle._read_bank(memory, bank, 0xA000, 0xC000).hex()
    return record


class LoadHooks:
    """Hooks at ValidateSaveData and InitGameState: each load the game makes, as {"before", "after"}."""

    def __init__(self, pyboy: Any) -> None:
        self.pyboy = pyboy
        self.loads: list[dict[str, Any]] = []
        self.pending: dict[str, Any] | None = None
        self.tick = 0
        pyboy.hook_register(*VALIDATE_SAVE_DATA, self._before, None)
        pyboy.hook_register(*INIT_GAME_STATE, self._after, None)

    def _before(self, _context: Any) -> None:
        self.pending = {"tick": self.tick, "before": snapshot(self.pyboy)}

    def _after(self, _context: Any) -> None:
        if self.pending is not None:
            self.pending["after"] = snapshot(self.pyboy)
            self.loads.append(self.pending)
            self.pending = None


def write_capture(name: str, load: dict[str, Any], origin: dict[str, Any]) -> Path:
    CAPTURES.mkdir(parents=True, exist_ok=True)
    path = CAPTURES / f"{name}.json"
    document = {"format": FORMAT, "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
                "rom_sha256": oracle.WL3_WORLD_EN_JA.sha256, "origin": origin, **load}
    path.write_text(json.dumps(document, sort_keys=True) + "\n")
    return path


def collect(rom: bytes, names: list[str]) -> list[str]:
    """Replay each movie to its end, checked against its recorded memory digests; keep the save it
    leaves; capture any load during it. Returns the saves' SHA-256s."""
    saves = []
    for name in names:
        recording = json.loads((RECORDINGS / f"{name}.recording.json").read_text())
        oracle.check_document(recording, "recording")
        oracle.check_rom(rom, recording["rom_sha256"])
        pyboy = oracle.start_from(rom, recording["start"])
        hooks = LoadHooks(pyboy)
        expected = {c["tick"]: c["ram_sha256"] for c in recording["checkpoints"]}

        def on_tick(tick: int) -> None:
            hooks.tick = tick + 1
            if tick in expected and oracle.ram_digest(pyboy) != expected[tick]:
                raise oracle.OracleError(f"{name}: the replay desynchronised by tick {tick}")

        oracle.play(pyboy, recording["input"], on_tick)
        for index, load in enumerate(hooks.loads):
            path = write_capture(f"{name}-load{index + 1}", load, {"movie": name, "tick": load["tick"]})
            print(f"  {name}: a load at tick {load['tick']} -> {path.name}", flush=True)
        digest = oracle.store_put("save", oracle.cartridge_ram_bytes(pyboy),
                                  {"from_movie": name, "ticks": recording["input"]["ticks"]})
        pyboy.stop(save=False)
        saves.append(digest)
        print(f"  {name}: its save {digest[:12]}", flush=True)
    return saves


def capture(rom: bytes, name: str, save_sha: str | None) -> Path:
    """Power on (with the save, or none) and capture the load."""
    start = oracle.power_on_start(save_sha=save_sha)
    pyboy = oracle.start_from(rom, start)
    hooks = LoadHooks(pyboy)
    for tick in range(MAX_POWER_ON_TICKS):
        hooks.tick = tick
        pyboy.tick(1, False)
        if hooks.loads:
            break
    pyboy.stop(save=False)
    if not hooks.loads:
        raise oracle.OracleError(f"{name}: no load within {MAX_POWER_ON_TICKS} ticks of power-on")
    return write_capture(name, hooks.loads[0], {"power_on": True, "save_sha256": save_sha})


# A Continue from the title: with a save the title goes straight to its start menu (sub-state 7,
# SST_START_MENU) 160 ticks after power-on, where A (HandleStartMenuSelection) takes Continue, the
# selection a save gives; Start does nothing there. The map then runs from transition 0.
CONTINUE_PRESS_TICK = 200
CONTINUE_TICKS = 800


def parse_presses(text: str) -> list[tuple[int, int, frozenset[str]]]:
    """PRESSES as [(first tick, last tick, buttons)]: comma-separated "TICK:BUTTONS" (one tick) or
    "FIRST-LAST:BUTTONS" (held through LAST), buttons joined by "+" (a, b, select, start, right, left,
    up, down)."""
    presses = []
    for item in filter(None, (part.strip() for part in text.split(","))):
        ticks, _, buttons = item.partition(":")
        first, held, last = ticks.partition("-")
        names = frozenset(buttons.split("+"))
        if not names <= {"a", "b", "select", "start", "right", "left", "up", "down"} or not first.isdigit() \
                or (held and not last.isdigit()):
            raise oracle.OracleError(f"cannot read the press {item!r} (TICK:BUTTONS or FIRST-LAST:BUTTONS)")
        presses.append((int(first), int(last or first), names))
    return presses


def continue_movie(rom: bytes, save_sha: str | None, name: str, presses: str = "", ticks: int = CONTINUE_TICKS,
                   route: str | None = None) -> Path:
    """A movie that powers on with the save (None: an empty cartridge RAM), presses A once at the
    title's start menu (Continue), and waits on the map, recorded with checkpoints as the recorder takes
    them; `presses` replaces the A with presses of its own (parse_presses), over `ticks` ticks. With
    `route` (a power-on route), the route's start and input come first and `presses` count on from
    the route's end."""
    from .oracle_levels import scripted_recording

    path = RECORDINGS / f"{name}.recording.json"
    if path.exists():
        raise oracle.OracleError(f"{path} exists; choose another NAME")
    start = oracle.power_on_start(save_sha=save_sha)
    held: list[frozenset[str]] = []
    if route:
        document, _ = oracle.load_route(route)
        if document["start"].get("kind") != "power-on":
            raise oracle.OracleError(f"route {route} does not start at power-on")
        start = document["start"]
        events = dict(oracle.check_trace(document["input"]))
        current: frozenset[str] = frozenset()
        for tick in range(document["input"]["ticks"]):
            current = events.get(tick, current)
            held.append(current)
    if presses or not route:
        script = parse_presses(presses) if presses else [(CONTINUE_PRESS_TICK, CONTINUE_PRESS_TICK, frozenset({"a"}))]
        held += [frozenset().union(*(names for first, last, names in script if first <= tick <= last))
                 for tick in range(max(ticks - len(held), 0))]
    what = f"presses {presses}" if presses else "A once at the title (Continue), then the map"
    if route:
        what = f"route {route}" + (f", then presses {presses}" if presses else "")
    with_save = f"save {save_sha[:12]}" if save_sha else "no save"
    trace = oracle.make_trace(held, f"Scripted: power-on with {with_save}, {what}")
    recording = scripted_recording(rom, start, trace)
    path.write_text(json.dumps(recording, indent=1) + "\n")
    return path


# The map's save and its backup (src/ram/sram.asm): "war3", then the progress WRAM ($5b bytes, from
# wSaveCounter) and the treasures ($11), whose plain sum is the checksum, stored high byte first with
# two echoes. wGameModeFlags is the progress's byte $3d; MODE_TIME_ATTACK its bit 1, which only a
# perfect game sets (src/engine/perfect/core.asm). wLanguage is its byte $46 (0 Japanese, 1 English).
# The treasures (wTreasuresCollected) follow at $5b, a bit a treasure from bit 0; the crayons are
# treasures $5e-$64 (CRAYON_RED_T to CRAYON_PINK_T), which GetCrayonFlags reads as wCrayonFlags.
MAP_SAVES = ((0xA380, (0xA791, 0xA7E1, 0xAFA1)), (0xAB80, (0xA793, 0xA7E3, 0xAFA3)))
GAME_MODE_FLAGS_OFFSET = 0x3D
MODE_GAME_CLEARED = 1 << 0
MODE_TIME_ATTACK = 1 << 1
MODE_FOUGHT_A_HIDDEN_FIGURE = 1 << 2
LANGUAGE_OFFSET = 0x46
TREASURES_OFFSET = 0x5B
CRAYON_TREASURES = range(0x5E, 0x65)
# wNumCoins (BCD, high byte first) is the progress's bytes 4 and 5; wMusicalCoinFlags its bytes $3e-$41,
# a bit a level from bit 0, of which CheckHasAllMusicalCoinFlags reads 25 (src/home/musical_coin.asm).
COINS_OFFSET = 0x04
MUSICAL_COIN_FLAGS_OFFSET = 0x3E
NUM_MUSICAL_COIN_LEVELS = 25
# wPowerUpLevel is the progress's byte $3c: each power-up treasure, collected, sets it to its own level
# (SetTreasureTransitionParam), from the Lead Overalls ($0c, 1) to the Super Grab Gloves ($09, 9), which
# a heavy object needs (the hidden figure's hands). wNumCollectedTreasures (BCD, hundreds first) is its
# bytes $39 and $3a, the count of treasures 1 to 100 (UpdateNumCollectedTreasures).
POWER_UP_LEVEL_OFFSET = 0x3C
POWER_UP_TREASURES = (0x0C, 0x07, 0x0E, 0x0B, 0x0A, 0x0D, 0x08, 0x06, 0x09)
NUM_COLLECTED_TREASURES_OFFSET = 0x39
NUM_TREASURES = 100


def with_progress_byte(save: bytes, offset: int, change: Any) -> bytes:
    """`save` (32 KiB) with the saved data's byte `offset` (the progress, then the treasures) set to
    change(byte) in each map save that has its check values, each checksum and its echoes moved by the
    same amount, so the load takes it as before."""
    data = bytearray(save)
    for check, sums in MAP_SAVES:
        if bytes(data[check - 0xA000:check - 0xA000 + 4]) != b"war3":
            continue
        at = check - 0xA000 + 4 + offset
        value = change(data[at]) & 0xFF
        delta = value - data[at]
        data[at] = value
        for address in sums:
            total = ((data[address - 0xA000] << 8) | data[address - 0xA000 + 1]) + delta
            data[address - 0xA000:address - 0xA000 + 2] = bytes([(total >> 8) & 0xFF, total & 0xFF])
    return bytes(data)


def with_mode_flags(save: bytes, flags: int) -> bytes:
    """`save` with `flags` set in each map save's wGameModeFlags (with_progress_byte)."""
    return with_progress_byte(save, GAME_MODE_FLAGS_OFFSET, lambda value: value | flags)


def invent_time_attack(save_sha: str, japanese: bool = False) -> str:
    """Store an invented save: the stored save `save_sha` with Time Attack on (with_mode_flags), and
    `japanese` its language Japanese, for the title's Time Attack paths no recorded save reaches.
    Returns its SHA-256."""
    source = oracle.store_get("save", save_sha)
    invented = with_mode_flags(source, MODE_TIME_ATTACK)
    change = "wGameModeFlags |= MODE_TIME_ATTACK"
    if japanese:
        invented = with_progress_byte(invented, LANGUAGE_OFFSET, lambda _value: 0)
        change += " and wLanguage = 0 (Japanese)"
    if invented == source:
        raise oracle.OracleError(f"save {save_sha[:12]} has no map save to change, or already has the change")
    return oracle.store_put("save", invented, {"invented": True, "from_save": save_sha,
                                               "change": change + " in each map save, its checksum and echoes "
                                                                  "moved by the same amount"})


def invent_game_cleared(save_sha: str) -> str:
    """Store an invented save: the stored save `save_sha` with the game cleared as the hidden figure's
    defeat leaves it (MODE_GAME_CLEARED and MODE_FOUGHT_A_HIDDEN_FIGURE, Time Attack left as it is), for
    what the map does after a cleared game: with all 100 treasures its save enters the Perfect screen
    (SaveGameOrEnterPerfectScreen). Returns its SHA-256."""
    source = oracle.store_get("save", save_sha)
    invented = with_mode_flags(source, MODE_GAME_CLEARED | MODE_FOUGHT_A_HIDDEN_FIGURE)
    if invented == source:
        raise oracle.OracleError(f"save {save_sha[:12]} has no map save to change, or the game is already cleared")
    return oracle.store_put("save", invented, {"invented": True, "from_save": save_sha,
                                               "change": "wGameModeFlags |= MODE_GAME_CLEARED | "
                                                         "MODE_FOUGHT_A_HIDDEN_FIGURE in each map save, its "
                                                         "checksum and echoes moved by the same amount"})


def with_treasures(save: bytes, treasures: Any) -> bytes:
    """`save` with each of `treasures` got (wTreasuresCollected's bit) in each map save (with_progress_byte)."""
    for treasure in treasures:
        save = with_progress_byte(save, TREASURES_OFFSET + treasure // 8,
                                  lambda value, bit=treasure % 8: value | (1 << bit))
    return save


def invent_treasures(save_sha: str, treasures: list[int]) -> str:
    """Store an invented save: the stored save `save_sha` with `treasures` got, for map paths no recorded
    save opens (the Day/Night Spell's button, WL3-052). Returns its SHA-256."""
    source = oracle.store_get("save", save_sha)
    invented = with_treasures(source, treasures)
    if invented == source:
        raise oracle.OracleError(f"save {save_sha[:12]} has no map save to change, or already has those treasures")
    listed = ", ".join(f"${treasure:02x}" for treasure in treasures)
    return oracle.store_put("save", invented, {"invented": True, "from_save": save_sha,
                                               "change": f"the treasures {listed} collected in each map save, its "
                                                         "checksum and echoes moved by the same amount"})


def invent_crayons(save_sha: str) -> str:
    """Store an invented save: the stored save `save_sha` with all seven crayons collected, for the golf
    building's course, which only ALL_CRAYONS opens and no recorded save has (WL3-050). Returns its
    SHA-256."""
    source = oracle.store_get("save", save_sha)
    invented = with_treasures(source, CRAYON_TREASURES)
    if invented == source:
        raise oracle.OracleError(f"save {save_sha[:12]} has no map save to change, or already has every crayon")
    return oracle.store_put("save", invented, {"invented": True, "from_save": save_sha,
                                               "change": "the crayon treasures $5e-$64 collected in each map "
                                                         "save, its checksum and echoes moved by the same amount"})


def with_treasure_count(save: bytes) -> bytes:
    """`save` with each map save's wNumCollectedTreasures counted again from its treasures (1 to 100)."""
    for check, _sums in MAP_SAVES:
        if bytes(save[check - 0xA000:check - 0xA000 + 4]) != b"war3":
            continue
        start = check - 0xA000 + 4 + TREASURES_OFFSET
        count = sum(1 for treasure in range(1, NUM_TREASURES + 1)
                    if save[start + treasure // 8] & (1 << (treasure % 8)))
        bcd = [count // 100, ((count % 100) // 10) << 4 | count % 10]
        for i, value in enumerate(bcd):
            save = with_progress_byte(save, NUM_COLLECTED_TREASURES_OFFSET + i, lambda _value, v=value: v)
        break  # with_progress_byte writes both map saves; the backup's treasures are the same
    return save


def invent_power_ups(save_sha: str) -> str:
    """Store an invented save: the stored save `save_sha` with every power-up treasure collected, its power-up
    level the last's (the Super Grab Gloves, 9), and the treasure count to match, for the hidden figure's
    fight, whose hands only the Super Grab Gloves pick up (WL3-048). Returns its SHA-256."""
    source = oracle.store_get("save", save_sha)
    invented = with_treasures(source, POWER_UP_TREASURES)
    invented = with_progress_byte(invented, POWER_UP_LEVEL_OFFSET, lambda _value: POWER_UP_TREASURES.index(0x09) + 1)
    invented = with_treasure_count(invented)
    if invented == source:
        raise oracle.OracleError(f"save {save_sha[:12]} has no map save to change, or already has every power-up")
    return oracle.store_put("save", invented, {"invented": True, "from_save": save_sha,
                                               "change": "every power-up treasure collected, wPowerUpLevel 9, and "
                                                         "wNumCollectedTreasures counted again in each map save, "
                                                         "its checksum and echoes moved by the same amount"})


def invent_musical_coins(save_sha: str) -> str:
    """Store an invented save: the stored save `save_sha` with every level's musical coins (the 25 flags
    CheckHasAllMusicalCoinFlags reads), which open the golf building's fourth course, and 999 coins to pay
    for several courses (WL3-050). Returns its SHA-256."""
    source = oracle.store_get("save", save_sha)
    invented = source
    for level in range(NUM_MUSICAL_COIN_LEVELS):
        invented = with_progress_byte(invented, MUSICAL_COIN_FLAGS_OFFSET + level // 8,
                                      lambda value, bit=level % 8: value | (1 << bit))
    invented = with_progress_byte(invented, COINS_OFFSET, lambda _value: 0x09)
    invented = with_progress_byte(invented, COINS_OFFSET + 1, lambda _value: 0x99)
    if invented == source:
        raise oracle.OracleError(f"save {save_sha[:12]} has no map save to change, or already has the change")
    return oracle.store_put("save", invented, {"invented": True, "from_save": save_sha,
                                               "change": "the 25 musical coin flags set and wNumCoins 999 in each map "
                                                         "save, its checksum and echoes moved by the same amount"})


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("movies", nargs="*", help="owner's movies (names in local/recordings); default: all")
    parser.add_argument("--continue-movie", metavar="NAME",
                        help="instead, record NAME: power-on with --save, Continue at the title, then the map")
    parser.add_argument("--save", help="--continue-movie: the save's SHA-256 in the oracle's store, or none")
    parser.add_argument("--presses", default="", help="--continue-movie: TICK:BUTTONS or FIRST-LAST:BUTTONS, "
                                                       "comma-separated, instead of A at the title")
    parser.add_argument("--ticks", type=int, default=CONTINUE_TICKS, help="--continue-movie: its length")
    parser.add_argument("--route", help="--continue-movie: a power-on route whose start and input come first")
    parser.add_argument("--invent-time-attack", metavar="SAVE",
                        help="instead, store an invented save: SAVE (a stored save's SHA-256) with Time Attack on")
    parser.add_argument("--japanese", action="store_true", help="--invent-time-attack: in Japanese too")
    parser.add_argument("--invent-crayons", metavar="SAVE",
                        help="instead, store an invented save: SAVE (a stored save's SHA-256) with all seven crayons")
    parser.add_argument("--invent-musical-coins", metavar="SAVE",
                        help="instead, store an invented save: SAVE with every musical coin and 999 coins")
    parser.add_argument("--invent-treasures", metavar="SAVE",
                        help="instead, store an invented save: SAVE with --treasures got")
    parser.add_argument("--treasures", default="", help="--invent-treasures: treasure numbers in hex, comma-separated")
    parser.add_argument("--invent-game-cleared", metavar="SAVE",
                        help="instead, store an invented save: SAVE with the game cleared (MODE_GAME_CLEARED)")
    parser.add_argument("--invent-power-ups", metavar="SAVE",
                        help="instead, store an invented save: SAVE with every power-up (wPowerUpLevel 9)")
    args = parser.parse_args(argv)
    try:
        if args.invent_time_attack:
            digest = invent_time_attack(args.invent_time_attack, args.japanese)
            print(f"invented save {digest} (Time Attack on{', Japanese' if args.japanese else ''})")
            return 0
        if args.invent_crayons:
            print(f"invented save {invent_crayons(args.invent_crayons)} (all seven crayons)")
            return 0
        if args.invent_treasures:
            treasures = [int(text, 16) for text in args.treasures.split(",") if text.strip()]
            if not treasures:
                parser.error("--invent-treasures needs --treasures")
            print(f"invented save {invent_treasures(args.invent_treasures, treasures)} (treasures {args.treasures})")
            return 0
        if args.invent_game_cleared:
            print(f"invented save {invent_game_cleared(args.invent_game_cleared)} (the game cleared)")
            return 0
        if args.invent_power_ups:
            print(f"invented save {invent_power_ups(args.invent_power_ups)} (every power-up)")
            return 0
        if args.invent_musical_coins:
            print(f"invented save {invent_musical_coins(args.invent_musical_coins)} (every musical coin, 999 coins)")
            return 0
        rom = oracle._rom(None)
        if args.continue_movie:
            if not args.save and not args.route:
                parser.error("--continue-movie needs --save or --route")
            save = None if args.save == "none" else args.save
            print(f"wrote {continue_movie(rom, save, args.continue_movie, args.presses, args.ticks, args.route)}")
            return 0
        names = args.movies or sorted(path.name.removesuffix(".recording.json") for path in RECORDINGS.glob("*.recording.json")
                                      if path.name.startswith(("game-", "ootw-gray-key")))
        saves = collect(rom, names)
        print(f"  no save: {capture(rom, 'power-on-no-save', None).name}", flush=True)
        for name, digest in zip(names, saves):
            print(f"  {name}'s save: {capture(rom, f'power-on-{name}', digest).name}", flush=True)
    except oracle.OracleError as error:
        print(f"oracle_save: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
