# WildPigGun — Cloud agent runbook (Godot 4.6)

Minimal instructions to run, validate, and extend this repo on Cursor Cloud VMs. Full detail also lives in `AGENTS.md` at repo root.

## Environment and “login”

- **No accounts or API keys.** The game is self-contained (no backend, no database, no Docker).
- **Engine:** Godot **4.6** at `/usr/local/bin/godot` (installed on VM startup).
- **GPU:** Cloud uses OpenGL compatibility; Vulkan is not required. Godot falls back automatically.
- **Working directory:** Run all commands from the **repository root** unless a path says otherwise.

## Quick sanity check

```bash
which godot
godot --version
```

## Starting the app

| Goal | Command |
|------|---------|
| Play the game (main menu) | `godot --windowed` |
| Open the editor | `godot --editor --windowed` |
| Re-import assets (headless, after pulling new art/audio) | `godot --headless --import` |

**Note:** Without `--editor`, Godot runs the game; main scene is configured in `project.godot` (`run/main_scene`).

## Feature flags and toggles

- **There is no feature-flag system or env-var gate** in this codebase (no `OS.get_environment`–style switches for gameplay).
- **In-game debug:** A debug overlay exists (`scripts/ui/debug_menu.gd`). Toggle with **triple-tap `Z`** within ~500 ms when not typing in a `LineEdit`. Use it for god mode, stat tweaks, and spawning enemies during manual QA.

If you add flags later, document the **exact variable names**, **default values**, and **how to set them** (shell `export`, Godot project settings, or CLI) in the “Maintaining this skill” section below.

---

## By codebase area

### 1. Game data (`data/*.json`)

- JSON drives waves, shop, clusters, etc. Editor and direct runs load these immediately; packaged builds may need a separate export step (see `AGENTS.md`).
- **Automated checks:** Balance runner validates wave timing, shop scaling, cluster caps, and RNG determinism (see area 3).

### 2. GDScript sources (`scripts/`)

- Core gameplay, UI, audio, save, settings.
- **Optional lint (not CI-blocking):** `pip3 install gdtoolkit` then `gdlint scripts/` — expect existing style noise (line length, definition order).

### 3. Automated tests (`tests/`)

All use **headless** Godot with `-s` (script as main loop). Exit **0** = pass, **1** = failure.

| Area | What it covers | Command |
|------|----------------|---------|
| Balance / data | `BalanceChecks` — waves, shop pricing, batch caps, determinism | `godot --headless -s res://tests/balance_runner.gd` |
| UI — item cards | Property tests via `test_item_card_runner.gd` | `godot --headless -s res://tests/ui/test_item_card_runner.gd` |
| UI — damage popups | Property tests via `test_damage_popup_runner.gd` | `godot --headless -s res://tests/ui/test_damage_popup_runner.gd` |

**GDUnit4:** Not bundled. If `addons/gdUnit4/` exists in a fork, run:  
`godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd`

**Workflow:** After changing `data/*.json` or wave/shop logic, always run the **balance** command first; after UI/layout changes touching item cards or damage popups, run the matching **UI runner**.

### 4. Scenes, themes, assets (`scenes/`, `themes/`, `assets/`)

- After pulling large asset changes, run `godot --headless --import` so `.godot/imported/` stays consistent.
- **Manual / visual QA:** `godot --windowed` or `godot --editor --windowed`.

### 5. Single-file syntax check (Godot CLI)

- `--check-only` validates **one** script file and must be used with `--script`, e.g.  
  `godot --headless --check-only --script res://scripts/path/to/file.gd`  
  It does **not** lint the whole tree—use `gdlint` for bulk style.

---

## Common Cloud workflows

1. **Post-clone / post-pull:** `godot --headless --import` (if assets changed), then `godot --headless -s res://tests/balance_runner.gd`.
2. **Before commit (logic + data):** Balance runner + any affected UI runner from the table above.
3. **Interactive debugging:** `godot --windowed` → triple-`Z` debug panel.

---

## Maintaining this skill

When you discover a new trick (extra test script, env convention, editor setting, packaging step):

1. **Add it in the right section** above (match the folder or subsystem you touched).
2. **Prefer copy-paste commands** with `res://` paths from repo root.
3. **Keep `AGENTS.md` in sync** for anything that applies to all agents (engine version, canonical commands); this file can stay Cloud- and workflow-focused.
4. If something is **fragile or VM-specific**, say so in one line (why and when it breaks).

Short checklist before merging skill edits: commands run from repo root; paths verified; note “not bundled” for optional tools (GDUnit4, gdtoolkit).
