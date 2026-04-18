#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${DIST_DIR:-${ROOT_DIR}/dist}"
EXPORT_FILE_BASENAME="${EXPORT_FILE_BASENAME:-wildpiggun}"
EXPORT_FILE_NAME="${EXPORT_FILE_NAME:-${EXPORT_FILE_BASENAME}.html}"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
echo "[netlify-build] root=${ROOT_DIR}"
echo "[netlify-build] dist=${DIST_DIR}"
mkdir -p "${DIST_DIR}"
"${GODOT_BIN}" --headless --import
"${GODOT_BIN}" --headless --export-release "Web" "${DIST_DIR}/${EXPORT_FILE_NAME}"
if [ ! -f "${DIST_DIR}/${EXPORT_FILE_NAME}" ]; then
  echo "[netlify-build] 错误：未找到导出的 HTML 文件 ${DIST_DIR}/${EXPORT_FILE_NAME}" >&2
  exit 1
fi
cp -f "${DIST_DIR}/${EXPORT_FILE_NAME}" "${DIST_DIR}/index.html"
cat > "${DIST_DIR}/_headers" << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF
echo "[netlify-build] 完成，已生成 ${DIST_DIR}/index.html 与 ${DIST_DIR}/_headers"
