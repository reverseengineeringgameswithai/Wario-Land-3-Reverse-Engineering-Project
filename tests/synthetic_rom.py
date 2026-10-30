"""Build synthetic cartridge images for tests.

Contains no original bytes: the logo region is a counting pattern, so the
"logo matches" path is exercised by patching the expected hash instead.
"""

from __future__ import annotations

FAKE_LOGO = bytes(range(0x30))


def build_rom(
    size: int = 0x8000,
    title: bytes = b"SYNTHTEST",
    cgb_flag: int = 0xC0,
    cart_type: int = 0x1B,
    ram_code: int = 0x03,
    fill: int = 0x00,
    patches: dict[int, bytes] | None = None,
    fix_checksums: bool = True,
) -> bytearray:
    rom = bytearray([fill]) * size
    rom[0x100:0x104] = bytes([0x00, 0xC3, 0x50, 0x01])
    rom[0x104:0x134] = FAKE_LOGO
    rom[0x134:0x13F] = title.ljust(11, b"\x00")[:11]
    rom[0x13F:0x143] = b"TEST"
    rom[0x143] = cgb_flag
    rom[0x144:0x146] = b"00"
    rom[0x147] = cart_type
    size_code = (size // 0x8000).bit_length() - 1 if size >= 0x8000 else 0xFF
    rom[0x148] = size_code
    rom[0x149] = ram_code
    rom[0x14A] = 0x01
    for offset, data in (patches or {}).items():
        rom[offset : offset + len(data)] = data
    if fix_checksums:
        fix(rom)
    return rom


def fix(rom: bytearray) -> bytearray:
    checksum = 0
    for byte in rom[0x134:0x14D]:
        checksum = (checksum - byte - 1) & 0xFF
    rom[0x14D] = checksum
    total = (sum(rom) - rom[0x14E] - rom[0x14F]) & 0xFFFF
    rom[0x14E:0x150] = total.to_bytes(2, "big")
    return rom
