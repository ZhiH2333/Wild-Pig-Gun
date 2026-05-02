# UX Spec：主菜单版本与检查更新

> **Status**: Implemented（`scenes/main_menu.tscn`、`scripts/ui/main_menu.gd`、设置「游戏」页）  
> **Last Updated**: 2026-05-02  
> **Journey Phase(s)**: 主菜单 / 设置 / 局外  
> **Related**: `scenes/char_gallery.tscn`（遮罩与卡片气质参考）

---

## Purpose & Player Need

玩家需要知道**当前安装版本**，主动对照线上仓库发布标签；若落后则明确提示，并一键在浏览器打开**对应该 tag 的 GitHub 下载页**。不要求应用内静默更新或自动下载安装包。

---

## 设置：更新渠道（「游戏」页签）

| 选项 | 行为 |
|------|------|
| **正式版（仅 Release）** | 调用 GitHub `GET .../releases/latest`（官方「最新正式版」，不含预发布）。若无正式版可能返回 404。 |
| **测试版（含预发布）** | 调用 `GET .../releases?per_page=1`，取时间线上**最新一条**（可为 Pre-release）。 |

持久化：`GameSettings.update_channel` → `user://game_settings.json` 字段 `update_channel`（`stable` / `prerelease`）。

---

## 结果弹层内容（成功）

卡片约 **960px** 宽，**左右分栏**（中间竖线分隔）：

- **整行顶部**：标题 **版本信息**。  
- **左栏**：**当前版本**（与角标一致）、**最新版本**（`tag_name`）、条件显示 **您的版本已落后！**、**LinkButton**「在浏览器中打开**最新版本**的 GitHub 下载页」→ `https://github.com/ZhiH2333/Wild-Pig-Gun/releases/tag/{tag}`（`tag` URI 编码）。  
- **右栏**：小标题 **更新日志**；`ScrollContainer` + `RichTextLabel`（`bbcode_enabled = false`）展示 GitHub API 返回的 **`body`**（仓库里写的 Release 说明，按纯文本显示 Markdown 源码）；无正文时显示「（此版本未填写更新说明）」。  
- **底部**：**确定** 关闭遮罩。

失败时：标题「检查更新」、居中错误说明；隐藏整段分栏（`BodySplit`）。

---

## Layout Zones

- **主菜单右下角**：版本 `Label` + 「检查更新」`Button`。  
- **弹层**：Dim 0.62、Vignette 0.18、居中加宽大圆角卡片；与 `char_gallery` 气质一致；成功态为左右分栏 + 右侧可滚动更新日志。

---

## Interaction Map

| 组件 | 操作 | 结果 |
|------|------|------|
| 检查更新 | 按下 | 按 `GameSettings.update_channel` 选择 API URL；`HTTPRequest` GET；按钮 `disabled` 至结束 |
| 下载链接 | 按下 | `OS.shell_open(uri)`（Godot `LinkButton` 默认行为） |
| 确定 | 按下 | 关闭遮罩 |

---

## Platform 说明

- **桌面 / Android**：直连 `api.github.com` 可行；请求需带 `User-Agent`。  
- **Web**：可能受 CORS 限制，需代理或静态 JSON（未实现）。

---

## Acceptance Criteria

- [ ] 「游戏」页可切换正式版 / 测试版渠道，重进设置后保持。  
- [ ] 正式版仅反映 GitHub latest 正式 release；测试版反映列表首条（可含预发布）。  
- [ ] 成功弹窗为左右分栏：左侧版本信息与「最新版本」下载链接；右侧展示 GitHub `body` 更新日志（可滚动）。  
- [ ] 成功弹窗含当前版本、最新版本、落后提示（仅落后时）、下载链接正确指向 `/releases/tag/{tag}`。  
- [ ] 失败时隐藏分栏与更新日志，仅错误说明，确定可关闭。  
- [ ] 请求进行中不可重复触发检查更新。
