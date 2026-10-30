"""Decode the title screen's data (WL3-055, WL3-056): its framesets, OAM tables, palettes, graphics, and maps.

Question: what does the title, from power-on to the start menu's Continue, load?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM): the title
runs in TitleStateTable (01:402b, src/engine/title/state_table.asm). InitIntroSequence
(src/engine/title/intro.asm) loads LoadTitleScreenPals' palettes (Pals_4f82 and Pals_4fc2 for the
intro, Pals_5002 and Pals_5042 with a save) into the temporary palette sets, LoadTitleScreenTiles'
PlaneGfx (to VRAM 1's $8000) and TitleScreenGfx (VRAM 0's $8000), and LoadTitleScreenTileMap's
TitleScreenAttrmap and TitleScreenTilemap (BG map 0), all compressed (Decompress), and with a save
copies TitleScreenBoxTilemap's two rows of 12 tiles under the menu (src/engine/title/load_gfx.asm,
vblank.asm). Its objects are animated with UpdateObjAnim through the framesets InitIntroSequence,
the intro, and the start menu name (Frameset_6ce6 to Frameset_71a7, bank 1, the bank the table runs
in), drawn by LoadStartMenuSprite (OAM_6b5f) and LoadIntroSprite (OAM_6d21)
(src/engine/title/load_oam.asm, start_menu.asm). New Game's language selection, in bank 1 too
(src/engine/language_selection/), loads LoadFontPals' Pals_1f3610 into both temporary palette sets,
LoadFontTiles' FontGfx (VRAM 0's $8000) and LoadLanguageSelectionText's two maps (BG map 0), all from
bank $7c and compressed, and draws its cursor (Frameset_76b5) by LoadLanguageSelectionSprite (OAM_75c3).
Time Attack's description (InitTimeAttackDescription, src/engine/title/time_attack_description.asm,
load_gfx.asm; WL3-058) loads Pals_71b0 into wTempPals1, FontGfx to VRAM 1, $80 tiles of
PrologueBackgroundGfx (2c:4f80, uncompressed) to VRAM 0's $9000, and LoadTimeAttackText's two maps by
wLanguage (compressed; the disassembly's labels for them are swapped against its file names, so they
are named here by the language whose path loads them: 01:73e6 and 01:74e8 for English, 01:71f0 and
01:7316 for Japanese).
Research note: docs/02-research/title.md.
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

FORMAT = "wl3pc.title"
FORMAT_VERSION = 3
EXTRACTOR_VERSION = 3
# The title's framesets (bank 1): the start menu's (Frameset_6ce6 to Frameset_6d1e), the intro's
# (Frameset_712c to Frameset_71a7), and the language selection's cursor (Frameset_76b5).
FRAMESETS = tuple(BankedAddress.parse(text) for text in (
    "01:6ce6", "01:6ce9", "01:6cec", "01:6cef", "01:6cf2", "01:6d05", "01:6d18", "01:6d1b", "01:6d1e",
    "01:712c", "01:713d", "01:7144", "01:7165", "01:7172", "01:717b", "01:7184", "01:718d", "01:7198",
    "01:71a1", "01:71a4", "01:71a7", "01:76b5",
))
OAM_TABLES = tuple(BankedAddress.parse(text) for text in (
    "01:6b5f",  # OAM_6b5f (LoadStartMenuSprite)
    "01:6d21",  # OAM_6d21 (LoadIntroSprite)
    "01:75c3",  # OAM_75c3 (LoadLanguageSelectionSprite)
))
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "01:5082",  # TitleScreenGfx
    "01:635c",  # PlaneGfx
    "01:697a",  # TitleScreenTilemap
    "01:6ae7",  # TitleScreenAttrmap
    "7c:5d5d",  # FontGfx (LoadFontTiles)
    "7c:7650",  # LanguageSelection1TextMap (BG map 0's tiles)
    "7c:767f",  # LanguageSelection2TextMap (its attributes)
    "01:71f0",  # TimeAttack1JPTextMap: the Japanese description's tiles (BG map 0)
    "01:7316",  # TimeAttack2JPTextMap: its attributes
    "01:73e6",  # TimeAttack1ENTextMap: the English description's tiles
    "01:74e8",  # TimeAttack2ENTextMap: its attributes
))
RAW = {
    "01:6b47": 24,  # TitleScreenBoxTilemap: two rows of 12 tiles
    "2c:4f80": 0x800,  # PrologueBackgroundGfx: the $80 tiles LoadTimeAttackDescriptionTiles copies
}
PALETTES = {
    "01:4f82": 0x40,  # Pals_4f82 (LoadTitleScreenPals without a save, wTempPals1)
    "01:4fc2": 0x40,  # Pals_4fc2 (wTempPals2)
    "01:5002": 0x40,  # Pals_5002 (with a save, wTempPals1)
    "01:5042": 0x40,  # Pals_5042 (wTempPals2)
    "7c:7610": 0x40,  # Pals_1f3610 (LoadFontPals, both sets)
    "01:71b0": 0x40,  # Pals_71b0 (LoadTimeAttackDescriptionPals, wTempPals1)
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
                       "extractor": "wl3pc.extract.title", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "title.json", payload)
    return {"path": str(target / "title.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-title", description=__doc__.splitlines()[0])
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
