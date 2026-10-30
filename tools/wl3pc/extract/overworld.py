"""Keep the ROM banks the map reads (WL3-052), whole.

Question: what data does the map's port need, and in what form?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM): the map
(src/engine/overworld/, about 37,200 lines) reads hundreds of data labels through pointer tables:
its paths and level coordinates (data/overworld/), its palettes and their fades
(data/overworld/palettes.asm), its objects' framesets and OAM tables, its maps and graphics
(compressed with the levels' RLE, in banks $22 to $24), its unlockable connections, and the
cutscenes' scripts. Decoding each into its own format would mean a format per table; the port
instead reads them as the original does, by bank and address, from these banks kept whole (and
decompresses with the same RLE). Banks are added as the port reaches their data.
Research note: docs/02-research/overworld.md.
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

FORMAT = "wl3pc.overworld"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 4
# The ROM banks the map's port reads, kept whole: the home bank's tables, the map's code banks'
# tables ($20, $21, $26, $27, $2b, $2d, $56, $57), its graphics and maps ($22 to $24, $2a, $2e,
# $2f), its objects' framesets and OAM tables ($1a, $05, $7f), the clouds and sea ($76), and for its
# drawing (in progress) the other graphics banks its loaders read; for the prologue (WL3-056) scene
# Wario's other OAM and tiles ($35, $09), _PrologueFade's Pals_db000 ($36), and FontGfx ($7c); for the
# Temple's hidden figure (WL3-052) its hands' and mouth's OAM table (OAM_18c88a, $63); for the epilogue
# its creatures' OAM tables (OAM_18007b and _180ea7, $60; OAM_18422f, $61) and graphics (SpearheadGfx,
# $68; HammerBotGfx, $69).
BANKS = (0x00, 0x01, 0x04, 0x05, 0x09, 0x0B, 0x1A, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
         0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x33, 0x35, 0x36, 0x4E, 0x52, 0x56, 0x57, 0x60, 0x61, 0x62, 0x63,
         0x68, 0x69, 0x6A, 0x76, 0x7C, 0x7F)
BANK_SIZE = 0x4000


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    return {"banks": {f"{bank:02x}": view.read_banked(BankedAddress(bank, 0x0000 if bank == 0 else 0x4000),
                                                      BANK_SIZE).hex() for bank in BANKS}}


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
                       "extractor": "wl3pc.extract.overworld", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "overworld.json", payload)
    return {"path": str(target / "overworld.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-overworld", description=__doc__.splitlines()[0])
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
    return 0


if __name__ == "__main__":
    sys.exit(main())
