# Content fixtures

Synthetic, project-original fixtures shared by the Python validator
(`tests/test_content.py`) and the Godot loader
(`game/tests/unit/test_content_loader.gd`). Every entry under `invalid-mods/`,
`invalid-packs/`, and `invalid-traces/` must be rejected by both; its name
states the defect. Every entry under `valid-packs/` must load in both.
