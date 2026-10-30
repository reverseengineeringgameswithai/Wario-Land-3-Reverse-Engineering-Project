#!/usr/bin/env bash
# Clone the committed HEAD into a temporary directory and run the ROM-free
# checks there, proving they do not depend on ignored files (ROM, external/,
# local/content). The pinned Godot binary is reused via GODOT.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
godot=${GODOT:-$root/local/toolchain/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64}
work=$(mktemp -d "${TMPDIR:-/tmp}/wl3pc-clean-XXXXXX")
trap 'rm -rf "$work"' EXIT
git clone --quiet --no-local "$root" "$work/repo"
cd "$work/repo"
echo "clean checkout: $(git rev-parse HEAD) in $work/repo"
uv sync --locked --python /usr/bin/python3.14 --quiet
export GODOT="$godot" WL3PC_ROM="$work/no-rom.gbc"
make --no-print-directory test-python content-check docs-check repo-check test-godot smoke
before=$(git status --porcelain --untracked-files=all)
if [ -n "$before" ]; then
  echo "tracked-tree changes after running checks:"; echo "$before"; exit 1
fi
echo "clean checkout: OK (no ROM, no external/, no local/; working tree unchanged)"
