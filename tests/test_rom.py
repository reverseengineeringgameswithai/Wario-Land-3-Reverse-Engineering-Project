import hashlib
import os

import pytest

from synthetic_rom import FAKE_LOGO, build_rom, fix
from wl3pc import rom as rom_module
from wl3pc import rom_info
from wl3pc.known_roms import KnownRom
from wl3pc.rom import RomFormatError, UnknownRomError, Hashes, inspect_bytes, inspect_file, parse_header, require_known


def test_header_fields_and_valid_checksums():
    data = bytes(build_rom(size=0x10000))
    header = parse_header(data)
    assert header.title == "SYNTHTEST"
    assert header.manufacturer_code == "TEST"
    assert header.cgb_mode == "CGB only"
    assert header.cartridge_type_name == "MBC5+RAM+BATTERY"
    assert header.rom_size_declared == 0x10000
    assert header.ram_size_declared == 32 * 1024
    assert header.header_checksum_valid
    assert header.global_checksum_valid
    assert not header.logo_matches_boot_logo


def test_checksum_mismatches_are_reported_separately():
    data = build_rom()
    data[0x14D] ^= 0xFF
    report = inspect_bytes(bytes(data))
    assert not report.header.header_checksum_valid
    assert report.header.global_checksum_valid is False  # stored global sum no longer matches after the edit
    assert any("header checksum" in w for w in report.warnings)


def test_unknown_rom_is_inspectable_but_extraction_is_refused():
    report = inspect_bytes(bytes(build_rom()))
    assert report.identity.status == "unknown"
    assert report.to_dict()["extraction_allowed"] is False
    with pytest.raises(UnknownRomError, match="exploratory"):
        require_known(report, "wl3-world-en-ja")
    require_known(report, "wl3-world-en-ja", exploratory=True)  # explicit opt-in does not raise


def test_identification_requires_exact_sha256_and_size():
    data = bytes(build_rom())
    hashes = Hashes.of(data)
    known = (KnownRom("synthetic", "Synthetic", len(data), hashes.md5, hashes.sha1, hashes.sha256, ("test",)),)
    assert inspect_bytes(data, known=known).identity.status == "verified"
    altered = bytes(fix(bytearray(data[:-1]) + b"\x01"))
    assert inspect_bytes(altered, known=known).identity.status == "unknown"


def test_logo_check_uses_hash(monkeypatch):
    monkeypatch.setattr(rom_module, "LOGO_SHA256", hashlib.sha256(FAKE_LOGO).hexdigest())
    assert parse_header(bytes(build_rom())).logo_matches_boot_logo


def test_size_mismatch_and_truncation():
    data = build_rom(size=0x8000)
    data[0x148] = 0x02  # declares 128 KiB
    fix(data)
    assert any("declares" in w for w in inspect_bytes(bytes(data)).warnings)
    with pytest.raises(RomFormatError):
        parse_header(bytes(0x100))


def test_inspect_file_is_read_only(tmp_path):
    path = tmp_path / "synthetic cart (test).gbc"
    path.write_bytes(bytes(build_rom()))
    os.chmod(path, 0o444)
    before = (path.stat().st_mtime_ns, path.read_bytes())
    report = inspect_file(path)
    assert report.size == 0x8000
    assert (path.stat().st_mtime_ns, path.read_bytes()) == before


def test_cli_exit_codes(tmp_path, capsys):
    path = tmp_path / "cart.gbc"
    path.write_bytes(bytes(build_rom()))
    assert rom_info.main([str(path), "--json"]) == 0
    assert '"status": "unknown"' in capsys.readouterr().out
    assert rom_info.main([str(path), "--require-known"]) == 3
    assert rom_info.main([str(tmp_path / "missing.gbc")]) == 2
    (tmp_path / "tiny.gbc").write_bytes(b"\x00" * 16)
    assert rom_info.main([str(tmp_path / "tiny.gbc")]) == 2
