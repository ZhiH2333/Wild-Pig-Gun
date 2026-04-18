#!/usr/bin/env bash
set -euo pipefail
# 在 CI/无界面导出前生成 Android release 签名库（密码与 export_presets.cfg 一致）。
# 密钥仅用于自动化构建产物；上架 Play 请换正式密钥。

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
