import json

import pytest

from synthetic_rom import build_rom, fix
from wl3pc.address import BankedAddress
from wl3pc.extract import block_functions as bf
from wl3pc.provenance import ROM_DERIVED_MARKER
from wl3pc.rom import UnknownRomError
from wl3pc.symbols import parse_editor_ref, parse_sym

# A miniature layout over a 64 KiB synthetic ROM (banks 0-3).
LAYOUT = bf.BlockFunctionLayout(
    rom_id="synthetic", pointer_table=BankedAddress(1, 0x4000), pointer_count=4, group2_first_index=2,
    group1_bank=1, group2_bank=2, entries_per_table=4, handler_bank=3,
)


def le(*words: int) -> bytes:
    return b"".join(w.to_bytes(2, "little") for w in words)


def synthetic(pointers=(0x4010, 0x4020, 0x4000, 0xFFFF), group1=None, group2=None) -> bytes:
    patches = {
        0x4000: le(*pointers),
        0x4010: le(*(group1 or (0x4100, 0x4100, 0x4200, 0x0028))),
        0x4020: le(0x4200, 0x4200, 0x4200, 0x4200),
        0x8000: le(*(group2 or (0x4300, 0x4100, 0x4100, 0x4100))),
    }
    return bytes(build_rom(size=0x10000, patches=patches))


def test_decodes_groups_sentinels_and_rom0_handlers():
    document = bf.decode(synthetic(), LAYOUT)
    statuses = [t["status"] for t in document["tables"]]
    assert statuses == ["decoded", "decoded", "decoded", "reset-sentinel"]
    assert document["tables"][0]["entries"] == ["h03_4100", "h03_4100", "h03_4200", "h00_0028"]
    # Index 2 is in group 2: the same 16-bit pointer is read from bank 2, not bank 1.
    assert document["tables"][2]["location"] == "02:4000"
    assert document["tables"][2]["entries"][0] == "h03_4300"
    handlers = {h["id"]: h["used_by_tables"] for h in document["handlers"]}
    assert handlers == {"h00_0028": [0], "h03_4100": [0, 2], "h03_4200": [0, 1], "h03_4300": [2]}


def test_rejects_handler_outside_rom():
    with pytest.raises(bf.MalformedDataError, match="not a ROM address"):
        bf.decode(synthetic(group1=(0x4100, 0xC000, 0x4100, 0x4100)), LAYOUT)


def test_rejects_table_pointer_outside_romx():
    with pytest.raises(bf.MalformedDataError, match="table 0x00"):
        bf.decode(synthetic(pointers=(0x2000, 0x4020, 0x4000, 0xFFFF)), LAYOUT)


def test_rejects_table_crossing_bank_end():
    with pytest.raises(bf.MalformedDataError, match="cross the end of bank"):
        bf.decode(synthetic(pointers=(0x7FFC, 0x4020, 0x4000, 0xFFFF)), LAYOUT)


def test_rejects_truncated_rom():
    with pytest.raises(bf.MalformedDataError, match="pointer table"):
        bf.decode(bytes(build_rom(size=0x4000)), LAYOUT)


def test_labels_are_optional_and_do_not_change_values():
    document = bf.decode(synthetic(), LAYOUT)
    plain = json.dumps(document["tables"], sort_keys=True)
    symbols = parse_sym("; header\n03:4100 Handler_A\n03:4100 Handler_A.local\n03:4200 Handler_B\n00:0028 Rst28\nc0:d000 wRam\n")
    editor = parse_editor_ref("; comment\nFirst= 4100\n[section]\nUnused= 4abc\n")
    bf.annotate(document, symbols, editor, handler_bank=3)
    assert json.dumps(document["tables"], sort_keys=True) == plain
    by_id = {h["id"]: h for h in document["handlers"]}
    assert by_id["h03_4100"]["symbol"] == "Handler_A"
    assert by_id["h03_4100"]["editor_names"] == ["First"]
    assert by_id["h00_0028"]["editor_names"] == []  # editor names only describe the handler bank
    assert document["audit"]["handlers_without_symbol"] == ["h03_4300"]
    assert document["audit"]["editor_entries_unused_by_any_table"] == ["Unused (4abc)"]


def wl3_shaped_rom() -> bytes:
    """2 MiB synthetic ROM that satisfies the WL3 layout with one decodable table."""
    layout = bf.WL3_WORLD_LAYOUT
    pointers = [0xFFFF] * layout.pointer_count
    pointers[0] = 0x40C4
    patches = {
        layout.pointer_table.file_offset: le(*pointers),
        BankedAddress(0x32, 0x40C4).file_offset: le(*([0x4032] * layout.entries_per_table)),
    }
    return bytes(build_rom(size=0x200000, patches=patches))


def test_extract_refuses_unknown_rom(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    with pytest.raises(UnknownRomError):
        bf.extract(rom_path, tmp_path / "out")
    assert not (tmp_path / "out").exists()


def test_exploratory_extraction_is_marked_and_deterministic(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    first = bf.extract(rom_path, tmp_path / "out", exploratory=True)
    second = bf.extract(rom_path, tmp_path / "out", exploratory=True)
    assert first["changed"] and not second["changed"]
    assert first["sha256"] == second["sha256"]
    output = tmp_path / "out" / "exploratory" / "block_function_tables.json"
    document = json.loads(output.read_text())
    assert document["exploratory"] is True
    assert document["marker"] == ROM_DERIVED_MARKER
    assert document["tables"][0]["entries"][:2] == ["h06_4032", "h06_4032"]
    assert sum(t["status"] == "reset-sentinel" for t in document["tables"]) == bf.WL3_WORLD_LAYOUT.pointer_count - 1
    assert "timestamp" not in output.read_text()
    assert not (output.stat().st_mode & 0o222), "extracted base files are written read-only"


def test_malformed_wl3_layout_fails_clearly(tmp_path):
    rom_path = tmp_path / "zeros.gbc"
    rom_path.write_bytes(bytes(fix(build_rom(size=0x200000))))
    with pytest.raises(bf.MalformedDataError):
        bf.extract(rom_path, tmp_path / "out", exploratory=True)
