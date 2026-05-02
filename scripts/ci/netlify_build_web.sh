#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

git fetch --tags --force 2>/dev/null || true
git fetch --unshallow 2>/dev/null || true

# shellcheck source=install_godot_linux.sh
source "${REPO_ROOT}/scripts/ci/install_godot_linux.sh"

mkdir -p "${REPO_ROOT}/dist"

if [ -n "${RELEASE_VERSION:-}" ]; then
	:
elif tag="$(git describe --tags --exact-match 2>/dev/null)" && [ -n "${tag}" ]; then
	export RELEASE_VERSION="${tag#v}"
else
	LATEST="$(git describe --tags --match 'v[0-9]*.[0-9]*.[0-9]*' --abbrev=0 2>/dev/null || true)"
	if [ -n "${LATEST}" ]; then
		export RELEASE_VERSION="${LATEST#v}"
	else
		pg_ver=""
		if [ -f "${REPO_ROOT}/project.godot" ]; then
			pg_ver="$(grep -E '^config/version=' "${REPO_ROOT}/project.godot" | head -1 | sed 's/^config\/version="\(.*\)"/\1/')"
		fi
		if [[ "${pg_ver}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			export RELEASE_VERSION="${pg_ver}"
		else
			export RELEASE_VERSION="0.0.0"
		fi
	fi
fi

python3 "${REPO_ROOT}/scripts/ci/sync_version.py"

if [ ! -f "${REPO_ROOT}/export_presets.cfg" ]; then
	echo "Missing export_presets.cfg at repo root." >&2
	exit 1
fi

echo "Importing assets (.godot/imported)..."
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --import --quit

echo "Exporting Web preset → dist/ ..."
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --export-release "Web" "${REPO_ROOT}/dist/wildpiggun.html"

cp -f "${REPO_ROOT}/dist/wildpiggun.html" "${REPO_ROOT}/dist/index.html"
cat > "${REPO_ROOT}/dist/_headers" << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF

echo "Web export ready under dist/ (version ${RELEASE_VERSION})"
