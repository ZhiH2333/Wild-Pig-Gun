# godot-webview 多平台二进制说明

本仓库已包含 **macOS arm64** 的 `addons/webview`（用于桌面嵌入墨韵）。

若需在 **Windows x86_64** 或 **Linux x86_64 / arm64** 上运行嵌入 WebView，请从官网下载对应 zip 并覆盖 `addons/webview` 中与平台相关的库文件（保留 `webview.gdextension` 与脚本配置）。

官方下载页：<https://godotwebview.com/pages/downloads/>

直链示例（版本 `0.1.4`，以官网为准）：

- Windows x86_64: `https://godotwebview.com/downloads/gd-webview.0.1.4-windows-x86_64-release.zip`
- Linux x86_64: `https://godotwebview.com/downloads/gd-webview.0.1.4-linux-x86_64-release.zip`
- Linux arm64: `https://godotwebview.com/downloads/gd-webview.0.1.4-linux-arm64-release.zip`
- macOS arm64: `https://godotwebview.com/downloads/gd-webview.0.1.4-macos-arm64-release.zip`

解压后应存在 `addons/webview/webview.gdextension`。macOS 若无法加载，请按官网说明处理签名与隔离属性。

**Android / Web**：不依赖本扩展；Android 当前通过 `OS.shell_open` 打开系统浏览器；Web 使用 `JavaScriptBridge` 注入 iframe。
