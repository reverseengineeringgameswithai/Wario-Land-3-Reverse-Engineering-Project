"""The title's data (wl3pc.extract.title) on a synthetic ROM, its addresses and the port's RAM constants
against the reference build's symbols, a continue movie's scripted presses, and the power-on save and the
captured loads a parity run takes (WL3-055, WL3-057)."""

import re
from pathlib import Path

import pytest

from test_rooms import at
from wl3pc import godot, oracle, oracle_save
from wl3pc.address import BankedAddress
from wl3pc.extract import title
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"
PORT = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "title_sim.gd"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    for where in title.OAM_TABLES:  # one frame, one entry
        start = at(where.bank, where.address)
        rom[start:start + 7] = (where.address + 2).to_bytes(2, "little") + bytes([0xF8, 0xFC, 0x04, 0x01, 0x80])
    start = at(0x01, 0x6CF2)
    rom[start:start + 5] = bytes([4, 30, 2, 3, 0xFF])
    for where in title.COMPRESSED:  # empty streams
        rom[at(where.bank, where.address)] = 0
    start = at(0x01, 0x6B47)
    rom[start:start + 24] = bytes([0x7C] * 12 + [0x10] * 12)
    start = at(0x01, 0x5002)
    rom[start:start + 2] = bytes([0xC0, 0x42])
    return bytes(rom)


def test_framesets_oam_tables_graphics_maps_and_palettes_decode_from_their_places():
    document = title.decode(synthetic())
    assert document["framesets"]["01:6cf2"] == [[4, 30], [2, 3]]
    assert document["framesets"]["01:7198"] == []
    assert len(document["framesets"]) == 22
    assert document["oam_tables"]["01:6b5f"] == document["oam_tables"]["01:75c3"] == [[[-8, -4, 4, 1]]]
    assert document["gfx"]["compressed"]["01:697a"] == ""
    assert document["gfx"]["raw"]["01:6b47"] == "7c" * 12 + "10" * 12
    assert document["gfx"]["palettes"]["01:5002"][:4] == "c042"
    assert len(bytes.fromhex(document["gfx"]["palettes"]["01:4fc2"])) == 0x40


def _symbols() -> dict[str, tuple[int, int]]:
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    names: dict[str, tuple[int, int]] = {}
    for line in SYM.read_text().splitlines():
        match = re.match(r"([0-9a-f]{2}):([0-9a-f]{4}) (\S+)$", line)
        if match:
            names.setdefault(match.group(3), (int(match.group(1), 16), int(match.group(2), 16)))
    return names


def test_the_extractor_reads_the_labelled_data():
    names = _symbols()
    labels = {where: name for name, where in names.items() if "." not in name}
    for where in title.FRAMESETS:
        assert labels.get((where.bank, where.address), "").startswith("Frameset_"), str(where)
    assert [labels.get((where.bank, where.address)) for where in title.OAM_TABLES] == ["OAM_6b5f", "OAM_6d21", "OAM_75c3"]
    places = [*title.COMPRESSED, *map(BankedAddress.parse, title.RAW), *map(BankedAddress.parse, title.PALETTES)]
    expected = ["TitleScreenGfx", "PlaneGfx", "TitleScreenTilemap", "TitleScreenAttrmap", "FontGfx",
                "LanguageSelection1TextMap", "LanguageSelection2TextMap", "TimeAttack1JPTextMap",
                "TimeAttack2JPTextMap", "TimeAttack1ENTextMap", "TimeAttack2ENTextMap", "TitleScreenBoxTilemap",
                "PrologueBackgroundGfx", "Pals_4f82", "Pals_4fc2", "Pals_5002", "Pals_5042", "Pals_1f3610",
                "Pals_71b0"]
    for where, name in zip(places, expected, strict=True):
        assert names[name] == (where.bank, where.address), name
    # The box's two rows end where OAM_6b5f starts.
    box = BankedAddress.parse(next(iter(title.RAW)))
    assert box.address + title.RAW[str(box)] == names["OAM_6b5f"][1]


def test_the_titles_framesets_are_the_ones_the_port_names():
    named = {int(value, 16) for value in re.findall(r"^const FRAMESET_[0-9A-F]{4}: int = 0x([0-9A-F]{4})$",
                                                     PORT.read_text(), re.MULTILINE)}
    assert named == {where.address for where in title.FRAMESETS}


def test_the_titles_ram_constants_are_the_labels_they_name():
    names: dict[str, tuple[int, int]] = {}
    for name, where in _symbols().items():  # without their underscores: W_TEMP_PALS_1, wTempPals1
        names.setdefault(name.replace("_", "").lower(), where)
    checked = 0
    for constant, value in re.findall(r"^const (W[0-9A-Z_]+): int = 0x([0-9A-F]{4})$", PORT.read_text(), re.MULTILINE):
        label = constant.replace("_", "").lower()
        assert label in names, constant
        assert names[label][1] == int(value, 16), constant
        checked += 1
    assert checked >= 16


def test_scripted_presses_are_single_ticks_or_held_ranges():
    assert oracle_save.parse_presses("200:a, 600-602:right+a,") == [
        (200, 200, frozenset({"a"})), (600, 602, frozenset({"right", "a"}))]
    for bad in ("200", "x:a", "200:jump", "1-:a"):
        with pytest.raises(oracle.OracleError):
            oracle_save.parse_presses(bad)


def test_an_invented_time_attack_save_keeps_each_map_saves_sum():
    save = bytearray(0x8000)
    data = bytearray(range(1, 0x5B + 0x11 + 1))  # the progress and the treasures
    data[oracle_save.GAME_MODE_FLAGS_OFFSET] = 0x01  # Time Attack off
    save[0x380:0x384] = b"war3"
    save[0x384:0x384 + len(data)] = data
    for address in (0xA791, 0xA7E1, 0xAFA1):
        save[address - 0xA000:address - 0xA000 + 2] = (sum(data) & 0xFFFF).to_bytes(2, "big")
    invented = oracle_save.with_mode_flags(bytes(save), oracle_save.MODE_TIME_ATTACK)
    flags = invented[0x384 + oracle_save.GAME_MODE_FLAGS_OFFSET]
    assert flags == 0x03
    new_sum = sum(invented[0x384:0x384 + len(data)]) & 0xFFFF
    assert new_sum == (sum(data) + 2) & 0xFFFF
    for address in (0xA791, 0xA7E1, 0xAFA1):
        assert int.from_bytes(invented[address - 0xA000:address - 0xA000 + 2], "big") == new_sum
    backup = [range(0xAB80 - 0xA000, 0xAB84 - 0xA000 + len(data))] + [
        range(address - 0xA000, address - 0xA000 + 2) for address in (0xA793, 0xA7E3, 0xAFA3)]
    assert all(invented[i] == save[i] for part in backup for i in part), "no backup save: left alone"
    assert oracle_save.with_mode_flags(invented, oracle_save.MODE_TIME_ATTACK) == invented
    japanese = oracle_save.with_progress_byte(invented, oracle_save.LANGUAGE_OFFSET, lambda _value: 0)
    assert japanese[0x384 + oracle_save.LANGUAGE_OFFSET] == 0
    assert int.from_bytes(japanese[0x791:0x793], "big") == sum(japanese[0x384:0x384 + len(data)]) & 0xFFFF


def test_an_invented_crayon_save_sets_the_seven_crayon_treasures_and_keeps_the_sum(monkeypatch):
    save = bytearray(0x8000)
    data = bytearray(0x5B + 0x11)  # the progress and the treasures, none got
    save[0x380:0x384] = b"war3"
    save[0x384:0x384 + len(data)] = data
    stored: dict = {}
    monkeypatch.setattr(oracle, "store_get", lambda kind, sha: bytes(save))
    monkeypatch.setattr(oracle, "store_put", lambda kind, data, meta: stored.update(data=data, meta=meta) or "sha")
    assert oracle_save.invent_crayons("x" * 64) == "sha"
    invented = stored["data"]
    treasures = invented[0x384 + oracle_save.TREASURES_OFFSET:0x384 + oracle_save.TREASURES_OFFSET + 0x11]
    # Treasures $5e and $5f are byte 11's bits 6 and 7, $60-$64 byte 12's bits 0-4 (GetCrayonFlags).
    assert (treasures[11], treasures[12]) == (0xC0, 0x1F) and sum(treasures) == 0xC0 + 0x1F
    assert int.from_bytes(invented[0x791:0x793], "big") == 0xC0 + 0x1F
    assert stored["meta"]["invented"] is True
    monkeypatch.setattr(oracle, "store_get", lambda kind, sha: invented)
    with pytest.raises(oracle.OracleError):
        oracle_save.invent_crayons("x" * 64)


def test_an_invented_musical_coin_save_sets_25_flags_and_999_coins(monkeypatch):
    save = bytearray(0x8000)
    data = bytearray(0x5B + 0x11)
    save[0x380:0x384] = b"war3"
    save[0x384:0x384 + len(data)] = data
    stored: dict = {}
    monkeypatch.setattr(oracle, "store_get", lambda kind, sha: bytes(save))
    monkeypatch.setattr(oracle, "store_put", lambda kind, data, meta: stored.update(data=data) or "sha")
    oracle_save.invent_musical_coins("x" * 64)
    progress = stored["data"][0x384:0x384 + 0x5B]
    assert progress[oracle_save.MUSICAL_COIN_FLAGS_OFFSET:oracle_save.MUSICAL_COIN_FLAGS_OFFSET + 4] == bytes(
        [0xFF, 0xFF, 0xFF, 0x01])
    assert progress[oracle_save.COINS_OFFSET:oracle_save.COINS_OFFSET + 2] == bytes([0x09, 0x99])
    assert int.from_bytes(stored["data"][0x791:0x793], "big") == 0xFF * 3 + 1 + 0x09 + 0x99


def test_invented_treasures_set_their_bits_and_keep_the_sum(monkeypatch):
    save = bytearray(0x8000)
    data = bytearray(0x5B + 0x11)
    save[0x380:0x384] = b"war3"
    save[0x384:0x384 + len(data)] = data
    stored: dict = {}
    monkeypatch.setattr(oracle, "store_get", lambda kind, sha: bytes(save))
    monkeypatch.setattr(oracle, "store_put", lambda kind, data, meta: stored.update(data=data, meta=meta) or "sha")
    oracle_save.invent_treasures("x" * 64, [0x4D, 0x01])  # the Day/Night Spell, and treasure 1
    treasures = stored["data"][0x384 + oracle_save.TREASURES_OFFSET:0x384 + oracle_save.TREASURES_OFFSET + 0x11]
    assert (treasures[0], treasures[9]) == (0x02, 0x20) and sum(treasures) == 0x22
    assert int.from_bytes(stored["data"][0x791:0x793], "big") == 0x22
    assert "$4d, $01" in stored["meta"]["change"]


def test_an_invented_cleared_game_save_sets_the_flag_and_keeps_the_sum(monkeypatch):
    save = bytearray(0x8000)
    data = bytearray(0x5B + 0x11)
    save[0x380:0x384] = b"war3"
    save[0x384:0x384 + len(data)] = data
    stored: dict = {}
    monkeypatch.setattr(oracle, "store_get", lambda kind, sha: bytes(save))
    monkeypatch.setattr(oracle, "store_put", lambda kind, data, meta: stored.update(data=data, meta=meta) or "sha")
    oracle_save.invent_game_cleared("x" * 64)
    flags = oracle_save.MODE_GAME_CLEARED | oracle_save.MODE_FOUGHT_A_HIDDEN_FIGURE
    assert stored["data"][0x384 + oracle_save.GAME_MODE_FLAGS_OFFSET] == flags
    assert int.from_bytes(stored["data"][0x791:0x793], "big") == flags
    assert "MODE_GAME_CLEARED" in stored["meta"]["change"]
    monkeypatch.setattr(oracle, "store_get", lambda kind, sha: stored["data"])
    with pytest.raises(oracle.OracleError):
        oracle_save.invent_game_cleared("x" * 64)


def test_an_invented_power_up_save_sets_every_power_up_level_9_and_the_count(monkeypatch):
    save = bytearray(0x8000)
    data = bytearray(0x5B + 0x11)
    data[oracle_save.POWER_UP_LEVEL_OFFSET] = 2
    data[oracle_save.TREASURES_OFFSET + 0x0C // 8] = 0x10  # treasure $0c (the Lead Overalls) only
    data[oracle_save.TREASURES_OFFSET + 0x61 // 8] |= 0x02  # and treasure $61 (a crayon)
    save[0x380:0x384] = b"war3"
    save[0x384:0x384 + len(data)] = data
    for address in (0xA791, 0xA7E1, 0xAFA1):
        save[address - 0xA000:address - 0xA000 + 2] = sum(data).to_bytes(2, "big")
    stored: dict = {}
    monkeypatch.setattr(oracle, "store_get", lambda kind, sha: bytes(save))
    monkeypatch.setattr(oracle, "store_put", lambda kind, data, meta: stored.update(data=data, meta=meta) or "sha")
    oracle_save.invent_power_ups("x" * 64)
    progress = stored["data"][0x384:0x384 + 0x5B + 0x11]
    treasures = progress[oracle_save.TREASURES_OFFSET:]
    assert all(treasures[t // 8] & (1 << (t % 8)) for t in oracle_save.POWER_UP_TREASURES)
    assert progress[oracle_save.POWER_UP_LEVEL_OFFSET] == 9
    # Nine power-ups and the crayon: 10, in BCD with the hundreds first.
    assert progress[oracle_save.NUM_COLLECTED_TREASURES_OFFSET:oracle_save.NUM_COLLECTED_TREASURES_OFFSET + 2] == bytes(
        [0x00, 0x10])
    assert int.from_bytes(stored["data"][0x791:0x793], "big") == sum(progress) & 0xFFFF
    assert stored["meta"]["invented"] is True


def test_a_power_on_movie_gives_its_save_to_the_parity_run(tmp_path, monkeypatch):
    assert godot.power_on_save({"kind": "route", "id": "ootw-day1-start"}) is None
    assert godot.power_on_save({"kind": "power-on", "cartridge_ram": {"source": "empty"}}) == ""
    monkeypatch.setattr(godot, "PROJECT_ROOT", tmp_path)
    digest = "ab" * 32
    with pytest.raises(godot.StepFailed):
        godot.power_on_save({"kind": "power-on", "cartridge_ram": {"source": "file", "sha256": digest}})
    saves = tmp_path / "local" / "oracle" / "saves"
    saves.mkdir(parents=True)
    (saves / f"{digest}.sav").write_bytes(bytes(0x8000))
    start = {"kind": "power-on", "cartridge_ram": {"source": "file", "sha256": digest}}
    assert godot.power_on_save(start) == str(saves / f"{digest}.sav")
    assert godot.save_file(digest) == saves / f"{digest}.sav"
    assert godot.save_file("none") == "none"
    (tmp_path / "short.sav").write_bytes(bytes(10))
    with pytest.raises(godot.StepFailed):
        godot.save_file(str(tmp_path / "short.sav"))


def test_a_power_on_runs_loads_are_the_movies_captured_loads_in_order(tmp_path, monkeypatch):
    monkeypatch.setattr(godot, "SAVE_LOAD_CAPTURES", tmp_path)
    for name in ["movie-load2.json", "movie-load10.json", "movie-load1.json", "movie-2-load1.json", "movie-loadx.json"]:
        (tmp_path / name).write_text("{}")
    assert godot.movie_loads(Path("local/captures/movie.wario.json")) == [
        tmp_path / "movie-load1.json", tmp_path / "movie-load2.json", tmp_path / "movie-load10.json"]
    assert godot.movie_loads(Path("local/captures/other.wario.json")) == []
