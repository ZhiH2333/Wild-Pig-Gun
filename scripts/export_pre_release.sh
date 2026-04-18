#!/usr/bin/env bash
set -euo pipefail
# 预发布一键导出：Android（v7+v8）、Windows、macOS、Web（含 _headers）。
# 需已安装与项目一致的 Godot 4.6 及对应 export templates。
# 用法：在仓库根目录执行 ./scripts/export_pre_release.sh
# 可选：GODOT_BIN=/path/to/godot GODOT_HEADLESS_FLAGS="--display-driver headless"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
GODOT_BIN="${GODOT_BIN:-godot}"

mkdir -p "${ROOT}/export_build/android" "${ROOT}/export_build/windows" "${ROOT}/export_build/macos" "${ROOT}/export_build/web"

if [ ! -f "${ROOT}/export_build/keys/wildpiggun-release.keystore" ]; then
	echo "生成 Android release 签名库…"
	"${ROOT}/scripts/android_export_prep.sh"
fi

echo "导入资源（headless）…"
"${GODOT_BIN}" --headless --path "${ROOT}" --import || true

export_one() {
	local name="$1"
	local path="$2"
	echo "导出: ${name} -> ${path}"
	"${GODOT_BIN}" --headless --path "${ROOT}" --export-release "${name}" "${path}"
}

export_one "Android" "${ROOT}/export_build/android/WildPigGun-android-v1.0.0+4.apk"
export_one "Windows Desktop" "${ROOT}/export_build/windows/WildPigGun.exe"
export_one "macOS" "${ROOT}/export_build/macos/WildPigGun-macos-universal-v1.0.0+4.zip"
export_one "Web" "${ROOT}/export_build/web/wildpiggun.html"

WEB_DIR="${ROOT}/export_build/web"
if [ -f "${WEB_DIR}/wildpiggun.html" ]; then
	cp -f "${WEB_DIR}/wildpiggun.html" "${WEB_DIR}/index.html"
	cat > "${WEB_DIR}/_headers" << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF
	echo "已写入 Web 托管用 _headers（与 COOP/COEP 跨源隔离一致）。"
fi

echo "完成。输出目录: ${ROOT}/export_build/"
