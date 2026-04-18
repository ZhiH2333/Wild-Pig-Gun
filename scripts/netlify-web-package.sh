#!/usr/bin/env bash
set -euo pipefail
# 将 Godot Web 导出目录整理为可直接拖入 Netlify 的站点根目录：
# - 复制 wildpiggun.html 为 index.html
# - 写入 Netlify _headers（COOP/COEP，与 Godot WASM 跨源隔离要求一致）
#
# 用法：
#   WEB_EXPORT_DIR=/path/to/web ./scripts/netlify-web-package.sh [输出目录]
# 默认输出：同目录下的 netlify-site/

WEB_EXPORT_DIR="${WEB_EXPORT_DIR:-}"
OUT_DIR="${1:-}"

if [ -z "${WEB_EXPORT_DIR}" ]; then
	echo "请设置 WEB_EXPORT_DIR 为 Godot Web 导出目录（含 wildpiggun.html）。" >&2
	exit 1
fi

if [ ! -f "${WEB_EXPORT_DIR}/wildpiggun.html" ]; then
	echo "错误：未找到 ${WEB_EXPORT_DIR}/wildpiggun.html" >&2
	exit 1
fi

if [ -z "${OUT_DIR}" ]; then
	OUT_DIR="${WEB_EXPORT_DIR}/netlify-site"
fi

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"
cp -a "${WEB_EXPORT_DIR}/." "${OUT_DIR}/"
cp -f "${OUT_DIR}/wildpiggun.html" "${OUT_DIR}/index.html"
cat > "${OUT_DIR}/_headers" << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF

echo "已生成 Netlify 站点目录: ${OUT_DIR}"
