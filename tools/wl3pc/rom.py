"""Read-only Game Boy / Game Boy Color cartridge inspection.

Header layout and checksum algorithms follow Pan Docs, "The Cartridge Header"
(https://gbdev.io/pandocs/The_Cartridge_Header.html). Header validity is
reported separately from revision identity: a well-formed header says nothing
about which dump this is, and only an exact SHA-256 match against
known_roms.KNOWN_ROMS establishes a verified revision.
"""

from __future__ import annotations

import hashlib
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

from .known_roms import KNOWN_ROMS, LOGO_SHA256, KnownRom

HEADER_END = 0x150
MIN_ROM_SIZE = 0x8000

CARTRIDGE_TYPES = {
    0x00: "ROM ONLY", 0x01: "MBC1", 0x02: "MBC1+RAM", 0x03: "MBC1+RAM+BATTERY",
    0x05: "MBC2", 0x06: "MBC2+BATTERY", 0x08: "ROM+RAM", 0x09: "ROM+RAM+BATTERY",
    0x0B: "MMM01", 0x0C: "MMM01+RAM", 0x0D: "MMM01+RAM+BATTERY",
    0x0F: "MBC3+TIMER+BATTERY", 0x10: "MBC3+TIMER+RAM+BATTERY", 0x11: "MBC3",
    0x12: "MBC3+RAM", 0x13: "MBC3+RAM+BATTERY", 0x19: "MBC5", 0x1A: "MBC5+RAM",
    0x1B: "MBC5+RAM+BATTERY", 0x1C: "MBC5+RUMBLE", 0x1D: "MBC5+RUMBLE+RAM",
    0x1E: "MBC5+RUMBLE+RAM+BATTERY", 0x20: "MBC6", 0x22: "MBC7+SENSOR+RUMBLE+RAM+BATTERY",
    0xFC: "POCKET CAMERA", 0xFD: "BANDAI TAMA5", 0xFE: "HuC3", 0xFF: "HuC1+RAM+BATTERY",
}
RAM_SIZES = {0x00: 0, 0x02: 8 * 1024, 0x03: 32 * 1024, 0x04: 128 * 1024, 0x05: 64 * 1024}
CGB_FLAGS = {0x80: "CGB enhanced (DMG compatible)", 0xC0: "CGB only"}


class RomFormatError(ValueError):
    """The file cannot be a Game Boy cartridge image."""


class UnknownRomError(RuntimeError):
    """Revision-dependent work was requested for an unidentified ROM."""


@dataclass(frozen=True)
class Hashes:
    md5: str
    sha1: str
    sha256: str

    @classmethod
    def of(cls, data: bytes) -> "Hashes":
        return cls(
            md5=hashlib.md5(data).hexdigest(),
            sha1=hashlib.sha1(data).hexdigest(),
            sha256=hashlib.sha256(data).hexdigest(),
        )


@dataclass(frozen=True)
class Header:
    entry_point_hex: str
    logo_matches_boot_logo: bool
    title: str
    manufacturer_code: str
    cgb_flag: int
    cgb_mode: str
    new_licensee_code: str
    sgb_flag: int
    cartridge_type: int
    cartridge_type_name: str
    rom_size_code: int
    rom_size_declared: int | None
    ram_size_code: int
    ram_size_declared: int | None
    destination_code: int
    destination: str
    old_licensee_code: int
    mask_rom_version: int
    header_checksum_stored: int
    header_checksum_computed: int
    global_checksum_stored: int
    global_checksum_computed: int

    @property
    def header_checksum_valid(self) -> bool:
        return self.header_checksum_stored == self.header_checksum_computed

    @property
    def global_checksum_valid(self) -> bool:
        return self.global_checksum_stored == self.global_checksum_computed


@dataclass(frozen=True)
class Identity:
    status: str  # "verified" or "unknown"
    rom_id: str | None = None
    name: str | None = None
    evidence: tuple[str, ...] = ()


@dataclass(frozen=True)
class RomReport:
    path: str
    size: int
    hashes: Hashes
    header: Header
    identity: Identity
    warnings: tuple[str, ...] = field(default=())

    def to_dict(self) -> dict[str, Any]:
        header = asdict(self.header)
        header["header_checksum_valid"] = self.header.header_checksum_valid
        header["global_checksum_valid"] = self.header.global_checksum_valid
        return {
            "path": self.path,
            "size": self.size,
            "hashes": asdict(self.hashes),
            "header": header,
            "identity": {
                "status": self.identity.status,
                "rom_id": self.identity.rom_id,
                "name": self.identity.name,
                "evidence": list(self.identity.evidence),
            },
            "extraction_allowed": self.identity.status == "verified",
            "warnings": list(self.warnings),
        }


def header_checksum(data: bytes) -> int:
    value = 0
    for byte in data[0x134:0x14D]:
        value = (value - byte - 1) & 0xFF
    return value


def global_checksum(data: bytes) -> int:
    return (sum(data) - data[0x14E] - data[0x14F]) & 0xFFFF


def parse_header(data: bytes) -> Header:
    if len(data) < HEADER_END:
        raise RomFormatError(f"file is {len(data)} bytes; a cartridge header needs at least {HEADER_END:#x}")
    cgb_flag = data[0x143]
    # Titles on CGB carts may be 11 bytes followed by a manufacturer code.
    title_end = 0x13F if cgb_flag in CGB_FLAGS else 0x144
    title = data[0x134:title_end].split(b"\x00", 1)[0].decode("ascii", errors="replace")
    rom_code = data[0x148]
    ram_code = data[0x149]
    return Header(
        entry_point_hex=data[0x100:0x104].hex(),
        logo_matches_boot_logo=hashlib.sha256(data[0x104:0x134]).hexdigest() == LOGO_SHA256,
        title=title,
        manufacturer_code=data[0x13F:0x143].decode("ascii", errors="replace") if cgb_flag in CGB_FLAGS else "",
        cgb_flag=cgb_flag,
        cgb_mode=CGB_FLAGS.get(cgb_flag, "DMG (no CGB flag)"),
        new_licensee_code=data[0x144:0x146].decode("ascii", errors="replace"),
        sgb_flag=data[0x146],
        cartridge_type=data[0x147],
        cartridge_type_name=CARTRIDGE_TYPES.get(data[0x147], "unknown"),
        rom_size_code=rom_code,
        rom_size_declared=(0x8000 << rom_code) if rom_code <= 0x08 else None,
        ram_size_code=ram_code,
        ram_size_declared=RAM_SIZES.get(ram_code),
        destination_code=data[0x14A],
        destination={0x00: "Japan (and possibly overseas)", 0x01: "Overseas only"}.get(data[0x14A], "unknown"),
        old_licensee_code=data[0x14B],
        mask_rom_version=data[0x14C],
        header_checksum_stored=data[0x14D],
        header_checksum_computed=header_checksum(data),
        global_checksum_stored=int.from_bytes(data[0x14E:0x150], "big"),
        global_checksum_computed=global_checksum(data),
    )


def identify(hashes: Hashes, size: int, known: tuple[KnownRom, ...] = KNOWN_ROMS) -> Identity:
    for rom in known:
        if rom.sha256 == hashes.sha256 and rom.size == size:
            return Identity("verified", rom.rom_id, rom.name, rom.evidence)
    return Identity("unknown")


def inspect_bytes(data: bytes, path: str = "<memory>", known: tuple[KnownRom, ...] = KNOWN_ROMS) -> RomReport:
    header = parse_header(data)
    hashes = Hashes.of(data)
    warnings: list[str] = []
    if len(data) < MIN_ROM_SIZE:
        warnings.append(f"size {len(data)} is smaller than the minimum 32 KiB cartridge")
    if header.rom_size_declared is None:
        warnings.append(f"unrecognised ROM size code {header.rom_size_code:#04x}")
    elif header.rom_size_declared != len(data):
        warnings.append(f"header declares {header.rom_size_declared} bytes but file has {len(data)}")
    if not header.logo_matches_boot_logo:
        warnings.append("logo region does not match the boot ROM logo")
    if not header.header_checksum_valid:
        warnings.append("header checksum mismatch (real hardware would refuse to boot)")
    if not header.global_checksum_valid:
        warnings.append("global checksum mismatch (not checked by hardware)")
    return RomReport(path, len(data), hashes, header, identify(hashes, len(data), known), tuple(warnings))


def read_rom(path: Path) -> bytes:
    """Read a ROM image without modifying it."""
    with open(path, "rb") as handle:
        return handle.read()


def inspect_file(path: Path, known: tuple[KnownRom, ...] = KNOWN_ROMS) -> RomReport:
    return inspect_bytes(read_rom(path), str(path), known)


def require_known(report: RomReport, rom_id: str, exploratory: bool = False) -> None:
    """Gate revision-dependent work. Exploratory mode must be explicit."""
    if report.identity.status == "verified" and report.identity.rom_id == rom_id:
        return
    if exploratory:
        return
    found = report.identity.rom_id or "unidentified"
    raise UnknownRomError(
        f"{report.path}: expected verified revision {rom_id!r}, found {found} "
        f"(sha256 {report.hashes.sha256}). Revision-dependent extraction is refused; "
        "pass --exploratory to run anyway with outputs marked exploratory."
    )
