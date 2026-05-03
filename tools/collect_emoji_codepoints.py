#!/usr/bin/env python3
"""
Scan Godot project sources for emoji scalars and optionally subset Noto Color Emoji.

Requires (for subsetting): pip install -r tools/requirements-emoji-subset.txt
(fonttools provides pyftsubset; lxml is needed if the source font has an SVG table,
as with recent Noto Color Emoji builds.)

Example:
  python3 tools/collect_emoji_codepoints.py --list
  NOTO_EMOJI_FONT=/path/to/NotoColorEmoji-Regular.ttf \\
    python3 tools/collect_emoji_codepoints.py --subset assets/fonts/NotoColorEmoji-GameSubset.ttf

Godot: assign the subset as DynamicFont / FontFile fallback for UI fonts that show emoji.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

_ROOT = Path(__file__).resolve().parents[1]

# Scalars that commonly participate in emoji sequences (ZWJ, VS16, keycap).
_ALWAYS_INCLUDE: tuple[int, ...] = (0x200D, 0xFE0F, 0x20E3)

# Broad Unicode emoji scalar ranges (TR #51 style); avoids pulling non-emoji CJK.
_EMOJI_RANGES: tuple[tuple[int, int], ...] = (
    (0x203C, 0x203C),
    (0x2049, 0x2049),
    (0x2122, 0x2122),
    (0x2139, 0x2139),
    (0x2194, 0x2199),
    (0x21A9, 0x21AA),
    (0x231A, 0x23FF),
    (0x24C2, 0x24C2),
    (0x25AA, 0x25FE),
    (0x2600, 0x27FF),
    (0x2934, 0x2935),
    (0x2B05, 0x2B07),
    (0x2B1B, 0x2B1C),
    (0x2B50, 0x2B50),
    (0x2B55, 0x2B55),
    (0x3030, 0x3030),
    (0x303D, 0x303D),
    (0x3297, 0x3297),
    (0x3299, 0x3299),
    (0xFE00, 0xFE0F),
    (0x1F000, 0x1FFFF),
)

_ESCAPE_RE = re.compile(r"\\u([0-9a-fA-F]{4})")


def _in_emoji_range(codepoint: int) -> bool:
    for lo, hi in _EMOJI_RANGES:
        if lo <= codepoint <= hi:
            return True
    return False


def _collect_scalars_from_text(text: str, out: set[int]) -> None:
    for ch in text:
        o = ord(ch)
        if _in_emoji_range(o):
            out.add(o)
    for m in _ESCAPE_RE.finditer(text):
        o = int(m.group(1), 16)
        if _in_emoji_range(o):
            out.add(o)


def _iter_project_files() -> list[Path]:
    paths: list[Path] = []
    for sub in ("data", "scripts", "scenes"):
        base = _ROOT / sub
        if not base.is_dir():
            continue
        for p in base.rglob("*"):
            if not p.is_file():
                continue
            if p.suffix.lower() in {".gd", ".json", ".tscn", ".tres", ".csv"}:
                paths.append(p)
    return sorted(paths)


def collect_used_emoji_codepoints() -> set[int]:
    found: set[int] = set(_ALWAYS_INCLUDE)
    for path in _iter_project_files():
        try:
            raw = path.read_text(encoding="utf-8")
        except OSError:
            continue
        _collect_scalars_from_text(raw, found)
    return found


def _format_unicodes_arg(codepoints: set[int]) -> str:
    parts: list[str] = []
    for cp in sorted(codepoints):
        parts.append(f"U+{cp:X}")
    return ",".join(parts)


def _subset_argv0() -> list[str] | None:
    """Return argv prefix for pyftsubset (PATH, venv sibling, or python -m)."""
    import shutil

    exe = shutil.which("pyftsubset")
    if exe:
        return [exe]
    # Do not Path.resolve(): venv bin/python3 symlinks to Homebrew and would miss venv/pyftsubset.
    local = Path(sys.executable).parent / "pyftsubset"
    if local.is_file():
        return [str(local)]
    try:
        import fontTools  # noqa: F401
    except ImportError:
        return None
    return [sys.executable, "-m", "fontTools.subset"]


def main() -> int:
    parser = argparse.ArgumentParser(description="Collect emoji codepoints; optional Noto subset.")
    parser.add_argument("--list", action="store_true", help="Print sorted U+XXXX lines")
    parser.add_argument("--unicodes-arg", action="store_true", help="Print one pyftsubset --unicodes= line")
    parser.add_argument("--subset", metavar="OUT_TTF", help="Run pyftsubset to write subset font")
    parser.add_argument(
        "--font",
        default=os.environ.get("NOTO_EMOJI_FONT", ""),
        help="Input Noto Color Emoji TTF (or set NOTO_EMOJI_FONT)",
    )
    args = parser.parse_args()
    cps = collect_used_emoji_codepoints()
    if args.list:
        for cp in sorted(cps):
            print(f"U+{cp:X}")
        return 0
    if args.unicodes_arg:
        print(_format_unicodes_arg(cps))
        return 0
    if args.subset:
        font = args.font.strip()
        if not font:
            print("error: pass --font or set NOTO_EMOJI_FONT", file=sys.stderr)
            return 2
        fp = Path(font)
        if not fp.is_file():
            print(f"error: font not found: {fp}", file=sys.stderr)
            return 2
        prefix = _subset_argv0()
        if not prefix:
            print(
                "error: fonttools not available; pip install fonttools or use tools/.venv",
                file=sys.stderr,
            )
            return 2
        out_path = Path(args.subset)
        if not out_path.is_absolute():
            out_path = _ROOT / out_path
        out_path.parent.mkdir(parents=True, exist_ok=True)
        unicodes = _format_unicodes_arg(cps)
        cmd = prefix + [
            str(fp),
            f"--output-file={out_path}",
            f"--unicodes={unicodes}",
            "--layout-features=*",
            "--glyph-names",
            "--symbol-cmap",
            "--legacy-cmap",
            "--notdef-glyph",
            "--notdef-outline",
            "--recommended-glyphs",
        ]
        print(" ".join(cmd))
        r = subprocess.run(cmd, check=False)
        if r.returncode != 0:
            return r.returncode
        print(f"wrote {out_path} ({len(cps)} unicode scalars + tables)")
        return 0
    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
