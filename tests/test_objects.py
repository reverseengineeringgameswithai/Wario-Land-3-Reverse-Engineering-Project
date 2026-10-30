"""Object data decoding on invented data (no ROM bytes)."""

import pytest

from synthetic_rom import build_rom
from test_rooms import at
from wl3pc.extract import objects
from wl3pc.extract.block_functions import MalformedDataError


def test_framesets_decode_back_to_back_until_the_padding():
    rom = bytes(build_rom(size=0x10000, patches={
        at(3, 0x4000): bytes([1, 4, 0xFF, 2, 5, 3, 6, 0xFF, 0xFF, 7, 7, 0xFF]),
    }))
    assert objects.decode_framesets(rom, bank=3) == {"4000": [[1, 4]], "4003": [[2, 5], [3, 6]]}


def test_a_frameset_running_off_the_bank_is_refused():
    rom = bytes(build_rom(size=0x10000, patches={at(3, 0x4000): bytes([1, 1] * 0x2000)}))
    with pytest.raises(MalformedDataError, match="no \\$ff terminator|runs past"):
        objects.decode_framesets(rom, bank=3)


def test_object_groups_fill_wobjdatapointers_as_loadobjectgroupdata_does(monkeypatch):
    monkeypatch.setattr(objects, "NUM_OBJECT_GROUPS", 1)
    patches = {
        at(0x19, 0x4004): bytes([0x00, 0x60]),  # ld bc, $6000 (the dummy object)
        at(0x19, 0x5009): bytes([0x00, 0x50, 0x10, 0x50]),  # group 0: common $5000, group $5010
        at(0x19, 0x5000): bytes([0x10, 0x60, 0x20, 0x60, 0x30, 0x60]),  # chest, key, musical coin
        # GFX bank offset 0; four graphics at $4000 of banks $68-$6b; two data pointers; the end mark
        at(0x19, 0x5010): bytes([0x00]) + bytes([0x00, 0x40] * 4) + bytes([0x40, 0x60, 0x48, 0x60, 0xFF, 0xFF]),
        at(0x19, 0x6040): bytes(range(8)),
        at(0x68, 0x4000): bytes([0x02, 0xAB, 0x00]),  # slot 1: two bytes of $ab, then the end
    }
    for bank in (0x69, 0x6A, 0x6B):
        patches[at(bank, 0x4000)] = bytes([0x00])  # empty
    rom = bytes(build_rom(size=0x1B0000, patches=patches))
    groups = objects.decode_object_groups(rom)
    assert groups["groups"][0]["obj_data_pointers"] == ["6010", "6020", "6030", "6040", "6048"] + ["6000"] * 11
    assert groups["object_data"]["6040"] == "0001020304050607"
    assert groups["groups"][0]["enemy_vram"].startswith("abab00")
    # Slot 1 writes its two bytes; the empty slots write nothing (the rest keeps earlier VRAM).
    assert groups["groups"][0]["enemy_vram_written"] == [[0, 2], [0x400, 0x400], [0x800, 0x800], [0xC00, 0xC00]]
