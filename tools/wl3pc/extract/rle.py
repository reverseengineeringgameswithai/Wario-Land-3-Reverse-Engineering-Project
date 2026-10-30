"""Bounded model of the original run-length decoder.

Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the
identified ROM): `Decompress` (00:0909, src/home/decompress.asm) reads a
control byte at hl. $00 ends the stream. With bit 7 clear, the next byte is
written `control` times. With bit 7 set, `control & $7f` literal bytes follow.
The literal loop is `dec d / jr nz`, so a count of 0 (control $80) copies 256
bytes. The original has no output limit and reads past $7fff into VRAM; this
model refuses both instead of guessing.
"""

from __future__ import annotations

from ..address import ROMX_END, ROMX_START, BankedAddress, RomBoundsError, RomView


class DecompressError(ValueError):
    """A stream leaves its bank or overflows its destination buffer."""


def decompress(view: RomView, start: BankedAddress, capacity: int) -> tuple[bytes, int]:
    """Return (output, compressed length including the terminator)."""
    end = ROMX_START if start.bank == 0 else ROMX_END
    cursor = start.address
    output = bytearray()

    def take() -> int:
        nonlocal cursor
        if cursor >= end:
            raise DecompressError(f"stream from {start} is not terminated before the end of bank {start.bank:02x}")
        try:
            value = view.u8(BankedAddress(start.bank, cursor))
        except RomBoundsError as error:
            raise DecompressError(f"stream from {start}: {error}") from error
        cursor += 1
        return value

    while True:
        control = take()
        if control == 0:
            return bytes(output), cursor - start.address
        if control & 0x80:
            count = (control & 0x7F) or 0x100
            output.extend(take() for _ in range(count))
        else:
            output.extend([take()] * control)
        if len(output) > capacity:
            raise DecompressError(f"stream from {start} overflows its {capacity:#x}-byte destination")
