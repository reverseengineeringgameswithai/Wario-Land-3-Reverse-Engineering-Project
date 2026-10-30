"""Game Boy banked-address helpers for MBC5 cartridges.

Conventions follow RGBDS symbol files: bank 00 is ROM0 at $0000-$3FFF and
switchable banks 01+ appear at $4000-$7FFF. The conversion rule is from Pan
Docs (MBC5) and was checked against the identified ROM: the reference-build
symbol 32:4000 BlockFunctionTablePointers decodes to the expected pointers at
file offset 0xC8000. See docs/02-research/rom-identity.md.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

BANK_SIZE = 0x4000
ROMX_START = 0x4000
ROMX_END = 0x8000  # exclusive

_BANKED_RE = re.compile(r"^([0-9A-Fa-f]{1,3}):([0-9A-Fa-f]{1,4})$")


class AddressError(ValueError):
    """An address is outside the cartridge ROM address space."""


class RomBoundsError(ValueError):
    """A read would fall outside the ROM image."""


@dataclass(frozen=True, order=True)
class BankedAddress:
    bank: int
    address: int

    def __post_init__(self) -> None:
        if self.bank < 0 or self.bank > 0x1FF:
            raise AddressError(f"bank {self.bank:#x} is outside the MBC5 range 0x000-0x1FF")
        if self.bank == 0:
            if not 0 <= self.address < ROMX_START:
                raise AddressError(f"bank 00 address {self.address:#06x} is outside ROM0 ($0000-$3FFF)")
        elif not ROMX_START <= self.address < ROMX_END:
            raise AddressError(
                f"bank {self.bank:02x} address {self.address:#06x} is outside ROMX ($4000-$7FFF)"
            )

    @property
    def file_offset(self) -> int:
        if self.bank == 0:
            return self.address
        return self.bank * BANK_SIZE + (self.address - ROMX_START)

    def __str__(self) -> str:
        return f"{self.bank:02x}:{self.address:04x}"

    @classmethod
    def parse(cls, text: str) -> "BankedAddress":
        match = _BANKED_RE.match(text.strip())
        if not match:
            raise AddressError(f"expected BANK:ADDR in hex, got {text!r}")
        return cls(int(match.group(1), 16), int(match.group(2), 16))

    @classmethod
    def from_file_offset(cls, offset: int) -> "BankedAddress":
        if offset < 0:
            raise AddressError(f"negative file offset {offset}")
        bank, within = divmod(offset, BANK_SIZE)
        return cls(bank, within if bank == 0 else ROMX_START + within)

    def in_same_bank(self, address: int) -> "BankedAddress":
        """Resolve a 16-bit pointer read from this bank's code or data.

        Pointers below $4000 refer to ROM0, which is always mapped.
        """
        if 0 <= address < ROMX_START:
            return BankedAddress(0, address)
        return BankedAddress(self.bank, address)


class RomView:
    """Bounds-checked little-endian reads over an immutable ROM image."""

    def __init__(self, data: bytes) -> None:
        self._data = bytes(data)

    def __len__(self) -> int:
        return len(self._data)

    def _check(self, offset: int, length: int) -> None:
        if offset < 0 or length < 0 or offset + length > len(self._data):
            raise RomBoundsError(
                f"read of {length} byte(s) at file offset {offset:#x} exceeds ROM size {len(self._data):#x}"
            )

    def u8(self, where: BankedAddress | int) -> int:
        offset = where.file_offset if isinstance(where, BankedAddress) else where
        self._check(offset, 1)
        return self._data[offset]

    def u16le(self, where: BankedAddress | int) -> int:
        offset = where.file_offset if isinstance(where, BankedAddress) else where
        self._check(offset, 2)
        return self._data[offset] | (self._data[offset + 1] << 8)

    def read(self, where: BankedAddress | int, length: int) -> bytes:
        offset = where.file_offset if isinstance(where, BankedAddress) else where
        self._check(offset, length)
        return self._data[offset : offset + length]

    def read_banked(self, start: BankedAddress, length: int) -> bytes:
        """Read a span that must not cross the end of its bank."""
        limit = ROMX_START if start.bank == 0 else ROMX_END
        if start.address + length > limit:
            raise RomBoundsError(f"{length} byte(s) from {start} would cross the end of bank {start.bank:02x}")
        return self.read(start, length)
