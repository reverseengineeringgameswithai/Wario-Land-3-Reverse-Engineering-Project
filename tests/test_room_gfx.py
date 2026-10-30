"""Room graphics decoding on invented data (no ROM bytes)."""

import pytest

from wl3pc import png
from wl3pc.extract import room_gfx as rg


def tile(rows: list[tuple[int, int]]) -> bytes:
    """A tile from (low plane, high plane) byte pairs, one per row."""
    return b"".join(bytes(pair) for pair in rows)


def test_a_tile_pixel_takes_its_low_bit_from_the_first_plane():
    data = tile([(0b10000001, 0b11000000)] + [(0, 0)] * 7)
    pixels = rg.decode_tile(data)
    assert pixels[:8] == [3, 2, 0, 0, 0, 0, 0, 1]
    assert set(pixels[8:]) == {0}


def test_palette_words_are_little_endian_with_red_lowest():
    # colour 0: red 31; colour 1: green 31; colour 2: blue 31; colour 3: (1, 2, 3)
    words = [0x001F, 0x03E0, 0x7C00, 1 | (2 << 5) | (3 << 10)]
    data = b"".join(w.to_bytes(2, "little") for w in words) + bytes(56)
    palettes = rg.decode_palettes(data)
    assert palettes[0] == [[31, 0, 0], [0, 31, 0], [0, 0, 31], [1, 2, 3]]
    assert len(palettes) == 8 and palettes[7] == [[0, 0, 0]] * 4


def document(attributes: bytes) -> dict:
    """Block 0 uses tile 1 in all four positions with the given attributes."""
    main = bytearray(rg.TILES_PER_SET * rg.TILE_BYTES)
    special = bytearray(rg.TILES_PER_SET * rg.TILE_BYTES)
    # main tile 1: colour 1 in the top-left pixel only; special tile 1: colour 2 everywhere
    main[16:32] = tile([(0b10000000, 0)] + [(0, 0)] * 7)
    special[16:32] = tile([(0, 0xFF)] * 8)
    palettes = [[[p, 0, 0], [p, 1, 0], [p, 2, 0], [p, 3, 0]] for p in range(8)]
    return {"block_tiles": (bytes([1, 1, 1, 1]) + bytes(508)).hex(),
            "block_attributes": (attributes + bytes(508)).hex(),
            "main_tiles": bytes(main).hex(), "special_tiles": bytes(special).hex(), "palettes": palettes}


def test_a_blocks_tiles_go_top_left_top_right_bottom_left_bottom_right():
    pixels = rg.block_pixels(document(bytes([0, 1, 2, 3])), 0)
    # each quarter's top-left pixel is colour 1 of the palette its attribute names
    assert [pixels[0], pixels[8], pixels[8 * 16], pixels[8 * 16 + 8]] == [(0, 1, 0), (1, 1, 0), (2, 1, 0), (3, 1, 0)]
    assert pixels[1] == (0, 0, 0)


def test_attributes_flip_and_select_the_vram_bank():
    flipped = rg.block_pixels(document(bytes([0x20, 0x40, 0x60, 0x08])), 0)
    assert flipped[7] == (0, 1, 0), "X flip moves the pixel to the right edge"
    assert flipped[7 * 16 + 8] == (0, 1, 0), "Y flip moves it to the bottom row"
    assert flipped[15 * 16 + 7] == (0, 1, 0), "both flips move it to the bottom-right corner of its tile"
    assert flipped[8 * 16 + 8] == (0, 2, 0), "bank 1 reads the special tile"


def test_tiles_outside_the_rooms_sets_are_left_unknown():
    doc = document(bytes(4))
    doc["block_tiles"] = (bytes([0x80, 1, 1, 1]) + bytes(508)).hex()
    pixels = rg.block_pixels(doc, 0)
    assert pixels[0] is None and pixels[8] == (0, 1, 0)


def test_png_round_trip_and_checks():
    pixels = bytes(range(2 * 3 * 3)) + bytes(2 * 3 * 3)
    data = png.encode_rgb(3, 4, pixels[:3 * 4 * 3])
    assert png.decode_rgb(data) == (3, 4, pixels[:3 * 4 * 3])
    with pytest.raises(ValueError, match="CRC"):
        png.decode_rgb(data[:-5] + b"\x00" + data[-4:])
    with pytest.raises(ValueError):
        png.encode_rgb(2, 2, b"\x00" * 5)


def test_an_animated_document_swaps_tiles_70_to_77_and_the_palettes():
    from wl3pc.oracle_screen import animated_document

    special = bytes(rg.TILES_PER_SET * rg.TILE_BYTES)
    frames = bytes(range(256)) * 2  # 4 frames of 8 tiles
    room = {"special_tiles": special.hex(), "palettes": [[[0, 0, 0]] * 4] * 8}
    animation = {"animated_tiles_gfx": {"3": frames.hex()}, "room_pals": {"9": [[[1, 1, 1]] * 4] * 8}}
    same = animated_document(room, animation, -1, 0, -1)
    assert same == room
    moved = animated_document(room, animation, 3, 2, 9)
    tiles = bytes.fromhex(moved["special_tiles"])
    start = 0x70 * rg.TILE_BYTES
    assert tiles[start:start + 0x80] == frames[0x100:0x180] and tiles[:start] == special[:start]
    assert moved["palettes"][0][0] == [1, 1, 1] and room["palettes"][0][0] == [0, 0, 0]
