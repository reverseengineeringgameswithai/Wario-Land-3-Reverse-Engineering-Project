import copy
import json

import jsonschema
import pytest

import test_block_functions
from wl3pc.extract import block_functions as bf
from wl3pc.extract import block_materials as bm
from wl3pc.paths import PROJECT_ROOT
from wl3pc.provenance import ROM_DERIVED_MARKER, sha256_file
from wl3pc.rom import UnknownRomError


def schema(name: str) -> jsonschema.Draft202012Validator:
    return jsonschema.Draft202012Validator(json.loads((PROJECT_ROOT / "schemas" / name).read_text()))


def minimal_mapping() -> dict:
    return {
        "format": bm.MAPPING_FORMAT, "format_version": 1,
        "evidence_base": {"repository": "r", "commit": "0" * 40, "file": "f", "research_note": "n"},
        "materials": {"empty": "free", "solid": "blocks"},
        "flags": {"door": "enters", "breakable-cracked": "breaks"},
        "handlers": [
            {"id": "h03_4100", "symbol": "A", "material": "solid", "flags": ["breakable-cracked"],
             "replacement_block": 120, "evidence": "read"},
            {"id": "h03_4200", "symbol": "B", "material": "empty", "flags": ["door"], "room_transition": 226,
             "evidence": "read"},
        ],
    }


def test_tracked_mapping_passes_schema_and_rules():
    mapping = bm.load_mapping()
    schema("block-handler-materials.v1.schema.json").validate(mapping)
    assert len(mapping["handlers"]) == 31
    # The runtime prototype materials keep their meaning.
    assert {"empty", "solid", "platform"} <= mapping["materials"].keys()


@pytest.mark.parametrize("change, message", [
    (lambda m: m["handlers"][0].update(material="glass"), "material 'glass' is not defined"),
    (lambda m: m["handlers"][0]["flags"].append("sticky"), "flag 'sticky' is not defined"),
    (lambda m: m["handlers"].append(dict(m["handlers"][0])), "duplicate row"),
    (lambda m: m["materials"].update(unknown="x"), "reserved"),
    (lambda m: m["handlers"][1].pop("room_transition"), "room_transition must be present"),
    (lambda m: m["handlers"][0].pop("replacement_block"), "replacement_block must be present"),
    (lambda m: m["handlers"][1].update(replacement_block=1), "replacement_block must be present"),
    (lambda m: m["handlers"][0].update(evidence=""), "no evidence"),
    (lambda m: m["handlers"][0].update(id="h3_4100"), "malformed id"),
])
def test_mapping_rules_reject_inconsistent_rows(change, message):
    mapping = minimal_mapping()
    bm.check_mapping(mapping)
    change(mapping)
    with pytest.raises(bm.MappingError, match=message):
        bm.check_mapping(mapping)


def test_unmapped_handlers_become_unknown_never_empty():
    tables = bf.decode(test_block_functions.synthetic(), test_block_functions.LAYOUT)
    mapping = minimal_mapping()
    document = bm.apply(tables, mapping)
    first = document["tables"][0]
    # Table 0 is h03_4100, h03_4100, h03_4200, h00_0028 in the synthetic ROM.
    assert [b["material"] for b in first["blocks"]] == ["solid", "solid", "empty", "unknown"]
    assert first["blocks"][0] == {"material": "solid", "flags": ["breakable-cracked"], "replacement_block": 120}
    assert first["blocks"][2] == {"material": "empty", "flags": ["door"], "room_transition": 226}
    assert first["unknown_blocks"] == 1
    assert document["tables"][3] == {"index": 3, "status": "reset-sentinel"}
    assert document["audit"] == {
        "unmapped_handlers_used": ["h00_0028", "h03_4300"],
        "mapped_handlers_not_found": [],
        "tables_fully_mapped": [1],
    }
    # Applying never edits the mapping it was given.
    assert mapping == minimal_mapping()


def test_mapping_rows_for_absent_handlers_are_reported():
    tables = bf.decode(test_block_functions.synthetic(), test_block_functions.LAYOUT)
    mapping = minimal_mapping()
    extra = copy.deepcopy(mapping["handlers"][0])
    extra["id"] = "h03_7000"
    mapping["handlers"].append(extra)
    assert bm.apply(tables, mapping)["audit"]["mapped_handlers_not_found"] == ["h03_7000"]


def test_exploratory_extraction_is_marked_deterministic_and_schema_valid(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(test_block_functions.wl3_shaped_rom())
    with pytest.raises(UnknownRomError):
        bm.extract(rom_path, tmp_path / "refused")
    first = bm.extract(rom_path, tmp_path / "out", exploratory=True)
    second = bm.extract(rom_path, tmp_path / "out", exploratory=True)
    assert first["changed"] and not second["changed"]
    output = tmp_path / "out" / "exploratory" / "block_materials.json"
    document = json.loads(output.read_text())
    schema("block-materials.v1.schema.json").validate(document)
    assert document["exploratory"] is True and document["marker"] == ROM_DERIVED_MARKER
    assert document["provenance"]["mapping_sha256"] == sha256_file(bm.MAPPING_PATH)
    # The synthetic table is all BlockFunc_Solid, which the tracked mapping covers.
    assert {b["material"] for b in document["tables"][0]["blocks"]} == {"solid"}
    assert document["audit"]["tables_fully_mapped"] == [0]
    assert not (output.stat().st_mode & 0o222), "extracted base files are written read-only"


def test_extract_rejects_a_broken_mapping(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(test_block_functions.wl3_shaped_rom())
    broken = minimal_mapping()
    broken["handlers"][0]["material"] = "glass"
    mapping_path = tmp_path / "mapping.json"
    mapping_path.write_text(json.dumps(broken))
    with pytest.raises(bm.MappingError):
        bm.extract(rom_path, tmp_path / "out", mapping_path, exploratory=True)
    assert not (tmp_path / "out").exists()
