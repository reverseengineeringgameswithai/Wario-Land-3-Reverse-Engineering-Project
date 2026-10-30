"""Wario's sprite decoding and the sprite check's helpers on invented data (no ROM bytes)."""

import pytest

from synthetic_rom import build_rom
from test_rooms import at
from wl3pc import png
from wl3pc.address import BankedAddress
from wl3pc.extract import room_gfx
from wl3pc.extract import wario_sprites as ws
from wl3pc.extract.block_functions import MalformedDataError
from wl3pc.oracle_screen import drawn, wario_oam_entries

# A miniature layout over a 64 KiB synthetic ROM: one tile set, one OAM table of two frames, one palette.
LAYOUT = ws.SpriteLayout(
    rom_id="synthetic",
    tile_sets=(("TestGfx", BankedAddress(1, 0x4000)),),
    oam_tables=(("OAM_test", BankedAddress(2, 0x4000)),),
    palettes=(("TestPal", BankedAddress(3, 0x4800)),),
)


def tiles() -> bytes:
    """Tile 0: colour 1 in its top-left pixel; tile 1: colour 3 in its bottom-right pixel."""
    data = bytearray(ws.TILES_PER_SET * room_gfx.TILE_BYTES)
    data[0] = 0x80
    data[16 + 14] = data[16 + 15] = 0x01
    return bytes(data)


def synthetic(extra=None) -> bytes:
    patches = {
        at(1, 0x4000): tiles(),
        # two frame pointers, then the frames: (y, x, tile, attributes) entries ending in $80
        at(2, 0x4000): bytes([0x04, 0x40, 0x0D, 0x40]),
        at(2, 0x4004): bytes([0xF0, 0xF8, 0x00, 0x00, 0xF0, 0x00, 0x00, 0x20, 0x80]),
        at(2, 0x400D): bytes([0x80]),
        # palette 0: red, green, blue on clear; palette 1: greys
        at(3, 0x4800): b"".join(w.to_bytes(2, "little") for w in
                                (0, 0x001F, 0x03E0, 0x7C00, 0, 1 | 1 << 5 | 1 << 10, 2 | 2 << 5 | 2 << 10, 3 | 3 << 5 | 3 << 10)),
    }
    patches.update(extra or {})
    return bytes(build_rom(size=0x10000, patches=patches))


def test_tables_end_where_the_lowest_frame_pointer_points():
    document = ws.decode(synthetic(), LAYOUT)
    assert document["oam_tables"]["02:4000"] == {
        "name": "OAM_test", "frames": [[[-16, -8, 0, 0], [-16, 0, 0, 0x20]], []]}
    assert document["palettes"]["03:4800"]["colours"][0] == [[0, 0, 0], [31, 0, 0], [0, 31, 0], [0, 0, 31]]
    assert bytes.fromhex(document["tile_sets"]["01:4000"]["tiles"]) == tiles()


def test_a_frame_without_terminator_is_refused():
    unterminated = synthetic({at(2, 0x400D): bytes([0x10, 0x10, 0x00, 0x00] * 42)})
    with pytest.raises(MalformedDataError, match="no \\$80 terminator"):
        ws.decode(unterminated, LAYOUT)


def test_a_pointer_outside_the_bank_is_refused():
    with pytest.raises(MalformedDataError, match="points to"):
        ws.decode(synthetic({at(2, 0x4002): bytes([0x00, 0x80])}), LAYOUT)


def test_sprite_pixels_stack_8x16_pairs_flip_them_and_keep_the_first_entry_on_top():
    document = ws.decode(synthetic(), LAYOUT)
    pixels = ws.sprite_pixels(document, "01:4000", "02:4000", 0, "03:4800")
    # entry 0 at (-8, -16): tile 0's pixel at its top-left, tile 1's at the pair's bottom-right
    assert pixels[(-8, -16)] == (31, 0, 0)
    assert pixels[(-1, -1)] == (0, 0, 31)
    # entry 1 is X-flipped at (0, -16): its pixels move to the other side of the pair
    assert pixels[(7, -16)] == (31, 0, 0)
    assert pixels[(0, -1)] == (0, 0, 31)
    assert len(pixels) == 4
    flipped = ws.sprite_pixels(document, "01:4000", "02:4000", 0, "03:4800", attributes=0x41)
    assert flipped[(-8, -1)] == (1, 1, 1), "wWarioAttributes is XORed: Y flip and OBJ palette 1"


def test_entries_in_vram_bank_1_or_beyond_wario_palettes_are_refused():
    document = ws.decode(synthetic(), LAYOUT)
    with pytest.raises(MalformedDataError, match="VRAM bank 1"):
        ws.sprite_pixels(document, "01:4000", "02:4000", 0, "03:4800", attributes=0x08)
    with pytest.raises(MalformedDataError, match="OBJ palette 2"):
        ws.sprite_pixels(document, "01:4000", "02:4000", 0, "03:4800", attributes=0x02)


def draw(**values):
    base = {"wWarioOAMBank": 2, "wWarioOAMPtr": 0x4000, "wWarioFrame": 0, "wWarioScreenYPos": 100,
            "wWarioScreenXPos": 4, "wWarioAttributes": 0, "wInvisibleFrame": 0, "wTransformation": 0}
    base.update(values)
    return base


def test_the_check_predicts_loadsprites_oam_bytes():
    document = ws.decode(synthetic(), LAYOUT)
    assert wario_oam_entries(document, draw()) == [[84, 252, 0, 0], [84, 4, 0, 0x20]]
    assert wario_oam_entries(document, draw(wWarioOAMPtr=0x5000)) is None
    assert wario_oam_entries(document, draw(wWarioFrame=2)) is None


def test_the_check_follows_draw_warios_visibility():
    assert drawn(draw()) and not drawn(draw(wInvisibleFrame=1))
    # Invisible Wario: DrawWario increments first, then needs the upper 4 bits set and bit 2 clear.
    assert [f for f in range(256) if drawn(draw(wTransformation=0x06, wInvisibleFrame=f))] == [
        0xEF, 0xF0, 0xF3, 0xF4, 0xF7, 0xF8, 0xFB, 0xFC]


def test_priority_sheet_keeps_only_priority_pixels_with_a_colour():
    main = bytearray(room_gfx.TILES_PER_SET * room_gfx.TILE_BYTES)
    main[16:32] = bytes([0x80, 0x00] + [0x00] * 14)  # tile 1: colour 1 at its top-left only
    document = {"block_tiles": (bytes([1, 1, 1, 1]) + bytes(508)).hex(),
                "block_attributes": (bytes([0x80, 0, 0, 0]) + bytes(508)).hex(),
                "main_tiles": bytes(main).hex(), "special_tiles": bytes(len(main)).hex(),
                "palettes": [[[0, 0, 0], [31, 31, 31], [0, 0, 0], [0, 0, 0]]] * 8}
    info = room_gfx.block_pixel_info(document, 0)
    assert info[0] == ((31, 31, 31), 1, True) and info[1] == ((0, 0, 0), 0, True) and info[8][2] is False
    data = room_gfx.priority_png(document)
    assert data.startswith(png.SIGNATURE) and data[25] == 6, "an RGBA PNG"


def test_object_entries_come_from_the_table_of_the_ids_bank_at_the_slots_screen_position():
    from wl3pc.oracle_screen import drawn_object_slots, object_oam_entries

    tables = {"62:4000": [[[-16, -8, 4, 0x0C]], [[-8, 0, 6, 0x2C]]]}
    slot = bytearray(32)
    slot[0x00] = 0x83  # active, on screen, priority
    slot[0x07] = 0x25  # ID: bits 4-6 pick bank $60 + 2
    slot[0x0D], slot[0x0E], slot[0x0F] = 100, 4, 1  # screen y, x; frame 1
    slot[0x10], slot[0x11] = 0x00, 0x40
    assert object_oam_entries(tables, bytes(slot)) == [[92, 4, 6, 0x2C]]
    slot[0x0F] = 2
    assert object_oam_entries(tables, bytes(slot)) is None
    hidden, behind = bytearray(slot), bytearray(slot)
    hidden[0] |= 0x10  # invisible
    behind[0] = 0x03  # no priority
    slots = bytes(slot) + bytes(hidden) + bytes(behind) + bytes(32 * 5)
    assert drawn_object_slots(slots, True) == [bytes(slot)]
    assert drawn_object_slots(slots, False) == [bytes(behind)]
