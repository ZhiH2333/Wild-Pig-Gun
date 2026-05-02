#!/usr/bin/env bash
# Godot 4.x Linux 编辑器与导出模板安装（与 netlify_build_web 职责分离）。
# Installs Godot editor + export templates on Linux（Netlify / GitHub Actions）。
# Source 本脚本后可用：GODOT_BIN、REPO_ROOT
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

GODOT_VERSION="${GODOT_VERSION:-4.6}"
if [ -n "${NETLIFY_CACHE_DIR:-}" ]; then
	CACHE="${NETLIFY_CACHE_DIR}/godot-${GODOT_VERSION}"
elif [ -d "/opt/build/cache" ]; then
	CACHE="/opt/build/cache/godot-${GODOT_VERSION}"
else
	CACHE="${CI_GODOT_CACHE:-${REPO_ROOT}/.ci-godot-cache}"
fi
mkdir -p "${CACHE}"

GODOT_URL="${GODOT_URL:-https://downloads.godotengine.org/?version=${GODOT_VERSION}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64}"
GODOT_BIN="${CACHE}/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
TPZ_URL="${GODOT_EXPORT_TEMPLATES_URL:-https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz}"

if [ ! -x "${GODOT_BIN}" ]; then
	echo "Downloading Godot ${GODOT_VERSION} editor (linux x86_64)..."
	curl -fsSL "${GODOT_URL}" -o "${CACHE}/godot-linux.zip"
	unzip -q -o "${CACHE}/godot-linux.zip" -d "${CACHE}"
	chmod +x "${GODOT_BIN}"
fi

TP_EXTRACT="${CACHE}/export-templates-unpack"
TP_VERSION_FILE="${TP_EXTRACT}/templates/version.txt"
if [ ! -f "${TP_VERSION_FILE}" ]; then
	echo "Downloading export templates..."
	rm -rf "${TP_EXTRACT}"
	mkdir -p "${TP_EXTRACT}"
	curl -fL "${TPZ_URL}" -o "${CACHE}/export_templates.tpz"
	unzip -q -o "${CACHE}/export_templates.tpz" -d "${TP_EXTRACT}"
fi
TP_VER="$(tr -d '\r\n' < "${TP_VERSION_FILE}")"
TP_TARGET="${HOME}/.local/share/godot/export_templates/${TP_VER}"
if [ ! -f "${TP_TARGET}/web_release.zip" ]; then
	echo "Installing export templates to ${TP_TARGET}..."
	mkdir -p "${TP_TARGET}"
	cp -a "${TP_EXTRACT}/templates/." "${TP_TARGET}/"
fi

if [ ! -x "${GODOT_BIN}" ]; then
	echo "Godot binary missing: ${GODOT_BIN}" >&2
	exit 1
fi

export GODOT_BIN REPO_ROOT
