#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRESET_FILE="${ROOT_DIR}/export_presets.cfg"
ANDROID_EXPORT_DIR="${ROOT_DIR}/export_build/android"
V8_OUTPUT="${ANDROID_EXPORT_DIR}/WildPigGun-android-1.0.0+4-v8a.apk"
V7_OUTPUT="${ANDROID_EXPORT_DIR}/WildPigGun-android-1.0.0+4-v7a.apk"
BACKUP_FILE="$(mktemp)"
cleanup() {
	cp -f "${BACKUP_FILE}" "${PRESET_FILE}"
	rm -f "${BACKUP_FILE}"
}
cp -f "${PRESET_FILE}" "${BACKUP_FILE}"
trap cleanup EXIT
mkdir -p "${ANDROID_EXPORT_DIR}"
python3 - <<'PY'
from pathlib import Path
p=Path("export_presets.cfg")
t=p.read_text(encoding="utf-8")
t=t.replace("architectures/armeabi-v7a=true","architectures/armeabi-v7a=false")
t=t.replace("architectures/arm64-v8a=true","architectures/arm64-v8a=true")
p.write_text(t,encoding="utf-8")
PY
/usr/local/bin/godot --headless --export-release "Android" "${V8_OUTPUT}"
python3 - <<'PY'
from pathlib import Path
p=Path("export_presets.cfg")
t=p.read_text(encoding="utf-8")
t=t.replace("architectures/arm64-v8a=true","architectures/arm64-v8a=false")
t=t.replace("architectures/armeabi-v7a=false","architectures/armeabi-v7a=true")
p.write_text(t,encoding="utf-8")
PY
/usr/local/bin/godot --headless --export-release "Android" "${V7_OUTPUT}"
cp -f "${BACKUP_FILE}" "${PRESET_FILE}"
rm -f "${BACKUP_FILE}"
trap - EXIT
