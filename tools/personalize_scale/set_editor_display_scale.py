#!/usr/bin/env python3
"""Patch Godot 4.6 editor_settings-4.6.tres display scale (restart required)."""
from __future__ import annotations

import argparse
from pathlib import Path


def apply(path: Path, display_scale: int, custom_scale: float | None) -> None:
    text: str = path.read_text(encoding="utf-8")
    lines: list[str] = text.splitlines(keepends=True)
    key_ds: str = "interface/editor/appearance/display_scale"
    key_cs: str = "interface/editor/appearance/custom_display_scale"
    out: list[str] = []
    seen_ds: bool = False
    seen_cs: bool = False
    for line in lines:
        if line.startswith(key_ds + " "):
            out.append(f"{key_ds} = {display_scale}\n")
            seen_ds = True
            continue
        if line.startswith(key_cs + " "):
            if custom_scale is not None:
                out.append(f"{key_cs} = {custom_scale}\n")
            else:
                out.append(line)
            seen_cs = True
            continue
        out.append(line)
    if not seen_ds:
        insert_at: int = 0
        for i, line in enumerate(out):
            if line.strip() == "[resource]":
                insert_at = i + 1
                break
        out.insert(insert_at, f"{key_ds} = {display_scale}\n")
    if custom_scale is not None and not seen_cs:
        insert_at = 0
        for i, line in enumerate(out):
            if line.startswith(key_ds):
                insert_at = i + 1
                break
        out.insert(insert_at, f"{key_cs} = {custom_scale}\n")
    path.write_text("".join(out), encoding="utf-8")


def main() -> None:
    p: argparse.ArgumentParser = argparse.ArgumentParser()
    p.add_argument("path", type=Path)
    p.add_argument("--mode", type=int, required=True, help="enum index: 2=100% .. 7=Custom")
    p.add_argument("--custom", type=float, default=None, help="custom scale when mode is Custom (7)")
    args: argparse.Namespace = p.parse_args()
    apply(args.path, args.mode, args.custom)


if __name__ == "__main__":
    main()
