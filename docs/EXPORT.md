# WildPigGun 导出说明

更完整的发版流程（Tag、GitHub Actions、Netlify 密钥）见 **[docs/RELEASE.md](RELEASE.md)**。

## 桌面（Windows / macOS / Linux）

1. Godot 4.6：项目 → 导出，添加对应平台预设。
2. 主场景：`main_menu.tscn`（`project.godot` 中 `run/main_scene` 已指向主菜单 UID）。
3. 全屏选项由设置页写入 `user://game_settings.json`，依赖 `DisplayServer`。

## Web

1. 导出为 Web，模板需与引擎版本一致。
2. 失焦暂停：由 `GameFlow` 在 Web 平台监听 `NOTIFICATION_APPLICATION_FOCUS_OUT/IN`。
3. 性能与包体：请在目标浏览器实测 FPS；剔除未使用资源以控制下载体积。
4. **跨源隔离**：Godot 4 Web 需要 **`COOP: same-origin`** + **`COEP: require-corp`**，否则可能无法加载 WASM。Netlify 构建脚本 `scripts/ci/netlify_build_web.sh` 会在产物目录写入 **`_headers`**；本地可参考该文件手动配置任意静态托管。

## Android

1. 导出 APK/AAB，启用 `Internet` 等所需权限（若仅本地游玩可最小权限）。
2. 包名：`com.wildpiggun.game`（与导出预设一致）。
3. 虚拟摇杆：`VirtualJoystick` 仅在 `OS.has_feature("android")` 为真时显示；移动逻辑在 `player.gd` 中与键盘合并。
4. 建议真机测试：波间商店按钮触控区域、全屏安全区。

## 数据文件

运行时读取 `res://data/*.json`；修改后需重新导出或随 PCK 发布。
