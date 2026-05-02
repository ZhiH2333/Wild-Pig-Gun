#!/bin/bash
# macOS：清除 godot-webview GDExtension 的 quarantine 属性并重置签名
# 在项目根目录执行：bash scripts/fix_macos_webview_signing.sh

set -e
cd "$(dirname "$0")/.."

echo "[1/3] 清除 addons/webview/ 下所有文件的隔离属性..."
xattr -dr com.apple.quarantine addons/webview/ || true

echo "[2/3] 重置主 dylib 签名..."
for f in addons/webview/*.dylib; do
  install_name_tool -change 'a' 'a' "$f" && echo "  ok: $f" || echo "  skip: $f"
done

echo "[3/3] 清除 Qt frameworks 隔离属性..."
BASE_DIR="$(pwd)/addons/webview/macos_arm64-runtime/lib"
if [ -d "$BASE_DIR" ]; then
  find "$BASE_DIR" -name "*.framework" -print0 | while IFS= read -r -d $'\0' fw; do
    sudo xattr -dr com.apple.quarantine "$fw" 2>/dev/null || true
  done
fi

echo "完成！现在可以正常启动 Godot 编辑器。"
