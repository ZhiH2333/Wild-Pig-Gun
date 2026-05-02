#!/usr/bin/env bash
# GitHub Actions：按 tag 同步版本并无头导出 Web / Windows / macOS / Android，产物写入 artifacts/
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

# shellcheck source=webview_extension_ci.sh
source "${SCRIPT_DIR}/webview_extension_ci.sh"
ci_webview_extension_disable

TAG="${GITHUB_REF_NAME:?请在环境中设置 GITHUB_REF_NAME（通常为 git tag 名称）}"
export RELEASE_VERSION="${TAG#v}"
python3 "${REPO_ROOT}/scripts/ci/sync_version.py"

# shellcheck source=install_godot_linux.sh
source "${SCRIPT_DIR}/install_godot_linux.sh"

bash "${SCRIPT_DIR}/android_export_prep.sh"

ARTIFACT_DIR="${REPO_ROOT}/artifacts"
mkdir -p "${ARTIFACT_DIR}" "${REPO_ROOT}/export_build/web" "${REPO_ROOT}/export_build/windows" "${REPO_ROOT}/export_build/macos" "${REPO_ROOT}/export_build/android"

if [ ! -f "${REPO_ROOT}/export_presets.cfg" ]; then
	echo "Missing export_presets.cfg" >&2
	exit 1
fi

echo "Importing assets..."
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --import --quit

echo "Export Web..."
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --export-release "Web" "${REPO_ROOT}/export_build/web/wildpiggun.html"
WEB_DIR="${REPO_ROOT}/export_build/web"
cp -f "${WEB_DIR}/wildpiggun.html" "${WEB_DIR}/index.html"
cat > "${WEB_DIR}/_headers" << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF
( cd "${WEB_DIR}" && zip -r -q "${ARTIFACT_DIR}/WildPigGun-${RELEASE_VERSION}-web.zip" . )

echo "Export Windows Desktop..."
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --export-release "Windows Desktop" "${REPO_ROOT}/export_build/windows/WildPigGun.exe"
( cd "${REPO_ROOT}/export_build/windows" && zip -r -q "${ARTIFACT_DIR}/WildPigGun-${RELEASE_VERSION}-windows-x86_64.zip" . )

echo "Export macOS..."
MAC_PRESET_PATH="${REPO_ROOT}/export_build/macos/WildPigGun-macos-universal-${RELEASE_VERSION}.zip"
mkdir -p "${REPO_ROOT}/export_build/macos"
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --export-release "macOS" "${MAC_PRESET_PATH}"
cp -f "${MAC_PRESET_PATH}" "${ARTIFACT_DIR}/WildPigGun-${RELEASE_VERSION}-macos-universal.zip"

echo "Export Android (arm64+v7 universal APK)..."
ANDROID_OUT="${REPO_ROOT}/export_build/android/WildPigGun-android-${RELEASE_VERSION}-universal.apk"
mkdir -p "${REPO_ROOT}/export_build/android"
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --export-release "Android" "${ANDROID_OUT}"
cp -f "${ANDROID_OUT}" "${ARTIFACT_DIR}/WildPigGun-${RELEASE_VERSION}-android-universal.apk"

echo "Artifacts:"
ls -la "${ARTIFACT_DIR}"
