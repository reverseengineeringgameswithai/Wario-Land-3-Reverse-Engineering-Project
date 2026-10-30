import pytest

from wl3pc.address import AddressError, BankedAddress, RomBoundsError, RomView


@pytest.mark.parametrize(
    ("bank", "address", "offset"),
    [(0x00, 0x0150, 0x0150), (0x01, 0x4000, 0x4000), (0x32, 0x4000, 0xC8000), (0x50, 0x40C4, 0x1400C4), (0x7F, 0x7FFF, 0x1FFFFF)],
)
def test_round_trip(bank, address, offset):
    location = BankedAddress(bank, address)
    assert location.file_offset == offset
    assert BankedAddress.from_file_offset(offset) == location


def test_parse_and_format():
    assert BankedAddress.parse("32:40c4") == BankedAddress(0x32, 0x40C4)
    assert str(BankedAddress(6, 0x4032)) == "06:4032"
    with pytest.raises(AddressError):
        BankedAddress.parse("32-40c4")


@pytest.mark.parametrize(("bank", "address"), [(0, 0x4000), (1, 0x3FFF), (1, 0x8000), (-1, 0x4000), (0x200, 0x4000)])
def test_invalid_addresses(bank, address):
    with pytest.raises(AddressError):
        BankedAddress(bank, address)


def test_pointer_resolution_keeps_rom0():
    here = BankedAddress(6, 0x4000)
    assert here.in_same_bank(0x0028) == BankedAddress(0, 0x0028)
    assert here.in_same_bank(0x4032) == BankedAddress(6, 0x4032)


def test_bounds_checked_reads():
    view = RomView(bytes(range(256)) * 0x100)  # 64 KiB, four banks
    assert view.u16le(BankedAddress(1, 0x4000)) == 0x0100
    with pytest.raises(RomBoundsError):
        view.read(0xFFFF, 2)
    with pytest.raises(RomBoundsError, match="cross the end of bank"):
        view.read_banked(BankedAddress(1, 0x7FFF), 2)
