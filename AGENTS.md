# AGENTS.md

## Cursor Cloud specific instructions

This is a **Godot 4.6 GDScript** game project (top-down roguelite shooter). No backend, no database, no Docker—everything is self-contained.

### Engine

- **Godot 4.6** is the sole runtime. The binary is installed at `/usr/local/bin/godot`.
- The update script downloads and installs it automatically on each VM startup.

### Running the game

| Action | Command |
|---|---|
| Run game (GUI) | `godot --windowed` (from repo root; launches main menu) |
| Open editor | `godot --editor --windowed` |
| Import / re-import assets | `godot --headless --import` |

### Testing

| Action | Command |
|---|---|
| Balance / data sanity tests (headless, no GPU) | `godot --headless -s res://tests/balance_runner.gd` |
| GDUnit4 tests (if plugin installed) | `godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd` |
| GDScript lint | `gdlint scripts/` (via `pip3 install gdtoolkit`) |

- `balance_runner.gd` exit code 0 = pass. It checks wave data, shop pricing, cluster batches, and determinism.
- GDUnit4 is **not bundled** in `addons/`; the lightweight balance runner works without it.
- `gdlint` reports pre-existing style warnings (line length, definition order). These are not CI-blocking.

### Gotchas

- When Godot runs without `--editor`, it launches the game directly (main scene = main menu).
- The `--check-only` flag requires `--script` and checks a single file, not the whole project.
- Godot editor in headless mode (`--headless --import`) is needed to regenerate `.godot/imported/` cache after pulling new assets.
- Game data lives in `data/*.json`; changes require re-export for packaged builds but work immediately from the editor.
- The cloud VM uses OpenGL compatibility renderer (no Vulkan). Godot falls back automatically; the game runs fine.
