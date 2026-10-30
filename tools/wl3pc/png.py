"""Minimal PNG writing and reading (8-bit RGB or RGBA, no interlace), standard library only.

Used for previews of decoded graphics in ignored local/content and for comparisons; not a
general PNG library. Reading accepts only what write_rgb produces (filter type 0).
"""

from __future__ import annotations

import struct
import zlib
from pathlib import Path

SIGNATURE = b"\x89PNG\r\n\x1a\n"


def _chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def encode_rgb(width: int, height: int, pixels: bytes) -> bytes:
    """PNG bytes for `pixels`: width * height RGB triples, row by row."""
    if len(pixels) != width * height * 3:
        raise ValueError(f"expected {width * height * 3} bytes of RGB, got {len(pixels)}")
    rows = b"".join(b"\x00" + pixels[y * width * 3:(y + 1) * width * 3] for y in range(height))
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return SIGNATURE + _chunk(b"IHDR", header) + _chunk(b"IDAT", zlib.compress(rows, 9)) + _chunk(b"IEND", b"")


def encode_rgba(width: int, height: int, pixels: bytes) -> bytes:
    """PNG bytes for `pixels`: width * height RGBA quadruples, row by row (alpha 0 is transparent)."""
    if len(pixels) != width * height * 4:
        raise ValueError(f"expected {width * height * 4} bytes of RGBA, got {len(pixels)}")
    rows = b"".join(b"\x00" + pixels[y * width * 4:(y + 1) * width * 4] for y in range(height))
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return SIGNATURE + _chunk(b"IHDR", header) + _chunk(b"IDAT", zlib.compress(rows, 9)) + _chunk(b"IEND", b"")


def write_rgb(path: Path, width: int, height: int, pixels: bytes) -> bytes:
    data = encode_rgb(width, height, pixels)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return data


def decode_rgb(data: bytes) -> tuple[int, int, bytes]:
    """(width, height, RGB pixels) of a PNG written by encode_rgb."""
    if not data.startswith(SIGNATURE):
        raise ValueError("not a PNG")
    offset, width, height, idat = len(SIGNATURE), 0, 0, b""
    while offset < len(data):
        (length,) = struct.unpack(">I", data[offset:offset + 4])
        kind = data[offset + 4:offset + 8]
        body = data[offset + 8:offset + 8 + length]
        if struct.unpack(">I", data[offset + 8 + length:offset + 12 + length])[0] != zlib.crc32(kind + body) & 0xFFFFFFFF:
            raise ValueError(f"bad CRC in {kind!r}")
        if kind == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if (depth, colour, interlace) != (8, 2, 0):
                raise ValueError("only 8-bit RGB without interlace is supported")
        elif kind == b"IDAT":
            idat += body
        offset += 12 + length
    raw = zlib.decompress(idat)
    stride = width * 3 + 1
    if any(raw[y * stride] != 0 for y in range(height)):
        raise ValueError("only filter type 0 is supported")
    return width, height, b"".join(raw[y * stride + 1:(y + 1) * stride] for y in range(height))
