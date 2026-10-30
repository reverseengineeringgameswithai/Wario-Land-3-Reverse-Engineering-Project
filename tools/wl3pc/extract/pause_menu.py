"""Decode the pause menu's and the save screens' data (WL3-052): their framesets, OAM table,
palettes, graphics, and maps.

Question: what do the pause menu and the save screens that end every owner's movie load?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM): the map's
save screen runs in _PauseMenuStateTable (7c:4000, src/engine/pause/state_table.asm) at
SST_PAUSE_18; InitSaveScreenAndBackupVRAM and Save (src/engine/pause/save/save.asm) load
LoadSaveScreenPals' Pals_1f628c into both temporary palette sets, LoadSaveScreenGfx's SaveBoxGfx
(RLE, to $8000) and WarioSleepGfx ($800 bytes copied to $8000), and DrawSaveInProgressBox's and
DrawSaveCompleteBox's maps (RLE, to BG map 0) (src/engine/pause/bank7d.asm). The pause menu itself
(sub-states 0-7, pause_menu_1.asm and pause_menu_2.asm, bank $7c) loads LoadPauseMenuPals'
Pals_1f4182 and Pals_1f41c2 into the temporary palette sets, and animates its menu objects with
UpdateObjAnim through the framesets InitPauseMenu and HandlePauseMenuInput name (Frameset_1f1c4a to
Frameset_1f1d4c, bank $7c, the bank the table runs in), drawn by LoadPauseMenuSprite (OAM_1f156c);
LoadPauseMenuGfx's PauseMenuGfx (RLE, to $8000) with Owl Wario's, the rail's, or Vampire Wario's
$20 tiles copied over its start (ActionHelpOwlGfx, ActionHelpRailGfx, ActionHelpVampireGfx), and
Func_1f403f's maps on BG map 1 (PauseMenuAttrmap and PauseMenuTilemap, or in Time Attack
TimeAttackPauseMenuAttrmap and TimeAttackPauseMenuTilemap; RLE), all bank $7d.
Research note: docs/02-research/overworld.md, docs/02-research/pause-menu.md.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..address import BankedAddress, RomView
from ..known_roms import WL3_WORLD_EN_JA
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from . import block_functions as bf
from .block_functions import MalformedDataError
from .clear import decode_oam_table
from .golf import decode_frameset
from .rle import decompress

FORMAT = "wl3pc.pause_menu"
FORMAT_VERSION = 3
EXTRACTOR_VERSION = 3
# The pause menu's framesets (InitPauseMenu, HandlePauseMenuInput): Frameset_1f1c4a to Frameset_1f1d4c.
FRAMESETS = tuple(BankedAddress.parse(text) for text in (
    "7c:5c4a", "7c:5c4d", "7c:5c50", "7c:5c69", "7c:5c74", "7c:5c77", "7c:5c9c", "7c:5c9f", "7c:5cb8",
    "7c:5cbb", "7c:5cd4", "7c:5ced", "7c:5cf0", "7c:5cf3", "7c:5cf6", "7c:5cf9", "7c:5d0a", "7c:5d1b",
    "7c:5d20", "7c:5d41", "7c:5d4c",
))
OAM_TABLES = (BankedAddress.parse("7c:556c"),)  # OAM_1f156c (LoadPauseMenuSprite)
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "7d:62cc",  # SaveBoxGfx
    "7d:6949",  # SaveInProgressBoxTilemap
    "7d:69f9",  # SaveInProgressBoxAttrmap
    "7d:6a2e",  # SaveCompleteBoxTilemap
    "7d:6ac2",  # SaveCompleteBoxAttrmap
    "7d:4202",  # PauseMenuGfx
    "7d:5de1",  # PauseMenuTilemap
    "7d:5f49",  # PauseMenuAttrmap
    "7d:603a",  # TimeAttackPauseMenuTilemap
    "7d:6194",  # TimeAttackPauseMenuAttrmap
))
RAW = {
    "76:6800": 0x800,  # WarioSleepGfx
    "7d:57e1": 0x200,  # ActionHelpOwlGfx (the pause menu's $20 tiles for Owl Wario)
    "7d:59e1": 0x200,  # ActionHelpRailGfx
    "7d:5be1": 0x200,  # ActionHelpVampireGfx
}
PALETTES = {
    "7d:628c": 0x40,  # Pals_1f628c (LoadSaveScreenPals)
    "7d:4182": 0x40,  # Pals_1f4182 (LoadPauseMenuPals, wTempPals1)
    "7d:41c2": 0x40,  # Pals_1f41c2 (LoadPauseMenuPals, wTempPals2)
}


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    return {"framesets": {str(where): decode_frameset(view, where) for where in FRAMESETS},
            "oam_tables": {str(where): decode_oam_table(view, where) for where in OAM_TABLES},
            "gfx": {"compressed": {str(where): decompress(view, where, 0x2000)[0].hex() for where in COMPRESSED},
                    "raw": {key: view.read_banked(BankedAddress.parse(key), size).hex() for key, size in RAW.items()},
                    "palettes": {key: view.read_banked(BankedAddress.parse(key), size).hex()
                                 for key, size in PALETTES.items()}}}


def extract(rom_path: Path, out_dir: Path, exploratory: bool = False) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_EN_JA.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"
    document = decode(rom)
    document.update({
        "format": FORMAT, "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {"rom_sha256": report.hashes.sha256, "rom_id": report.identity.rom_id,
                       "extractor": "wl3pc.extract.pause_menu", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "pause_menu.json", payload)
    return {"path": str(target / "pause_menu.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-pause-menu", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    try:
        result = extract(args.rom or rom_path_from_env(), args.out, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    document = result["document"]
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(f"  {len(document['framesets'])} framesets, {len(document['oam_tables'])} OAM tables")
    return 0


if __name__ == "__main__":
    sys.exit(main())
