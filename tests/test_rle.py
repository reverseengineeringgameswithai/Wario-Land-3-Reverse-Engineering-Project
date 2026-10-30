import pytest

from synthetic_rom import build_rom
from wl3pc.address import BankedAddress, RomView
from wl3pc.extract.rle import DecompressError, decompress


def view_with(offset: int, data: bytes, size: int = 0x8000) -> RomView:
    return RomView(bytes(build_rom(size=size, patches={offset: data})))


def test_runs_literals_and_terminator():
    view = view_with(0x4100, bytes([0x03, 0xAA, 0x82, 0x01, 0x02, 0x00, 0x99]))
    output, compressed = decompress(view, BankedAddress(1, 0x4100), capacity=0x10)
    assert output == bytes([0xAA, 0xAA, 0xAA, 0x01, 0x02])
    assert compressed == 6  # the byte after the terminator is not read


def test_literal_count_zero_copies_256_bytes():
    # Decompress counts literals with `dec d / jr nz`, so control $80 wraps to 256.
    literal = bytes(range(256))
    view = view_with(0x4100, bytes([0x80]) + literal + bytes([0x00]))
    output, compressed = decompress(view, BankedAddress(1, 0x4100), capacity=0x100)
    assert output == literal
    assert compressed == 258


def test_rejects_stream_running_off_the_bank():
    view = view_with(0x7FFE, bytes([0x02, 0x55]))
    with pytest.raises(DecompressError, match="not terminated"):
        decompress(view, BankedAddress(1, 0x7FFE), capacity=0x10)


def test_rejects_rom0_stream_running_into_romx():
    view = view_with(0x3FFF, bytes([0x81]))
    with pytest.raises(DecompressError, match="end of bank 00"):
        decompress(view, BankedAddress(0, 0x3FFF), capacity=0x10)


def test_rejects_output_overflow():
    view = view_with(0x4100, bytes([0x7F, 0x00, 0x00]))
    with pytest.raises(DecompressError, match="overflows"):
        decompress(view, BankedAddress(1, 0x4100), capacity=0x7E)


def test_rejects_stream_outside_rom_image():
    with pytest.raises(DecompressError, match="exceeds ROM size"):
        decompress(view_with(0x4100, b"\x00"), BankedAddress(2, 0x4000), capacity=0x10)
