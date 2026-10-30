import json

import pytest

import test_rooms
from synthetic_rom import build_rom
from wl3pc import content
from wl3pc.address import BankedAddress, RomView
from wl3pc.extract import block_materials as bm
from wl3pc.extract import level_headers as lh
from wl3pc.extract import level_maps as lm
from wl3pc.extract import room_pack as rp
from wl3pc.extract.rle import decompress
from wl3pc.provenance import ROM_DERIVED_MARKER
from wl3pc.rom import UnknownRomError

le, at = test_rooms.le, test_rooms.at


def encode_rle(data: bytes) -> bytes:
    """Encoder for the original's run/literal scheme (test helper; the game only decodes)."""
    out, i = bytearray(), 0
    while i < len(data):
        run = 1
        while i + run < len(data) and run < 0x7F and data[i + run] == data[i]:
            run += 1
        if run >= 3:
            out += bytes([run, data[i]])
            i += run
            continue
        literal = data[i:i + min(0x7F, len(data) - i)]
        out += bytes([0x80 | len(literal)]) + literal
        i += len(literal)
    return bytes(out) + b"\x00"


def grid(width: int, height: int, fill: int) -> list[bytearray]:
    return [bytearray([fill]) * width for _ in range(height)]


def wl3_shaped_rom(region_extra: dict[tuple[int, int], int] | None = None, spawn=(20, 30)) -> bytes:
    """One level whose start room covers sections x 0-1, y 1 (block rows 16-31, columns 0-31)."""
    headers, maps = lh.WL3_WORLD_LEVEL_LAYOUT, lm.WL3_WORLD_MAP_LAYOUT
    blocks = grid(160, 48, 0x00)                     # block 0: BlockFunc_Solid
    for y in range(16, 31):
        blocks[y][2:30] = bytes([0x01]) * 28         # block 1: BlockFunc_Free
    blocks[25][10] = 0x02                            # block 2: BlockFunc_CrackedBlock_78
    blocks[20][5] = 0x81                             # bit 7 set; still block 1
    for (x, y), value in (region_extra or {}).items():
        blocks[y][x] = value
    objects = grid(80, 48, 0x00)
    spawn_x, spawn_y = spawn
    objects[spawn_y][spawn_x // 2] = 0xF0 if spawn_x % 2 == 0 else 0x0F
    return test_rooms.wl3_shaped_rom(extra={
        at(0x32, 0x40C4 + 2): le(0x4020, 0x4CB4, 0x40D9),  # blocks 1-3: free, cracked, right slope
        headers.level_pointer_table.file_offset: le(*([0x4D1F] + [0xFFFF] * (headers.level_count - 1))),
        at(0x30, 0x4D1F): le(*([0x4D5B] + [0xFFFF] * (headers.entries_per_list - 1))),
        # spawn section (x 1, y 1); Y limits 1-2; X limits 0-2; ROOM_001
        at(0x30, 0x4D5B): bytes([0x11, 0x12, 0x02, 0x00, 0x01, 0x00, 0x00, 0x01]),
        maps.pointer_table.file_offset: le(*([0x4300] + [0xFFFF] * (maps.level_count - 1))),
        at(0x30, 0x4300): le(0x4000) + bytes([0x38]) + le(0x5000),
        at(0x38, 0x4000): encode_rle(b"".join(blocks)),
        at(0x38, 0x5000): encode_rle(b"".join(objects)),
    })


def movement() -> dict:
    return json.loads(rp.SYNTHETIC_MOVEMENT.read_text())


def test_rle_helper_round_trips():
    data = bytes([1, 1, 1, 1, 2, 3, 3, 3, 4]) + bytes(300)
    rom = bytes(build_rom(size=0x8000, patches={0x4000: encode_rle(data)}))
    assert decompress(RomView(rom), BankedAddress(1, 0x4000), 1000)[0] == data


def test_builds_room_with_exact_cells_and_labelled_approximations():
    built = rp.build(wl3_shaped_rom(), bm.load_mapping(), 0, movement())
    room, pack = built["room"], built["pack"]
    assert (len(room["rows"]), len(room["rows"][0])) == (16, 32)
    assert room["legend"] == {"#": "solid", ".": "empty", "A": "solid"}
    assert room["rows"][9][10] == "A" and room["rows"][4][5] == "."  # bit 7 does not change the block
    assert room["rows"][0] == "##" + "." * 28 + "##" and room["rows"][15] == "#" * 32
    breakable, start, moves = pack["approximations"]
    assert breakable == {"subject": "room/room-001/legend/A", "behaves_as": "solid", "task": "WL3-026",
                         "original": "solid, breakable-cracked, becomes block $78 when broken"}
    assert (start["subject"], moves["subject"], moves["task"]) == ("start", "movement", "WL3-012")
    # Spawn block (20, 30): point (328, 496) in the level, (328, 240) in the room; body 12 x 24.
    assert built["details"]["spawn_point_px"] == [328, 496]
    assert pack["start"] == {"room": "room-001", "x_px": 322, "y_px": 216}
    assert pack["origin"] == "original-extracted" and ROM_DERIVED_MARKER in pack["license"]
    assert built["movement"]["provisional"] is True


def test_unimplemented_material_stops_the_build():
    with pytest.raises(rp.PackError, match="slope-right.*does not implement"):
        rp.build(wl3_shaped_rom({(12, 20): 0x03}), bm.load_mapping(), 0, movement())


def test_unknown_material_stops_the_build():
    mapping = bm.load_mapping()
    mapping["handlers"] = [row for row in mapping["handlers"] if row["symbol"] != "BlockFunc_CrackedBlock_78"]
    with pytest.raises(rp.PackError, match="no mapping row"):
        rp.build(wl3_shaped_rom(), mapping, 0, movement())


def test_spawn_outside_the_room_stops_the_build():
    # Section (1, 1) is scanned downward; a marker below row 31 is outside the room.
    with pytest.raises(rp.PackError, match="outside room 1"):
        rp.build(wl3_shaped_rom(spawn=(20, 40)), bm.load_mapping(), 0, movement())


def test_identical_behaviour_shares_a_character():
    blocks = [{"material": "solid", "flags": ["breakable-cracked"], "replacement_block": 120}] * 2 + \
             [{"material": "empty", "flags": []}]
    char_of, legend, approximations = rp.legend_for(blocks, [2, 1, 0, 1])
    assert char_of == {0: "A", 1: "A", 2: "."} and len(approximations) == 1
    assert legend == {".": "empty", "A": "solid"}


def test_extract_writes_a_valid_read_only_pack(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    with pytest.raises(UnknownRomError):
        rp.extract(rom_path, tmp_path / "refused")
    first = rp.extract(rom_path, tmp_path / "packs", exploratory=True)
    second = rp.extract(rom_path, tmp_path / "packs", exploratory=True)
    assert first["changed"] and not second["changed"]
    pack_dir = tmp_path / "packs" / "exploratory" / "wl3-level-00-room-001"
    loaded = content.load_pack(pack_dir)
    assert loaded["pack"]["approximations"] == first["pack"]["approximations"]
    for name in ("pack.json", "movement.json", "rooms/room-001.json", "provenance.json"):
        assert not ((pack_dir / name).stat().st_mode & 0o222), f"{name} is read-only"
    provenance = json.loads((pack_dir / "provenance.json").read_text())
    assert provenance["marker"] == ROM_DERIVED_MARKER and provenance["exploratory"] is True
    assert provenance["spawn_block"] == [20, 30]
