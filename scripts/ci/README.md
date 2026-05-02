# CI / 发行脚本

| 文件 | 说明 |
|------|------|
| `sync_version.py` | 根据环境变量 `RELEASE_VERSION`（`X.Y.Z`）写入 `project.godot` 与 `export_presets.cfg`。 |
| `install_godot_linux.sh` | 下载 Godot 4.6 与导出模板（Linux）；供 Netlify / GitHub Actions `source`。 |
| `release_export.sh` | Actions：导入资源并导出 Web / Windows / macOS / Android，输出到仓库根目录 `artifacts/`。 |
| `netlify_build_web.sh` | Netlify：同步版本后导出 Web 到 `dist/`（含 `index.html`、`_headers`）。 |
| `android_export_prep.sh` | 若无 keystore，则用 `keytool` 在 `export_build/keys/` 生成 CI 用签名库。 |
| `webview_extension_ci.sh` | 在 Linux headless 导出前暂时移走 `webview.gdextension`（仓库未含 Linux `.so` 时避免加载失败）。 |

游戏逻辑脚本仍在上一级 `scripts/`（如 `scripts/player/`、`scripts/ui/`）。
