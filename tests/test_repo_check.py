import hashlib
import random
import subprocess

import pytest

from synthetic_rom import FAKE_LOGO, build_rom
from wl3pc import repo_check
from wl3pc.provenance import ROM_DERIVED_MARKER


def git(root, *args):
    subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True)


@pytest.fixture
def repo(tmp_path):
    root = tmp_path / "repo with space"
    root.mkdir()
    git(root, "init", "-q")
    return root


def stage(root, relative, content):
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content if isinstance(content, bytes) else content.encode())
    git(root, "add", "--", relative)


def reasons(root, roms=()):
    found = {}
    for finding in repo_check.run(root, list(roms)):
        found.setdefault(finding.path, []).append(finding.reason)
    return found


def test_clean_index_with_spaces_passes(repo):
    stage(repo, "docs/notes with space.md", "# Notes\n")
    stage(repo, "docs/.obsidian/app.json", "{}\n")
    stage(repo, "game/scripts/main.gd.uid", "uid://abc\n")
    stage(repo, "game/assets/tile sheet.png", b"\x89PNG\r\n\x1a\n\x00\x00")
    assert reasons(repo) == {}


def test_protected_paths_with_spaces_are_refused(repo):
    stage(repo, "WL3 Editor/ref/level.txt", "Out of the Woods D1= 00\n")
    stage(repo, "Original_ROM/Some Game (World).txt", "placeholder\n")
    stage(repo, "external/some ref/README.md", "x\n")
    stage(repo, "game/.godot/editor/state.cfg", "x\n")
    stage(repo, "docs/.obsidian/workspace.json", "{}\n")
    found = reasons(repo)
    assert set(found) == {
        "WL3 Editor/ref/level.txt", "Original_ROM/Some Game (World).txt", "external/some ref/README.md",
        "game/.godot/editor/state.cfg", "docs/.obsidian/workspace.json",
    }


def test_forbidden_types_binaries_and_marker(repo):
    stage(repo, "notes/a save.sav", "x")
    stage(repo, "tools/__pycache__/x.cpython-314.pyc", "x")
    stage(repo, "assets/blob data.bin", b"abc\x00def")
    stage(repo, "content/derived room.json", '{"marker": "%s"}\n' % ROM_DERIVED_MARKER)
    found = reasons(repo)
    assert "forbidden file type .sav" in found["notes/a save.sav"]
    assert "generated cache directory" in found["tools/__pycache__/x.cpython-314.pyc"]
    assert found["assets/blob data.bin"] == ["unexpected binary content"]
    assert found["content/derived room.json"] == ["contains the ROM-derived content marker"]


def test_detects_rom_images_by_content_not_name(repo, monkeypatch):
    stage(repo, "data/cart image.dat", bytes(build_rom(size=0x8000)))
    assert "content looks like a Game Boy ROM image" in reasons(repo)["data/cart image.dat"]
    monkeypatch.setattr(repo_check, "LOGO_SHA256", hashlib.sha256(FAKE_LOGO).hexdigest())
    bad_checksum = build_rom(size=0x8000, fix_checksums=False)
    stage(repo, "data/odd.dat", bytes(bad_checksum) + b"\x00")
    assert "content looks like a Game Boy ROM image" in reasons(repo)["data/odd.dat"]


def test_detects_copied_rom_fragment(repo, tmp_path):
    rng = random.Random(1234)
    fake_rom = bytes(rng.randrange(1, 256) for _ in range(4096))  # no NULs, so the copy stays text-like
    rom_path = tmp_path / "local rom.bin"
    rom_path.write_bytes(fake_rom)
    copied = fake_rom[1000:1070].hex()  # hex text does not match raw bytes
    stage(repo, "notes/hex dump.txt", copied + "\n")
    stage(repo, "notes/raw copy.txt", b"prefix " + fake_rom[1000:1070] + b" suffix")
    found = reasons(repo, [rom_path])
    assert "notes/hex dump.txt" not in found
    assert any("copied from a local ROM" in r for r in found["notes/raw copy.txt"])


def test_low_entropy_windows_are_ignored(repo, tmp_path):
    rom_path = tmp_path / "rom.bin"
    rom_path.write_bytes(b"\xff" * 4096)
    stage(repo, "notes/padding.txt", "\xff".encode("latin-1") * 200)
    assert all("copied" not in r for r in sum(reasons(repo, [rom_path]).values(), []))


def test_cli_reports_failure(repo, capsys):
    stage(repo, "Original_ROM/x.gbc", "x")
    assert repo_check.main(["--root", str(repo), "--no-rom"]) == 1
    assert "Original_ROM/x.gbc" in capsys.readouterr().out
