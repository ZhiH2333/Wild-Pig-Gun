#!/usr/bin/env bash
# 生成 Android release 签名库（与 export_presets.cfg 中密码一致）；已存在则跳过。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEY_DIR="${ROOT}/export_build/keys"
KEY_PATH="${KEY_DIR}/wildpiggun-release.keystore"
PASS="wildpiggun-ci-export"

mkdir -p "${KEY_DIR}"
if [ -f "${KEY_PATH}" ]; then
	exit 0
fi

keytool -genkeypair -v \
	-keystore "${KEY_PATH}" \
	-alias wildpiggun \
	-keyalg RSA -keysize 2048 -validity 10000 \
	-storepass "${PASS}" -keypass "${PASS}" \
	-dname "CN=WildPigGun, OU=CI, O=WildPigGun, L=Unknown, ST=Unknown, C=US"
