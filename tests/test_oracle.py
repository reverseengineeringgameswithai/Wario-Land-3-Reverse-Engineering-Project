"""Emulator oracle logic that does not need PyBoy or the ROM (the module imports PyBoy lazily)."""

import importlib.util
import json

import jsonschema
import pytest
from referencing import Registry, Resource

from wl3pc import content, oracle
from wl3pc.known_roms import WL3_WORLD_EN_JA
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT
from wl3pc.symbols import load_sym

SCHEMAS = PROJECT_ROOT / "schemas"


def validator(name: str) -> jsonschema.Draft202012Validator:
    registry = Registry()
    for dependency in ("input-trace.v1.schema.json", "oracle-capture.v2.schema.json"):
        schema = json.loads((SCHEMAS / dependency).read_text())
        registry = registry.with_resource(schema["$id"], Resource.from_contents(schema))
    return jsonschema.Draft202012Validator(json.loads((SCHEMAS / name).read_text()), registry=registry)


class FakeEmulator:
    """Records the order of button changes and ticks."""

    def __init__(self):
        self.log: list[tuple] = []
        self.ticks = 0

    def button_press(self, button):
        self.log.append(("press", button, self.ticks))

    def button_release(self, button):
        self.log.append(("release", button, self.ticks))

    def tick(self, count, render):
        self.ticks += count


def trace(ticks, *events):
    return {"format": "wl3pc.input-trace", "format_version": 1, "ticks": ticks,
            "events": [{"tick": t, "held": list(h)} for t, h in events]}


def test_held_buttons_change_before_the_tick_they_are_listed_on():
    emulator, seen = FakeEmulator(), []
    final = oracle.play(emulator, trace(5, (0, ["right"]), (2, ["right", "a"]), (4, [])), seen.append)
    assert seen == [0, 1, 2, 3, 4] and final == frozenset()
    # The first tick sets every button (the start's own button state is unknown) ...
    first = [entry for entry in emulator.log if entry[2] == 0]
    assert sorted(first) == sorted([("press", "right", 0)] + [("release", b, 0) for b in oracle.BUTTONS if b != "right"])
    # ... and later ticks change only what changed.
    assert [entry for entry in emulator.log if entry[2] > 0] == [
        ("press", "a", 2), ("release", "right", 4), ("release", "a", 4)]


def test_a_trace_starting_later_still_sets_every_button_on_the_first_tick():
    emulator = FakeEmulator()
    oracle.play(emulator, trace(3, (2, ["b"])))
    assert sorted(emulator.log[:8]) == sorted(("release", b, 0) for b in oracle.BUTTONS)
    assert emulator.log[8:] == [("press", "b", 2)]


def test_make_trace_keeps_one_event_per_change():
    held = [frozenset()] * 2 + [frozenset({"a", "right"})] * 3 + [frozenset()]
    made = oracle.make_trace(held, "test")
    assert made["ticks"] == 6
    assert made["events"] == [{"tick": 0, "held": []}, {"tick": 2, "held": ["right", "a"]}, {"tick": 5, "held": []}]
    assert oracle.check_trace(made)[1] == (2, frozenset({"a", "right"}))


@pytest.mark.parametrize("bad, message", [
    (trace(5, (2, ["a"]), (2, ["b"])), "strictly increasing"),
    (trace(5, (5, ["a"])), "below ticks"),
    (trace(5, (0, ["turbo"])), "invalid held"),
    (trace(5, (0, ["a", "a"])), "invalid held"),
    ({"format": "wl3pc.input-trace", "format_version": 2, "ticks": 1, "events": []}, "version 1"),
])
def test_bad_traces_are_refused(bad, message):
    with pytest.raises(oracle.OracleError, match=message):
        oracle.check_trace(bad)


def test_compare_captures_reports_the_first_differing_tick():
    base = {"rows": [[1], [2], [3]], "ram_sha256": ["a", "b", "c"]}
    assert oracle.compare_captures(base, json.loads(json.dumps(base))) is None
    assert oracle.compare_captures(base, {"rows": [[1], [9], [3]], "ram_sha256": ["a", "b", "c"]}) == 1
    assert oracle.compare_captures(base, {"rows": [[1], [2], [3]], "ram_sha256": ["a", "b", "x"]}) == 2
    assert oracle.compare_captures(base, {"rows": [[1], [2]], "ram_sha256": ["a", "b"]}) == 2


def test_tracked_route_is_valid_and_reaches_the_first_room(tmp_path):
    route, _ = oracle.load_route("ootw-day1-start")
    validator("oracle-route.v2.schema.json").validate(route)
    assert route["rom_sha256"] == WL3_WORLD_EN_JA.sha256
    assert route["emulator"]["version"] == oracle.PYBOY_VERSION
    # ST_LEVEL, UpdateLevel, OUT_OF_THE_WOODS_DAY_1, ROOM_001, Wario idle on the decoded spawn point.
    assert {k: route["expect"][k] for k in ("wState", "wSubState", "wLevel", "wRoom", "wWarioState")} == \
        {"wState": 2, "wSubState": 3, "wLevel": 0, "wRoom": 1, "wWarioState": 0}
    assert (route["expect"]["wWarioXPos"], route["expect"]["wWarioYPos"]) == (56, 752)
    # The same input rules as the native runtime's traces.
    path = tmp_path / "route-input.json"
    path.write_text(json.dumps(route["input"]))
    content.load_trace(path)


def test_sample_addresses_match_the_reference_symbols():
    sym = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"
    if not sym.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {sym}; run `make refbuild`)")
    by_name = {}
    for line in sym.read_text().splitlines():
        parts = line.split()
        if len(parts) == 2 and ":" in parts[0] and not line.startswith(";"):
            by_name.setdefault(parts[1], int(parts[0].split(":")[1], 16))
    for name, address, _ in oracle.SAMPLES:
        assert by_name[name] == address, name


def test_missing_pyboy_is_a_clear_error():
    if importlib.util.find_spec("pyboy") is not None:
        pytest.skip("SKIPPED (PyBoy is importable here)")
    with pytest.raises(oracle.OracleError, match="PyBoy is not importable"):
        oracle.open_emulator(b"", {"source": "pyboy-bundled", "sha256": "0" * 64})


@pytest.fixture
def store(tmp_path, monkeypatch):
    monkeypatch.setattr(oracle, "STORE_DIR", tmp_path / "store")
    return tmp_path


@pytest.mark.parametrize("kind, size, message", [
    ("boot-rom", 0x900, None), ("boot-rom", 0x100, None), ("boot-rom", 0x200, "2304 bytes"),
    ("save", 0x8000, None), ("save", 0x8010, "32768-byte"), ("state", 0, "empty"),
])
def test_store_accepts_only_plausible_files(store, kind, size, message):
    source = store / "input.bin"
    source.write_bytes(bytes([7]) * size)
    if message:
        with pytest.raises(oracle.OracleError, match=message):
            oracle.import_file(kind, source)
        return
    digest = oracle.import_file(kind, source)
    stored = oracle.store_path(kind, digest)
    assert oracle.store_get(kind, digest) == source.read_bytes()
    assert not stored.stat().st_mode & 0o222
    assert oracle.store_metadata(kind, digest)["imported_from"] == "input.bin"


def test_store_detects_a_changed_file(store):
    digest = oracle.store_put("save", bytes(0x8000))
    path = oracle.store_path("save", digest)
    path.chmod(0o644)
    path.write_bytes(bytes([1]) * 0x8000)
    with pytest.raises(oracle.OracleError, match="no longer matches"):
        oracle.store_get("save", digest)
    with pytest.raises(oracle.OracleError, match="import it first"):
        oracle.store_get("save", "a" * 64)
    with pytest.raises(oracle.OracleError, match="not a SHA-256"):
        oracle.store_path("save", "../x")


def test_state_starts_from_files_and_their_descriptions(store):
    state_file = store / "elsewhere.state"
    state_file.write_bytes(b"pyboy state bytes")
    bundled = {"source": "pyboy-bundled", "sha256": "b" * 64}
    origin_start = {"kind": "power-on", "boot_rom": bundled, "cartridge_ram": {"source": "empty"}}
    digest = oracle.store_put("state", b"second", {"origin": {"start": origin_start, "frame": 9, "movie": "run",
                                                              "ram_sha256": "c" * 64, "input": None}})
    start = oracle.parse_start(f"state:{digest}")
    assert start["boot_rom"] == bundled and start["origin"]["frame"] == 9
    assert oracle.describe_start(start) == f"state {digest[:8]} from run at frame 9"
    assert oracle.describe_start(origin_start) == "power-on (PyBoy boot ROM, empty save)"
    with_save = dict(origin_start, cartridge_ram={"source": "file", "sha256": "d" * 64})
    assert oracle.describe_start(with_save) == f"power-on (PyBoy boot ROM, save {'d' * 8})"
    with pytest.raises(oracle.OracleError, match="only to a power-on start"):
        oracle.parse_start("ootw-day1-start", save=state_file)


def test_documents_must_be_the_current_format():
    with pytest.raises(oracle.OracleError, match="format 1 is not supported"):
        oracle.check_document({"format": "wl3pc.oracle-recording", "format_version": 1}, "recording")
    with pytest.raises(oracle.OracleError, match="not a wl3pc.oracle-capture"):
        oracle.check_document({"format": "wl3pc.oracle-recording", "format_version": 2}, "capture")


def test_a_branched_movie_with_a_nested_origin_matches_the_schema():
    route, digest = oracle.load_route("ootw-day1-start")
    route_start = {"kind": "route", "id": "ootw-day1-start", "sha256": digest}
    walk = oracle.make_trace([frozenset({"right"})] * 5, "parent")
    first = {"kind": "state", "sha256": "1" * 64, "boot_rom": route["start"]["boot_rom"],
             "origin": {"start": route_start, "frame": 5, "movie": "parent", "ram_sha256": "2" * 64, "input": walk}}
    second = {"kind": "state", "sha256": "3" * 64, "boot_rom": route["start"]["boot_rom"],
              "origin": {"start": first, "frame": 0, "movie": "child", "ram_sha256": "4" * 64, "input": None}}
    for start in (first, second, {"kind": "state", "sha256": "5" * 64, "boot_rom": route["start"]["boot_rom"],
                                  "origin": None}, route["start"]):
        recording = {"format": "wl3pc.oracle-recording", "format_version": 2, "marker": "m",
                     "rom_sha256": WL3_WORLD_EN_JA.sha256, "emulator": oracle.emulator_config(), "start": start,
                     "input": walk, "checkpoints": [{"tick": 4, "ram_sha256": "6" * 64}]}
        validator("oracle-recording.v2.schema.json").validate(recording)
    assert oracle.describe_start(second) == f"state {'3' * 8} from child at frame 0"


def test_probe_hooks_refuse_a_rom_without_the_expected_call_sites():
    from wl3pc import oracle_review

    rom = bytearray(8 * 0x4000)
    for site in oracle_review.CALL_SITES:
        start = 6 * 0x4000 + (site - 0x4000)
        rom[start:start + 4] = bytes([0xCD, 0x00, 0x40, 0x47])
    oracle_review.check_call_sites(bytes(rom))
    rom[6 * 0x4000 + oracle_review.CALL_SITES[3] - 0x4000 + 3] = 0x00
    with pytest.raises(oracle.OracleError, match="06:5ba6"):
        oracle_review.check_call_sites(bytes(rom))


def test_probe_addresses_match_the_reference_symbols():
    from wl3pc import oracle_review

    sym = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"
    if not sym.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {sym}; run `make refbuild`)")
    names = {}
    for line in sym.read_text().splitlines():
        parts = line.split()
        if len(parts) == 2 and ":" in parts[0] and not line.startswith(";"):
            names.setdefault(parts[1], parts[0])
    expected = {"ProcessBlock": "06:4000", "wCollisionPoints": "00:c0d6", "wBlockFuncBreakFlag": "00:c0d8",
                "wBlockFuncSpecialCollision": "00:c0d9", "wBlockFuncWarioFlag": "00:c0da",
                "wBlockPtrBank": "00:cce9", "wBlockPtr": "00:ccea", "wBlockFunctionTable": "00:cd00", "hPos": "00:ffa8"}
    assert {k: names[k] for k in expected} == expected
    assert (oracle_review.W_COLLISION_POINTS, oracle_review.W_BREAK, oracle_review.W_SPECIAL, oracle_review.W_WARIO,
            oracle_review.W_BLOCK_PTR_BANK, oracle_review.W_BLOCK_PTR, oracle_review.W_BLOCK_FUNCTION_TABLE,
            oracle_review.H_POS) == (0xC0D6, 0xC0D8, 0xC0D9, 0xC0DA, 0xCCE9, 0xCCEA, 0xCD00, 0xFFA8)


def test_block_map_comparison_sorts_object_flags_from_changed_blocks():
    from wl3pc import oracle_review

    rows = [bytes(160) for _ in range(40)]
    rows[0] = bytes([0x00, 0xF8, 0x60]) + bytes(157)   # an object block and a breakable block
    rows[33] = bytes([0x00, 0x00, 0x00, 0xAF]) + bytes(156)

    def probe(tick: int, bank: int, pointer: int, block: int) -> list[int]:
        call = [0] * len(oracle_review.PROBE_COLUMNS)
        call[0], call[7], call[8], call[9] = tick, bank, pointer, block
        return call

    probes = {"calls": [
        probe(1, 1, 0xA001, 0x78),   # object on screen: bit 7 cleared
        probe(2, 1, 0xA001, 0xF8),   # same cell again: only the first probe counts
        probe(3, 1, 0xA002, 0x78),   # broken block
        probe(4, 2, 0xA103, 0xAF),   # row 33 lives in SRAM bank 2, page 1; unchanged
        probe(5, 0, 0xC000, 0x01),   # not a map pointer
        probe(6, 1, 0xA000, -1),     # probe without a block
    ]}
    check = oracle_review.compare_blocks(rows, probes)
    assert check["cells_checked"] == 3
    assert [(m["row"], m["column"], m["kind"]) for m in check["mismatches"]] == [
        (0, 1, "object_spawned"), (0, 2, "block_changed")]
    assert check["kinds"] == {"object_spawned": 1, "block_changed": 1}


def test_review_reads_the_level_where_probes_begin():
    from wl3pc import oracle_review

    events = [{"tick": 99, "changed": {"wState": [1, 2]}},
              {"tick": 140, "changed": {"wLevel": [0, 7], "wRoom": [0, 1]}},
              {"tick": 900, "changed": {"wLevel": [7, 3]}}]
    assert oracle_review.level_at(0, events, 10) == 0
    assert oracle_review.level_at(0, events, 140) == 7
    assert oracle_review.level_at(0, events, 899) == 7
    assert oracle_review.level_at(0, [], 500) == 0


def test_bcd_counters_read_as_decimal():
    assert oracle.SAMPLE_SIZES["wNumCoins"] == oracle.SAMPLE_SIZES["wNumCollectedTreasures"] == 2
    assert oracle.from_bcd(0x0021) == 21
    assert oracle.from_bcd(0x0999) == 999
    assert oracle.from_bcd(0) == 0
    assert oracle.from_bcd(0x002A) is None
    assert oracle.sample_value("wNumCoins", 0x0021) == 21
    assert oracle.sample_value("wNumCoins", 0x00FF) == 0xFF  # not BCD (uninitialised RAM): shown raw
    assert oracle.sample_value("wWarioXPos", 0x0021) == 0x21


def test_state_names_match_the_disassembly():
    from wl3pc import oracle_review
    from wl3pc.paths import EXTERNAL_DIR

    constants = EXTERNAL_DIR / "ElectroDeoxys_warioland3" / "src" / "constants" / "state_constants.asm"
    if not constants.exists():
        pytest.skip(f"SKIPPED (no disassembly checkout at {constants}; run `make references`)")
    names = [line.split()[1] for line in constants.read_text().splitlines() if line.strip().startswith("const ST_")]
    assert tuple(names[:len(oracle_review.STATE_NAMES)]) == oracle_review.STATE_NAMES
    assert oracle_review.describe_change("wState", 2, 8) == "wState 2->8 (ST_LEVEL->ST_COLLECT_KEY)"
    assert oracle_review.describe_change("wLevel", 0, 7) == "wLevel 0->7"


class BankedMemory:
    """Flat memory plus SRAM banks addressed as memory[bank, start:end], like PyBoy's."""

    def __init__(self):
        self.flat = bytearray(0x10000)
        self.sram = {bank: bytearray(0x2000) for bank in range(4)}

    def __getitem__(self, key):
        if isinstance(key, tuple):
            bank, span = key
            if isinstance(span, int):
                if span >= 0xD000:  # banked WRAM (a traced wShootGoals): empty here
                    return 0
                return self.sram[bank][span - 0xA000]
            return list(self.sram[bank][span.start - 0xA000:span.stop - 0xA000])
        return self.flat[key]

    def __setitem__(self, key, value):
        self.flat[key] = value


class FakeMemory:
    """A machine whose WRAM changes on every tick: wWarioXPos counts ticks, high byte first.
    On the second tick it breaks the block in row 33 (SRAM bank 2, page 1), column 5."""

    def __init__(self):
        self.memory = BankedMemory()
        self.memory[0xCA83] = 4  # wWarioState: airborne
        self.memory.sram[1][0x0003] = 0x81  # row 0, column 3
        self.ticks = 0
        self.stopped = False

    def button_press(self, button):
        pass

    def button_release(self, button):
        pass

    def tick(self, count, render):
        x = (self.memory[0xCA63] << 8 | self.memory[0xCA64]) + 0x0101
        self.memory[0xCA63], self.memory[0xCA64] = x >> 8, x & 0xFF
        self.ticks += 1
        if self.ticks == 2:
            self.memory.sram[2][0x0105] = 0x78

    def stop(self, save):
        self.stopped = True


def test_wario_trace_records_the_state_before_and_after_every_tick():
    from wl3pc import oracle_wario

    machine = FakeMemory()
    start = oracle.parse_start("ootw-day1-start")
    document = oracle_wario.wario_trace(b"rom", start, trace(3, (0, ["right"])), open_emulator=lambda rom, s: machine)
    names = [v["name"] for v in document["variables"]]
    x, state = names.index("wWarioXPos"), names.index("wWarioState")
    assert [frame[x] for frame in document["frames"]] == [0, 0x0101, 0x0202, 0x0303]
    assert {frame[state] for frame in document["frames"]} == {4}
    assert all(len(frame) == len(names) for frame in document["frames"]) and machine.stopped
    assert len(document["block_rows"]) == 64 and document["block_rows"][0][6:8] == "81"
    assert len(document["block_gap_rows"]) == 64 and all(len(row) == 32 for row in document["block_gap_rows"])
    # frames[2] is after the second tick, when row 33, column 5 became $78 (seen at the frame's end).
    assert document["block_changes"] == [[2, 33, 5, 0x78, 4]]
    assert document["updates"] == document["camera_updates"] == []  # the fake machine has no hooks
    assert document["pal_writes"] == document["temple_vram"] == document["temple_screens"] == []
    validator("oracle-wario-trace.v1.schema.json").validate(document)


def test_wario_variables_match_the_reference_symbols():
    from wl3pc import oracle_wario

    sym = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"
    if not sym.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {sym}; run `make refbuild`)")
    by_name = {}
    for line in sym.read_text().splitlines():
        parts = line.split()
        if len(parts) == 2 and ":" in parts[0] and not line.startswith(";"):
            by_name.setdefault(parts[1], int(parts[0].split(":")[1], 16))
    by_name["hYPos"], by_name["hXPos"] = by_name["hYPosHi"], by_name["hXPosHi"]
    by_name["wTreasuresCollected7"] = by_name["wTreasuresCollected"] + 7
    for name, address, _ in oracle_wario.WARIO_VARIABLES:
        assert by_name[name] == address & 0xFFFF, name
    names = [name for name, _, _ in oracle_wario.WARIO_VARIABLES]
    assert len(names) == len(set(names))
    for layout in oracle_wario.SCREENS:
        for name, address, _ in layout.variables:
            assert by_name[name] == address, (layout.name, name)
    (golf, golf_building, clear, action_help, overworld, pause_menu, title, language_selection, credits, game_over,
     perfect) = oracle_wario.SCREENS
    # The golf RAM ranges: w1d800 to wGolfCourseScore, wGolfHoleData to wGolfParaGoomGhost's end.
    (_, first, first_size), (_, second, second_size) = golf.ram
    assert (first, first + first_size - 1) == (by_name["w1d800"], by_name["wGolfCourseScore"])
    assert (second, second + second_size) == (by_name["wGolfHoleData"], by_name["wGolfParaGoomGhost"] + 8)
    # The golf building's: the temporary palettes, the menu's bytes, and wGolfHoleRAMStart (the course's
    # tile map) to the golf objects' end.
    pals, menu, hole = golf_building.ram
    assert pals == (0, by_name["wTempPals1"], 0x80) and menu == golf.ram[0]
    assert (hole[1], hole[1] + hole[2]) == (by_name["wGolfHoleRAMStart"], by_name["wGolfParaGoomGhost"] + 8)
    assert by_name["wGolfCourseTileMap"] == by_name["wGolfHoleRAMStart"] < by_name["w1db00"] < by_name["wGolfHoleData"]
    # The clear screen's: the musical coin flags (4 bytes for 25 levels, then the golf scores), the
    # tile queue, the level time, w3d50d to wMenuObj11's end, the treasures to wOWLevel.
    flags, queue, time, timer, objects, treasures = clear.ram
    assert flags[1:] == (by_name["wMusicalCoinFlags"], by_name["wGolfBestScores"] - by_name["wMusicalCoinFlags"])
    assert (queue[1], time[1], timer[1], timer[1] + 1) == (by_name["wBGMapTileVRAM0Queue"], by_name["wLevelTime"],
                                                           by_name["wcee4"], by_name["wTimer"])
    assert (objects[1], objects[1] + objects[2]) == (by_name["w3d50d"], by_name["wMenuObj11"] + 8)
    assert (treasures[1], treasures[1] + treasures[2] - 1) == (by_name["wTreasuresCollected"], by_name["wOWLevel"])
    # Action Help's: both temporary palette sets, the pending DMA, wTimer's byte, w3d500 to
    # wMenuObj7AnimationEnded.
    pals, dma, timer, objects = action_help.ram
    assert (pals[1], pals[1] + pals[2]) == (by_name["wTempPals1"], by_name["wTempPals2"] + 0x40)
    assert (dma[1], dma[1] + dma[2] - 1) == (by_name["wIsDMATransferPending"], by_name["wPendingDMALength"])
    assert (timer[1], objects[1], objects[1] + objects[2] - 1) == (by_name["wTimer"], by_name["w3d500"],
                                                                   by_name["wMenuObj7AnimationEnded"])
    # What a save keeps: wSaveCounter to the end of wcaa1's four palettes.
    _, progress, size = oracle_wario.PROGRESS_WRAM
    assert (progress, progress + size) == (by_name["wSaveCounter"], by_name["wcaa1"] + 4 * 8)
    # The map's: all of WRAMX bank 2 from wTreasuresCollected; the pause menu's: wMenuObj11's end and
    # SRAM bank 0 whole.
    assert overworld.ram[2] == (2, by_name["wTreasuresCollected"], 0x1000)
    assert pause_menu.ram[-2][1] + pause_menu.ram[-2][2] == by_name["wMenuObj11"] + 8
    assert pause_menu.ram[-1] == (0, 0xA000, 0x2000)
    # The title's: the temporary palettes, the progress, wTransitionParam to wcef1, w3d500 to wMenuObj11's end.
    pals, progress_ram, timers, objects = title.ram
    assert (pals, progress_ram) == ((0, by_name["wTempPals1"], 0x80), oracle_wario.PROGRESS_WRAM)
    assert (timers[1], timers[1] + timers[2] - 1) == (by_name["wTransitionParam"], by_name["wcef1"])
    assert (timers[1] <= by_name["wceef"] < timers[1] + timers[2]) and by_name["wTimer"] == by_name["wcee4"] + 1
    assert (objects[1], objects[1] + objects[2]) == (by_name["w3d500"], by_name["wMenuObj11"] + 8)
    assert language_selection.ram == title.ram and "wIntroBGXOffsetFar" not in dict(
        (name, address) for name, address, _ in language_selection.variables)
    # The credits': the temporary palettes, the page, the BG map pointer, the text buffer to the palette
    # map pointer's end, wcee4 and wTimer, w3d500 to wMenuObj1's end.
    pals, page, bg_map, text, timer, objects = credits.ram
    assert (pals, page[1], bg_map[1:]) == ((0, by_name["wTempPals1"], 0x80), by_name["wCreditsPage"],
                                           (by_name["wCreditsBGMapPtr"], 2))
    assert (text[1], text[1] + text[2]) == (by_name["wCreditsTextBuffer"], by_name["wCreditsPalsMapPtr"] + 2)
    assert (timer[1], timer[1] + 1) == (by_name["wcee4"], by_name["wTimer"])
    assert (objects[1], objects[1] + objects[2]) == (by_name["w3d500"], by_name["wMenuObj1End"])
    # The game over and Perfect screens': the temporary palettes, wcee4 and wTimer, w3d500 to wMenuObj1's
    # end (wGameOverWario and wSFXTimer among them); the Perfect screen's progress and wUnused_c186 too.
    assert game_over.ram == (pals, timer, objects) and by_name["wGameOverWario"] < by_name["wSFXTimer"] < by_name["wMenuObj1"]
    assert perfect.ram == (pals, oracle_wario.PROGRESS_WRAM, (0, by_name["wUnused_c186"], 1), timer, objects)


def test_a_ram_range_is_read_by_its_memory_and_never_as_a_slice_to_a_regions_end():
    from wl3pc import oracle_wario

    class Memory:
        def __getitem__(self, key):
            if isinstance(key, tuple):
                bank, where = key
                if isinstance(where, slice):
                    assert where.start < where.stop and where.stop not in (0xC000, 0xE000), where
                    return [bank * 16 + (address & 0x0F) for address in range(where.start, where.stop)]
                return bank * 16 + (where & 0x0F)
            return list(range(key.start & 0xFF, key.stop & 0xFF))

    pyboy = type("PyBoy", (), {"memory": Memory()})()
    assert oracle_wario.read_range(pyboy, 0, 0xC010, 3) == bytes([0x10, 0x11, 0x12])
    assert oracle_wario.read_range(pyboy, 2, 0xDFFE, 2) == bytes([0x2E, 0x2F])
    assert oracle_wario.read_range(pyboy, 0, 0xA000, 0x2000)[-1] == 0x0F
    assert oracle_wario.read_range(pyboy, 3, 0xD500, 1) == bytes([0x30])
