"""Optional checks against the user's identified ROM. Run with `make test-rom`.

These never write to the ROM; they confirm its hash is unchanged afterwards.
"""

import hashlib
import json
import os
import subprocess
from pathlib import Path

import pytest

import test_oracle

from wl3pc import content
from wl3pc.address import BankedAddress
from wl3pc.extract import block_functions as bf
from wl3pc.extract import block_materials as bm
from wl3pc.extract import level_headers as lh
from wl3pc.extract import level_maps as lm
from wl3pc.extract import room_pack as rp
from wl3pc.extract import rooms
from wl3pc.known_roms import WL3_WORLD_EN_JA
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT, rom_path_from_env
from wl3pc.rom import inspect_file
from wl3pc.symbols import load_sym, parse_sym

pytestmark = pytest.mark.rom
ROM = rom_path_from_env()
SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"


@pytest.fixture(scope="module")
def rom_bytes():
    if not ROM.exists():
        pytest.skip(f"SKIPPED (no ROM at {ROM}; set WL3PC_ROM)")
    data = ROM.read_bytes()
    yield data
    assert hashlib.sha256(ROM.read_bytes()).hexdigest() == hashlib.sha256(data).hexdigest(), "ROM changed"


def test_rom_is_the_identified_revision(rom_bytes):
    report = inspect_file(ROM)
    assert report.identity.status == "verified"
    assert report.hashes.sha256 == WL3_WORLD_EN_JA.sha256
    assert report.header.header_checksum_valid and report.header.global_checksum_valid
    assert report.header.logo_matches_boot_logo
    assert report.header.cartridge_type_name == "MBC5+RAM+BATTERY"


def test_block_function_tables_decode(rom_bytes):
    document = bf.decode(rom_bytes)
    decoded = [t for t in document["tables"] if t["status"] == "decoded"]
    sentinels = [t["index"] for t in document["tables"] if t["status"] == "reset-sentinel"]
    assert len(decoded) == 89
    assert sentinels == list(range(0x59, 0x62))
    assert decoded[0]["location"] == "32:40c4"
    assert decoded[0x3E]["location"] == "32:7ec4"
    assert decoded[0x3F]["location"] == "50:4000"
    assert len(document["handlers"]) == 138
    assert all(BankedAddress.parse(h["location"]).bank == 6 for h in document["handlers"])


def test_every_handler_lands_on_a_reference_symbol(rom_bytes):
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    symbols = load_sym(SYM)
    document = bf.annotate(bf.decode(rom_bytes), symbols, None, 6)
    assert document["audit"]["handlers_without_symbol"] == []
    names = {h["location"]: h["symbol"] for h in document["handlers"]}
    assert names["06:4020"] == "BlockFunc_Free"
    assert names["06:4032"] == "BlockFunc_Solid"
    assert json.dumps(document)  # serialisable


def test_room_records_decode(rom_bytes):
    document = rooms.decode(rom_bytes)
    decoded = [r for r in document["rooms"] if r["status"] == "decoded"]
    sentinels = [r["room"] for r in document["rooms"] if r["status"] == "reset-sentinel"]
    assert len(document["rooms"]) == 0x9B  # NUM_ROOMS
    assert sentinels == [0]  # ROOM_000 is `dw NULL`
    assert len(decoded) == 0x9B - 1
    # Records are contiguous 5-byte `room` macros starting at .room_data_001.
    assert [r["record"] for r in decoded] == [str(BankedAddress(0x30, 0x460B + 5 * i)) for i in range(len(decoded))]
    tables = {r["fields"]["block_function_table"] for r in decoded}
    assert max(tables) < 0x59 and len(tables) == 89  # every decoded table is used; no reset sentinel
    assert document["audit"]["tile_map_differs_from_block_function_table"] == []
    assert {r["sources"]["block_attributes"]["bytes"] for r in decoded} == {0x200}  # wRoomBlockAttributes


def test_room_records_land_on_reference_symbols(rom_bytes):
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    text = SYM.read_text(encoding="utf-8", errors="replace")
    global_labels, all_labels = parse_sym(text), parse_sym(text, include_local=True)
    document = rooms.annotate(rooms.decode(rom_bytes), global_labels)
    decoded = [r for r in document["rooms"] if r["status"] == "decoded"]
    record_labels = [name for name in all_labels.values() if name.startswith("RoomBlockAndGfxData.room_data_")]
    assert len(record_labels) == len(decoded)
    for room in decoded:
        fields, sources = room["fields"], room["sources"]
        assert all_labels[BankedAddress.parse(room["record"])] == f"RoomBlockAndGfxData.room_data_{room['room']:03d}"
        assert sources["block_tiles"]["symbol"] == f"BlocksetTiles{fields['block_function_table']:02d}"
        assert sources["block_attributes"]["symbol"] == f"BlocksetAttributes{fields['tile_map']:02d}"
        assert sources["main_tiles"]["symbol"] == f"LevelMainTiles{fields['main_tiles']}"
        assert sources["special_tiles"]["symbol"] == f"SpecialTiles{fields['special_tiles']}"
        assert sources["palettes"]["symbol"].startswith("Pals_")
    assert document["audit"]["sources_without_symbol"] == []
    # Each compressed stream ends exactly where the next label in its bank starts,
    # except the last stream in each of the 15 blockset banks ($38-$46).
    streams = {room["sources"]["block_attributes"]["location"]: room["sources"]["block_attributes"]["compressed_bytes"]
               for room in decoded}
    last_in_bank = 0
    for location, length in streams.items():
        start = BankedAddress.parse(location)
        later = sorted(a for a in global_labels if a.bank == start.bank and a.address > start.address)
        if later:
            assert later[0].address == start.address + length, location
        else:
            last_in_bank += 1
    assert (len(streams), last_in_bank) == (89, 15)


def test_level_headers_decode(rom_bytes):
    document = lh.decode(rom_bytes)
    levels = document["levels"]
    assert len(levels) == 0xC9 and all(lv["status"] == "decoded" for lv in levels)  # $00 through THE_TEMPLE
    assert (len(document["lists"]), len(document["headers"])) == (119, 2010)
    assert document["audit"] == {"levels_starting_on_reset_entry": [], "decoded_rooms_not_referenced": [63, 64, 65]}
    # Out of the Woods, day 1 ($00) starts in ROOM_001.
    assert (levels[0]["list"], levels[0]["start_header"], levels[0]["start_room"]) == ("30:4d1f", "30:4d5b", 1)
    # Each list is followed directly by its headers, consistent with 30 two-byte entries.
    for lst in document["lists"]:
        start = BankedAddress.parse(lst["location"])
        first = min(BankedAddress.parse(e) for e in lst["entries"] if e)
        assert first == BankedAddress(start.bank, start.address + 60), lst["location"]
    # Every spawn lies inside its own header's limits.
    for header in document["headers"]:
        f = header["fields"]
        assert f["upper_y_limit"] <= f["spawn_y"] < f["lower_y_limit"], header["location"]
        assert f["left_x_limit"] <= f["spawn_x"] < f["right_x_limit"], header["location"]


def test_level_headers_land_on_reference_symbols(rom_bytes):
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    document = lh.annotate(lh.decode(rom_bytes), load_sym(SYM, include_local=True))
    assert document["audit"]["lists_without_symbol"] == document["audit"]["headers_without_symbol"] == []
    header_symbols = {h["location"]: h["symbol"] for h in document["headers"]}
    for lst in document["lists"]:
        # List labels are named after their file offset, which checks the bank-group rule.
        assert lst["symbol"] == f"LevelHeaders_{BankedAddress.parse(lst['location']).file_offset:x}"
        first_use = {}
        for index, entry in enumerate(lst["entries"]):
            if entry:
                first_use.setdefault(entry, index)
        for entry, index in first_use.items():
            assert header_symbols[entry] == f"{lst['symbol']}.room_{index:02d}", entry


def test_block_materials_cover_the_first_room_table(rom_bytes):
    document = bm.apply(bf.decode(rom_bytes), bm.load_mapping())
    audit = document["audit"]
    assert audit["mapped_handlers_not_found"] == []
    # ROOM_001 (Out of the Woods, day 1, first room) uses table $00.
    assert 0 in audit["tables_fully_mapped"]
    assert all(b["material"] != bm.UNKNOWN for b in document["tables"][0]["blocks"])
    assert len(audit["unmapped_handlers_used"]) == 138 - len(bm.load_mapping()["handlers"])


def test_block_material_rows_name_the_reference_symbols(rom_bytes):
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    symbols = load_sym(SYM)
    for row in bm.load_mapping()["handlers"]:
        bank, address = row["id"][1:].split("_")
        assert symbols.get(BankedAddress(int(bank, 16), int(address, 16))) == row["symbol"], row["id"]


def test_level_block_maps_decode(rom_bytes):
    document = lm.decode(rom_bytes)
    assert all(lv["status"] == "decoded" for lv in document["levels"]) and len(document["levels"]) == 0xC9
    maps = {m["location"]: m for m in document["maps"]}
    assert len(maps) == 35 and document["audit"]["row_counts"] == [48]
    assert maps["38:4000"]["used_by_levels"] == list(range(8))  # Out of the Woods, all eight versions
    assert maps["38:4000"]["bytes"] == 48 * 160
    # One map stops one block short of its last row; the original leaves that SRAM byte as it was.
    assert document["audit"]["maps_with_incomplete_final_row"] == ["3d:5533"]
    assert maps["3d:5533"]["bytes"] == 48 * 160 - 1


def test_first_room_blocks_are_all_mapped(rom_bytes):
    # ROOM_001's region assumes the header limits are section ranges (see docs/02-research/level-headers.md).
    header = next(h for h in lh.decode(rom_bytes)["headers"] if h["location"] == "30:4d5b")["fields"]
    rows = [bytes.fromhex(r) for r in next(m for m in lm.decode(rom_bytes)["maps"]
                                          if m["location"] == "38:4000")["block_rows"]]
    region = [lm.block_id(rows[y][x])
              for y in range(16 * header["upper_y_limit"], 16 * header["lower_y_limit"])
              for x in range(16 * header["left_x_limit"], 16 * header["right_x_limit"])]
    assert len(region) == 16 * 32
    table = bm.apply(bf.decode(rom_bytes), bm.load_mapping())["tables"][0]["blocks"]
    assert {table[i]["material"] for i in region} == {"empty", "solid", "platform"}


def test_level_block_maps_land_on_reference_symbols(rom_bytes):
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    symbols = load_sym(SYM)
    document = lm.annotate(lm.decode(rom_bytes), symbols)
    assert document["audit"]["maps_without_symbol"] == []
    labels = sorted(symbols)
    for item in document["maps"]:
        assert item["symbol"].endswith("BlockMap") and item["object_map_symbol"].endswith("ObjectMap"), item
        # Each compressed stream ends exactly where the next label starts.
        start = BankedAddress.parse(item["location"])
        following = next(a for a in labels if a > start)
        assert following == BankedAddress(start.bank, start.address + item["compressed_bytes"]), item["location"]


def test_object_maps_decode_and_place_the_first_spawn(rom_bytes):
    document = lm.decode(rom_bytes)
    assert all(m["object_bytes"] == 48 * 80 for m in document["maps"])
    assert document["audit"]["object_maps_with_incomplete_final_row"] == []
    ootw = next(m for m in document["maps"] if m["location"] == "38:4000")
    # Out of the Woods, day 1 starts with spawn section (0, 2); the marker is block (3, 46).
    assert lm.find_spawn([bytes.fromhex(r) for r in ootw["object_rows"]], 0, 2) == (3, 46)


def test_object_map_streams_end_at_a_label_or_bank_padding(rom_bytes):
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    labels = sorted(load_sym(SYM))
    padded = 0
    for item in lm.decode(rom_bytes)["maps"]:
        start = BankedAddress.parse(item["object_map"])
        end = start.address + item["object_compressed_bytes"]
        following = next(a for a in labels if a > start)
        if following.bank == start.bank:
            assert following.address == end, item["object_map"]
        else:  # last stream in its bank: only $ff padding follows
            tail = rom_bytes[BankedAddress(start.bank, end).file_offset:BankedAddress(start.bank, 0x7FFF).file_offset + 1]
            assert set(tail) == {0xFF}, item["object_map"]
            padded += 1
    assert padded == 3


def test_first_room_pack_builds_loads_and_labels_every_difference(rom_bytes, tmp_path):
    result = rp.extract(ROM, tmp_path)
    loaded = content.load_pack(Path(result["path"]))
    room = loaded["rooms"]["room-001"]
    assert (len(room["rows"]), len(room["rows"][0])) == (16, 32)
    assert loaded["pack"]["start"] == {"room": "room-001", "x_px": 50, "y_px": 216}
    # The spawn block (3, 46) is room cell (3, 14): empty, standing on a solid cell.
    assert room["legend"][room["rows"][14][3]] == "empty" and room["legend"][room["rows"][15][3]] == "solid"
    approximations = loaded["pack"]["approximations"]
    assert len(approximations) == 12
    labelled = {a["subject"].rsplit("/", 1)[1] for a in approximations if a["subject"].startswith("room/")}
    assert labelled == set(room["legend"]) - {".", "#"}  # every non-exact character is labelled


ORACLE_PY = os.environ.get("ORACLE_PY", "/usr/bin/python3")


def run_oracle(*args: str) -> subprocess.CompletedProcess:
    """Run the oracle in the interpreter that has PyBoy (the test venv does not)."""
    probe = subprocess.run([ORACLE_PY, "-W", "ignore", "-c", "import pyboy"], capture_output=True)
    if probe.returncode != 0:
        pytest.skip(f"SKIPPED (PyBoy not importable by {ORACLE_PY}; set ORACLE_PY)")
    env = {**os.environ, "PYTHONPATH": str(PROJECT_ROOT / "tools")}
    return subprocess.run([ORACLE_PY, "-W", "ignore", "-m", "wl3pc.oracle", *args], env=env,
                          capture_output=True, text=True, timeout=900)


def test_oracle_route_replays_to_the_recorded_state(rom_bytes):
    result = run_oracle("route-check")
    assert result.returncode == 0, result.stderr


def test_oracle_walk_capture_is_reproducible_and_matches_the_extracted_room(rom_bytes, tmp_path):
    out = tmp_path / "walk-right-300.capture.json"
    result = run_oracle("verify", "--out", str(out))
    assert result.returncode == 0, result.stderr
    capture = json.loads(out.read_text())
    test_oracle.validator("oracle-capture.v2.schema.json").validate(capture)
    names = [s["name"] for s in capture["samples"]]
    rows = [dict(zip(names, row)) for row in capture["rows"]]
    assert len(rows) == 300 and rows[0]["wJoypadDown"] == 0x10  # PAD_RIGHT, seen on the first tick
    assert {r["wWarioYPos"] for r in rows} == {752}
    xs = [r["wWarioXPos"] for r in rows]
    # Wario walks from the spawn point into the solid block at column 6 of ROOM_001 and stops.
    assert xs[0] == 56 and xs[22] == 88 and set(xs[22:]) == {88}
    counter = [r["wGlobalCounter"] for r in rows]
    assert all((b - a) % 256 == 1 for a, b in zip(counter, counter[1:]))  # one game loop per frame


def test_tas_editor_seeking_and_editing_match_straight_replays(rom_bytes):
    result = run_oracle("tas-check")
    assert result.returncode == 0, result.stderr
    assert "tas-check: OK" in result.stdout


def test_every_start_kind_matches_straight_replays(rom_bytes):
    result = run_oracle("starts-check")
    assert result.returncode == 0, result.stderr
    assert "starts-check: OK" in result.stdout


def test_probe_trace_matches_the_handler_mapping_and_the_decoded_map(rom_bytes, tmp_path):
    from wl3pc import oracle_review

    out = tmp_path / "walk.probes.json"
    result = run_oracle("probes", str(PROJECT_ROOT / "game/assets/traces/walk-right-300.json"), "--out", str(out))
    assert result.returncode == 0, result.stderr
    probes = json.loads(out.read_text())
    assert probes["hooks_unchanged_memory"] is True and probes["summary"]["calls"] > 1000
    by_handler = probes["summary"]["by_handler"]
    assert all(key.endswith("->0x00") for key in by_handler["h06_4020"])        # BlockFunc_Free: always free
    assert by_handler["h06_4032"]["down->0x01"] == 300                           # BlockFunc_Solid under Wario
    assert by_handler["h06_4d60"] == {"unk4->0x01": 277}                         # the non-cracked wall at column 6
    check = oracle_review.check_block_map(rom_bytes, probes, level=0)
    assert check["cells_checked"] >= 20 and check["mismatches"] == []


def test_wario_movement_tables_land_on_reference_symbols(rom_bytes):
    from wl3pc.extract import wario_movement as wm

    document = wm.decode(rom_bytes)
    assert len(document["walk_vel_table"]["steps"]) == 0x1C
    assert [len(t["steps"]) for t in document["jump_vel_tables"]] == [0x28] * 5
    if not SYM.exists():
        pytest.skip(f"SKIPPED symbol check (no {SYM}; run `make refbuild`)")
    document = wm.annotate(document, load_sym(SYM))
    assert document["walk_vel_table"]["symbol"] == "WalkVelTable"
    assert [t["symbol"] for t in document["jump_vel_tables"]] == [
        "JumpVelTable_KnockBack", "JumpVelTable_Normal", "JumpVelTable_HighJump", "JumpVelTable_BouncyJump",
        "JumpVelTable_BouncyHighJump"]
    assert [t["symbol"] for t in document["swim_vel_tables"].values()] == [
        "SwimStraightVelTable", "Data_1f894", "SwimDiagonalVelTable"]
    assert [t["symbol"] for t in document["flat_fall_tables"].values()] == ["Data_2b664", "Data_2b68c"]
    for key, item in document["framesets"].items():
        bank, address = (int(part, 16) for part in item["location"].split(":"))
        offset = bank * 0x4000 + address - 0x4000
        assert item["symbol"] == f"Frameset_{offset:x}", key  # labels are named after their file offset


def test_level_collision_resolves_every_room_of_out_of_the_woods(rom_bytes):
    from wl3pc.extract import level_collision as lc

    document = lc.build(rom_bytes, 0, load_sym(SYM) if SYM.exists() else None)
    assert document["block_map"] == "38:4000" and len(document["block_rows"]) == 48
    rooms_by_entry = {r["level_room_id"]: r for r in document["rooms"]}
    # List entry 0 is the start room, ROOM_001, with block function table $00 (WL3-024).
    assert (rooms_by_entry[0]["fields"]["room"], rooms_by_entry[0]["block_function_table"]) == (1, 0)
    assert all(len(r["handlers"]) == 0x80 for r in document["rooms"])
    known = {h["id"] for h in bf.decode(rom_bytes)["handlers"]}
    assert set(document["handlers"]) <= known
    if SYM.exists():
        assert document["handlers"]["h06_4032"] == "BlockFunc_Solid"


def test_native_wario_reproduces_the_walk_capture_alone(rom_bytes, tmp_path):
    from wl3pc import godot

    trace = tmp_path / "walk-right-300.wario.json"
    result = run_oracle("wario-trace", str(PROJECT_ROOT / "game/assets/traces/walk-right-300.json"), "--out", str(trace))
    assert result.returncode == 0, result.stderr
    document = json.loads(trace.read_text())
    test_oracle.validator("oracle-wario-trace.v1.schema.json").validate(document)
    assert len(document["updates"]) == 300
    if not (godot.ORIGINAL_CONTENT / "wario_movement.json").exists():
        pytest.skip("SKIPPED native run (no extracted content; run `make extract`)")
    godot.do_wario_parity(str(trace), "run")  # raises StepFailed on the first difference


def test_room_graphics_equal_the_reference_build_and_palette_source(rom_bytes):
    from wl3pc.extract import room_gfx

    document = room_gfx.decode(rom_bytes, 1)  # ROOM_001, Out of the Woods' first room
    gfx = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "src" / "gfx" / "levels"
    asm = PROJECT_ROOT / "external" / "ElectroDeoxys_warioland3" / "src" / "data" / "levels" / "palettes.asm"
    if not gfx.exists() or not asm.exists():
        pytest.skip("SKIPPED (no reference build or checkout; run `make refbuild`)")
    # LevelMainTiles0 and SpecialTiles0 are INCBINs of these build intermediates (src/level.asm).
    assert bytes.fromhex(document["main_tiles"]) == (gfx / "main_tiles0.2bpp").read_bytes()[:0x800]
    assert bytes.fromhex(document["special_tiles"]) == (gfx / "special_tiles0.2bpp").read_bytes()[:0x800]
    lines = asm.read_text().split("Pals_cc040:")[0].splitlines()
    source = [[int(v) for v in line.split("rgb", 1)[1].split(",")] for line in lines if line.strip().startswith("rgb")]
    assert [colour for palette in document["palettes"] for colour in palette] == source  # Pals_cc000
    assert document["audit"]["tile_numbers_outside_room_tiles"] == []


def test_screen_background_equals_the_decoded_room_graphics(rom_bytes, tmp_path):
    from wl3pc.extract import room_gfx

    rooms = tmp_path / "rooms"
    rooms.mkdir()
    (rooms / "room-001.gfx.json").write_text(json.dumps(room_gfx.decode(rom_bytes, 1)))
    out = tmp_path / "screen.json"
    result = run_oracle("screen-check", str(PROJECT_ROOT / "game/assets/traces/walk-right-300.json"),
                        "--ticks", "0,30,150,299", "--rooms", str(rooms), "--out", str(out))
    assert result.returncode == 0, result.stdout + result.stderr
    frames = json.loads(out.read_text())["frames"]
    assert all(f["compared"] > 20000 and f["matched"] == f["compared"] for f in frames.values())


def test_wario_sprites_equal_the_reference_build_labels_and_palette_source(rom_bytes):
    from wl3pc.extract import wario_sprites as ws

    document = ws.decode(rom_bytes)
    gfx = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "src" / "gfx" / "wario"
    asm = PROJECT_ROOT / "external" / "ElectroDeoxys_warioland3" / "src" / "gfx" / "pals" / "wario.asm"
    if not SYM.exists() or not gfx.exists() or not asm.exists():
        pytest.skip("SKIPPED (no reference build or checkout; run `make refbuild`)")
    labels = {}  # every label, local ones included (the frames are OAM_xxxxx.frame_N)
    for line in SYM.read_text().splitlines():
        parts = line.split()
        if len(parts) == 2 and ":" in parts[0] and not line.startswith(";"):
            labels.setdefault(parts[1], parts[0].lower())
    files = {"WarioIdleGfx": "idle", "WarioWalkGfx": "walk", "WarioAttackGfx": "attack", "WarioLadderGfx": "ladder",
             "WarioAirborneGfx": "airborne", "WarioSlideGfx": "slide",
             "WarioElectricGfx": "electric", "WarioDizzyGfx": "dizzy",
             "WarioStringGfx": "string", "WarioHotGfx": "hot",
             "WarioBurntGfx": "burnt", "WarioClearGfx": "clear",
             "WarioSwimGfx": "swim", "WarioFatGfx": "fat",
             "WarioBubbleGfx": "bubble", "WarioHangGfx": "hang", "WarioZombieGfx": "zombie",
             "WarioBouncyGfx": "bouncy", "WarioThrowGfx": "throw", "WarioCrazyGfx": "crazy",
             "WarioPuffyGfx": "puffy", "WarioSnowballGfx": "snowball",
             "WarioBatGfx": "bat", "WarioVampireGfx": "vampire", "WarioSnowmanGfx": "snowman",
             "WarioFanGfx": "fan", "WarioMagicGfx": "magic",
             "WarioBallGfx": "ball", "WarioLaunchGfx": "launch"}  # their INCBINs (src/main.asm)
    for key, tile_set in document["tile_sets"].items():
        assert labels[tile_set["name"]] == key
        assert bytes.fromhex(tile_set["tiles"]) == (gfx / f"{files[tile_set['name']]}.2bpp").read_bytes()
    for key, table in document["oam_tables"].items():
        assert labels[table["name"]] == key
        frames = [name for name in labels if name.startswith(table["name"] + ".frame_")]
        assert len(table["frames"]) == len(frames), table["name"]
    lines = asm.read_text().split("WarioOnFirePal:")[0].splitlines()
    source = [[int(v) for v in line.split("rgb", 1)[1].split(",")] for line in lines if line.strip().startswith("rgb")]
    decoded = [colour for key in ("03:4800", "03:4810") for palette in document["palettes"][key]["colours"]
               for colour in palette]
    assert decoded == source  # WarioDefaultPal, WarioInvisiblePal
    assert [document["palettes"][k]["name"] for k in ("03:4800", "03:4810")] == ["WarioDefaultPal", "WarioInvisiblePal"]


def test_screen_shows_wario_as_his_decoded_sprite(rom_bytes, tmp_path):
    from wl3pc.extract import room_gfx
    from wl3pc.extract import wario_sprites as ws

    (tmp_path / "rooms").mkdir()
    (tmp_path / "rooms" / "room-001.gfx.json").write_text(json.dumps(room_gfx.decode(rom_bytes, 1)))
    from wl3pc.extract import objects as objects_extract

    (tmp_path / "wario_sprites.json").write_text(json.dumps(ws.decode(rom_bytes)))
    (tmp_path / "objects.json").write_text(json.dumps(objects_extract.decode(rom_bytes)))
    out = tmp_path / "sprites.json"
    result = run_oracle("sprite-check", str(PROJECT_ROOT / "game/assets/traces/walk-right-300.json"),
                        "--sprites", str(tmp_path / "wario_sprites.json"), "--rooms", str(tmp_path / "rooms"),
                        "--out", str(out))
    assert result.returncode == 0, result.stdout + result.stderr
    check = json.loads(out.read_text())
    assert check["oam"]["checked"] == 300 and check["oam"]["matched"] == 300
    assert check["vram"]["matched"] == check["vram"]["checked"] == 300
    assert check["screen"]["compared"] > 100000 and check["screen"]["matched"] == check["screen"]["compared"]
    assert check["objects"]["checked"] > 400 and check["objects"]["matched"] == check["objects"]["checked"]
    assert check["objects"]["vram_groups"] == {"0a": True}


def test_object_framesets_land_on_the_reference_labels(rom_bytes):
    from wl3pc.extract import objects

    framesets = dict(objects.decode(rom_bytes)["framesets"]["by_pointer"])
    assert framesets["4036"][0] == [4, 10]
    # The null frameset (pointer 0) is ROM0 from $0000 up to the first $ff at a pair boundary.
    null = framesets.pop("0000")
    first_end = next(i for i in range(0, 0x100, 2) if rom_bytes[i] == 0xFF)
    assert [byte for pair in null for byte in pair] == list(rom_bytes[:first_end])
    # Framesets entered at their second pair (Shoot out of its ball): their label's pairs from there.
    for mid, start in (("6024", "6022"), ("603c", "603a")):
        assert framesets.pop(mid) == framesets[start][1:]
    if not SYM.exists():
        pytest.skip(f"SKIPPED symbol check (no {SYM}; run `make refbuild`)")
    labels = sorted(line.split()[0][3:] for line in SYM.read_text().splitlines()
                    if line.startswith("1a:") and line.split()[1].startswith("Frameset_"))
    assert sorted(framesets) == labels and len(labels) == 938
    # The movement data runs from StandingFallYVel_Light to the code that follows it.
    movement = objects.decode(rom_bytes)["movement_data"]
    ends = {line.split()[1]: line.split()[0] for line in SYM.read_text().splitlines() if line.startswith("18:")}
    assert ends["StandingFallYVel_Light"] == "18:4000" and movement["location"] == "18:4000"
    assert ends["UpdateObject_Temple"] == f"18:{0x4000 + len(movement['bytes']) // 2:04x}"
    # Object groups: the table and the dummy object at their labels, every data pointer on an object_data label.
    groups = objects.decode(rom_bytes)["object_groups"]
    by_name = {line.split()[1]: line.split()[0] for line in SYM.read_text().splitlines() if line.startswith("19:")}
    assert by_name["ObjectGroups"] == "19:5009" and by_name["DummyObjectData"] == "19:43c3"
    data_labels = {address[3:] for name, address in by_name.items() if name.endswith("Data")}
    assert len(groups["groups"]) == 146 and set(groups["object_data"]) <= data_labels


def test_the_outside_block_read_hook_follows_process_blocks_read(rom_bytes):
    from wl3pc.oracle_wario import PROCESS_BLOCK_READ

    bank, address = PROCESS_BLOCK_READ
    offset = bank * 0x4000 + address - 0x4000
    # ld hl, wBlockPtr; ld a, [hli]; ld l, [hl]; ld h, a; ld a, [hl] (the block byte), then the hook's add a.
    assert rom_bytes[offset - 7:offset + 1] == bytes([0x21, 0xEA, 0xCC, 0x2A, 0x6E, 0x67, 0x7E, 0x87])


def test_the_hidden_figure_camera_hook_is_update_levels_jump_to_check_end_screen(rom_bytes):
    from wl3pc.oracle_wario import UPDATE_LEVEL_AFTER_CAMERA, UPDATE_LEVEL_HIDDEN_FIGURE_CAMERA

    bank, address = UPDATE_LEVEL_HIDDEN_FIGURE_CAMERA
    offset = bank * 0x4000 + address - 0x4000
    # .asm_8227: jr .check_end_screen ($4247), just before .asm_8229, the other camera end.
    assert rom_bytes[offset:offset + 2] == bytes([0x18, 0x1E])
    assert UPDATE_LEVEL_AFTER_CAMERA == (bank, address + 2)


def test_the_animation_copy_hook_follows_its_h_blank_waits(rom_bytes):
    from wl3pc.oracle_wario import ANIMATION_COPY_CHUNK

    bank, address = ANIMATION_COPY_CHUNK
    offset = bank * 0x4000 + address - 0x4000
    # wait_not_hblank and wait_hblank (ldh a, [rSTAT]; and STAT_MODE; jr z/nz), then ld a, [hli]; ld [de], a.
    assert rom_bytes[offset - 12:offset + 2] == bytes.fromhex("f041e60328faf041e60320fa2a12")


def test_the_palette_write_hooks_follow_their_h_blank_waits(rom_bytes):
    from wl3pc.oracle_wario import SET_BG_PALS_WRITE, SET_WARIO_PAL_WRITE

    labels = {name: where for where, name in load_sym(SYM).items()} if SYM.exists() else {}
    for (bank, address), label in ((SET_BG_PALS_WRITE, "SetBGPals"), (SET_WARIO_PAL_WRITE, "SetWarioPal")):
        # wait_not_hblank and wait_hblank, then ld a, [hli]; ld [$ff00+c], a (c: rBGPD or rOBPD).
        assert bank == 0 and rom_bytes[address - 12:address + 2] == bytes.fromhex("f041e60328faf041e60320fa2ae2"), label
        if label in labels:
            assert labels[label].bank == 0 and 0 < address - labels[label].address < 0x80, label


def test_each_screen_hook_is_its_state_tables_dispatch(rom_bytes):
    from wl3pc.oracle_wario import SCREENS

    assert [layout.name for layout in SCREENS] == ["golf", "golf_building", "clear", "action_help", "overworld", "pause_menu",
                                                   "title", "language_selection", "credits", "game_over", "perfect"]
    for layout in SCREENS:
        bank, address = layout.hook
        offset = bank * 0x4000 + address - 0x4000
        # ld a, [wSubState]; rst $28 (the jump table).
        assert rom_bytes[offset:offset + 4] == bytes([0xFA, 0x9C, 0xC0, 0xEF]), layout.name


def test_every_div_read_hook_follows_an_ldh_from_rdiv(rom_bytes):
    from wl3pc.oracle_wario import DIV_READS

    assert len(DIV_READS) == len(set(DIV_READS)) == 61
    for bank, address in DIV_READS:
        offset = bank * 0x4000 + (address - 0x4000)
        assert rom_bytes[offset - 2:offset] == bytes([0xF0, 0x04]), f"{bank:02x}:{address:04x}"
    # The source has 48 reads of rDIV; every other mention is a comment. Three are in bank $56's temple
    # rock macros, which expand to 16: temple_rock_fall's two in each of six rocks, temple_rock_bounce's
    # one in each of four.
    source = PROJECT_ROOT / "external" / "ElectroDeoxys_warioland3" / "src"
    if not source.exists():
        pytest.skip(f"SKIPPED source count (no {source})")
    reads = sum(text.count("ldh a, [rDIV]") for text in (p.read_text(errors="replace") for p in source.rglob("*.asm")))
    assert reads == 48
    assert reads - 3 + 6 * 2 + 4 == len(DIV_READS)


def test_particle_framesets_and_tables_land_on_the_reference_labels(rom_bytes):
    from wl3pc.extract import objects

    particles = objects.decode_particles(rom_bytes)
    assert all(pairs for pairs in particles["framesets"].values())
    if not SYM.exists():
        pytest.skip(f"SKIPPED symbol check (no {SYM}; run `make refbuild`)")
    labels = {line.split()[0]: line.split()[1] for line in SYM.read_text().splitlines() if line.startswith("03:")}
    for key in particles["framesets"]:
        assert labels[f"03:{key}"] == f"Frameset_{0xC000 + int(key, 16) - 0x4000:x}", key
    for key in particles["oam_tables"]:
        assert labels[f"03:{key}"] == f"OAM_{0xC000 + int(key, 16) - 0x4000:x}", key


def test_room_animation_tables_equal_the_source_and_the_reference_build(rom_bytes):
    import re

    from wl3pc.extract import room_gfx

    animation = room_gfx.decode_animation(rom_bytes)
    source = PROJECT_ROOT / "external" / "ElectroDeoxys_warioland3" / "src" / "data" / "levels" / "rooms1.asm"
    gfx = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "src" / "gfx" / "levels" / "animated"
    if not source.exists() or not gfx.exists():
        pytest.skip("SKIPPED (no reference checkout or build; run `make refbuild`)")
    text = source.read_text()
    groups = re.findall(r"db\s+(\d+), ANIMATED_TILES_GFX_(\d+) ; ANIMATED_TILES_GROUP", text)
    assert animation["animated_tiles_groups"] == [[int(d), int(g)] for d, g in groups]
    durations = [int(d) for d in re.findall(r"\.PalCycle\d+:\n(?:\tdb ROOM_PAL_\d+\n){8}\tdb (\d+) ; duration", text)]
    assert sorted({c["duration"] for c in animation["pal_cycles"]}) == sorted(set(durations))
    for index, data in animation["animated_tiles_gfx"].items():
        assert bytes.fromhex(data) == (gfx / f"animated_tiles{int(index) + 1}.2bpp").read_bytes()[:0x200], index
