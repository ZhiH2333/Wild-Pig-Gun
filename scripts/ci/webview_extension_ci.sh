#!/usr/bin/env bash
# Linux CI / Netlify 无仓库内 Linux WebView 二进制时，暂时移走 gdextension，避免 --import / --export 报错。
# 游戏逻辑已通过 ClassDB.class_exists("WebView") 分支降级。
set -euo pipefail

ci_webview_extension_disable() {
	local ext="${REPO_ROOT}/addons/webview/webview.gdextension"
	local off="${REPO_ROOT}/addons/webview/webview.gdextension.off-ci"
	if [[ -f "${ext}" ]]; then
		mv "${ext}" "${off}"
		trap ci_webview_extension_restore EXIT INT HUP TERM
	fi
}

ci_webview_extension_restore() {
	local ext="${REPO_ROOT}/addons/webview/webview.gdextension"
	local off="${REPO_ROOT}/addons/webview/webview.gdextension.off-ci"
	if [[ -f "${off}" ]]; then
		mv -f "${off}" "${ext}"
	fi
	trap - EXIT INT HUP TERM
}
