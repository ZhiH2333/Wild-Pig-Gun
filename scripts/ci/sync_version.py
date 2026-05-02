#!/usr/bin/env python3
"""根据 RELEASE_VERSION（语义化版本 X.Y.Z，可带可选前缀 v）写入 project.godot 与 export_presets.cfg。"""
from __future__ import annotations

import os
import re
import sys


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def parse_semver(raw: str) -> tuple[int, int, int, str]:
    s = raw.strip()
    if s.startswith("v"):
        s = s[1:]
    m = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", s)
    if not m:
        fail(f"RELEASE_VERSION 必须是 X.Y.Z（可选前缀 v），当前为 {raw!r}")
    major, minor, patch = int(m.group(1)), int(m.group(2)), int(m.group(3))
    ver = f"{major}.{minor}.{patch}"
    return major, minor, patch, ver


def main() -> None:
    raw = os.environ.get("RELEASE_VERSION", "").strip()
    if not raw:
        fail("请设置环境变量 RELEASE_VERSION，例如 1.0.2")
    major, minor, patch, ver = parse_semver(raw)
    version_code: int = major * 10000 + minor * 100 + patch
    win_file_ver = f"{major}.{minor}.{patch}.0"
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    pg_path = os.path.join(root, "project.godot")
    ep_path = os.path.join(root, "export_presets.cfg")
    if not os.path.isfile(pg_path):
        fail(f"找不到 {pg_path}")
    if not os.path.isfile(ep_path):
        fail(f"找不到 {ep_path}")
    pg = open(pg_path, encoding="utf-8").read()
    pg = re.sub(r'config/version="[^"]*"', f'config/version="{ver}"', pg)
    pg = re.sub(r"config/version_code=\d+", f"config/version_code={version_code}", pg)
    open(pg_path, "w", encoding="utf-8").write(pg)
    ep = open(ep_path, encoding="utf-8").read()
    ep = re.sub(
        r'export_path="export_build/android/[^"]*"',
        f'export_path="export_build/android/WildPigGun-android-{ver}-universal.apk"',
        ep,
        count=1,
    )
    ep = re.sub(r"version/code=\d+", f"version/code={version_code}", ep, count=1)
    ep = re.sub(r'version/name="[^"]*"', f'version/name="{ver}"', ep, count=1)
    ep = re.sub(
        r'application/file_version="[^"]*"',
        f'application/file_version="{win_file_ver}"',
        ep,
        count=1,
    )
    ep = re.sub(
        r'application/product_version="[^"]*"',
        f'application/product_version="{win_file_ver}"',
        ep,
        count=1,
    )
    ep = re.sub(
        r'export_path="export_build/macos/[^"]*"',
        f'export_path="export_build/macos/WildPigGun-macos-universal-{ver}.zip"',
        ep,
        count=1,
    )
    ep = re.sub(
        r'application/short_version="[^"]*"',
        f'application/short_version="{ver}"',
        ep,
        count=1,
    )
    ep = re.sub(
        r'application/version="[^"]*"',
        f'application/version="{ver}"',
        ep,
        count=1,
    )
    ep = re.sub(
        r'application/bundle_identifier="[^"]*"',
        'application/bundle_identifier="com.wildpiggun.game"',
        ep,
        count=1,
    )
    open(ep_path, "w", encoding="utf-8").write(ep)
    print(f"sync_version: {ver} (code={version_code})")


if __name__ == "__main__":
    main()
