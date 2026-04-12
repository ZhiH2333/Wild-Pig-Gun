# WildPigGun 导出说明

## 桌面（Windows / macOS / Linux）

1. Godot 4.6：项目 → 导出，添加对应平台预设。
2. 主场景：`main_menu.tscn`（`project.godot` 中 `run/main_scene` 已指向主菜单 UID）。
3. 全屏选项由设置页写入 `user://game_settings.json`，依赖 `DisplayServer`。

## Web

1. 导出为 Web，模板需与引擎版本一致。
2. 失焦暂停：由 `GameFlow` 在 Web 平台监听 `NOTIFICATION_APPLICATION_FOCUS_OUT/IN`。
3. 性能与包体：请在目标浏览器实测 FPS；剔除未使用资源以控制下载体积。
4. **托管到 Cloudflare Pages**：Godot 4 Web 导出默认要求 **跨源隔离**（`COOP: same-origin` + `COEP: require-corp`），否则可能无法加载 WASM。仓库提供脚本 `scripts/cloudflare-pages-deploy.sh`：会把导出目录中的 `wildpiggun.html` 复制为 **`index.html`**，并写入 **`_headers`** 后执行 `wrangler pages deploy`。
   - 首次需登录：`npx wrangler login`（在能打开浏览器的机器上完成 OAuth）。
   - 或使用 **API Token**（推荐 CI）：在环境变量中设置 `CLOUDFLARE_API_TOKEN`，需包含 **Account → Cloudflare Pages → Edit** 等权限。
   - 自定义导出路径：`WEB_EXPORT_DIR=/你的/web导出目录 ./scripts/cloudflare-pages-deploy.sh`
   - 自定义项目名：`PROJECT_NAME=你的-pages项目名 ./scripts/cloudflare-pages-deploy.sh`

## Android

1. 导出 APK/AAB，启用 `Internet` 等所需权限（若仅本地游玩可最小权限）。
2. 虚拟摇杆：`VirtualJoystick` 仅在 `OS.has_feature("android")` 为真时显示；移动逻辑在 `player.gd` 中与键盘合并。
3. 建议真机测试：波间商店按钮触控区域、全屏安全区。

## 数据文件

运行时读取 `res://data/*.json`；修改后需重新导出或随 PCK 发布。
