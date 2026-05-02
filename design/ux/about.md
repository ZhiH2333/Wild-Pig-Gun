# UX Spec：关于（About）

> **状态**：已与场景对齐  
> **最后更新**：2026-05-02  
> **模板**：UX Spec（实现摘要）

---

## 目的与玩家需求

玩家从主菜单进入「关于」，快速了解游戏简介、作者与仓库链接并返回；界面需与**设置 / 个性化**同一套左侧栏 + 顶栏 + 内容卡布局，无分页签，减少认知负担。

---

## 布局与信息架构（参考 `settings.tscn`、`char_gallery.tscn`）

| 区域 | 说明 |
|------|------|
| 全屏 | `BlurredBackground`（清晰底图、无模糊材质）+ `DimOverlay` `Color(0,0,0,0.62)` + `Vignette`，与设置/画廊 / 暂停遮罩同款；详见 `design/ux/menu-screen-backdrop.md` |
| `Center` | `MarginContainer`，左侧半屏内容区（`anchor_right = 0.5`），边距与设置一致 |
| 顶栏 | `HBoxContainer`：**返回**（`black_button_theme` + 返回图标）+ 标题 **「关于」** |
| 主内容 | `MainCard` 透明底板 + 内边距 22/20，内嵌 **单栏** `ScrollContainer`（无 Tab、无 `TabButtonRow`） |
| 滚动区 | 游戏图标与文案 → 作者 → 鸣谢 → 项目仓库；链接为全宽按钮 |

---

## 交互与主题

- **返回**：仅顶栏一处；`themes/black_button_theme.tres`，`SourceHanSansSC-Bold`、字号 24，带 `icon_back.svg`。
- **外链按钮**（作者 GitHub、仓库）：同一 `black_button_theme`，左对齐文案，最小高度约 48，点击仍由 `about_screen.gd` 调用 `OS.shell_open`。
- **不使用**：自定义紫灰「链接条」StyleBox；不使用底部第二条「返回」。

---

## 导航

- **进入**：主菜单「关于我们」→ `res://scenes/about.tscn`
- **退出**：顶栏「返回」→ `main_menu.tscn`

---

## 验收要点

- [ ] 无 Tab 行；单滚动列展示全部信息。  
- [ ] 所有可点按钮（返回、两条链接）视觉上一致为黑底白边按钮族。  
- [ ] 布局与设置/画廊左侧栏、标题字号与暖白标题色一致。  

---

## 实现对照

- 场景：`scenes/about.tscn`  
- 脚本：`scripts/ui/about_screen.gd`（`%AuthorLinkBtn`、`%RepoLinkBtn`、`%BackButton`）  
- 主题：`themes/black_button_theme.tres`
