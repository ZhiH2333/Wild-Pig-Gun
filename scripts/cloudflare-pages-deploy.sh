#!/usr/bin/env bash
set -euo pipefail
# 将 Godot Web 导出部署到 Cloudflare Pages（需已登录 wrangler 或设置 CLOUDFLARE_API_TOKEN）。
# 用法：
#   WEB_EXPORT_DIR=/path/to/web ./scripts/cloudflare-pages-deploy.sh
# 可选环境变量：PROJECT_NAME（默认 wild-pig-gun-web）、BRANCH（默认 production）

WEB_EXPORT_DIR="${WEB_EXPORT_DIR:-/home/ubuntu/exp/web}"
PROJECT_NAME="${PROJECT_NAME:-wild-pig-gun-web}"
BRANCH="${BRANCH:-production}"
STAGING="${STAGING:-/tmp/cf-pages-wildpiggun-staging}"

if [ ! -f "${WEB_EXPORT_DIR}/wildpiggun.html" ]; then
	echo "错误：未找到 ${WEB_EXPORT_DIR}/wildpiggun.html，请设置 WEB_EXPORT_DIR 为 Godot Web 导出目录。" >&2
	exit 1
fi

rm -rf "${STAGING}"
mkdir -p "${STAGING}"
cp -a "${WEB_EXPORT_DIR}/." "${STAGING}/"
cp -f "${STAGING}/wildpiggun.html" "${STAGING}/index.html"
cat > "${STAGING}/_headers" << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF

echo "暂存目录: ${STAGING}"
npx --yes wrangler@4.54.0 pages deploy "${STAGING}" --project-name="${PROJECT_NAME}" --branch="${BRANCH}"
