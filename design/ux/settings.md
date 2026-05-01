# UX Spec：设置（Settings）

> **状态**：进行中（视觉统一已落地）  
> **模板**：UX Spec（节选 — 以视觉与主题一致性为主）  
> **最后更新**：2026-05-01  

---

## 目的与玩家需求

玩家在设置中调整音频、显示、控制、游戏选项与数据管理；界面需在**不改变布局结构**的前提下，与主菜单级黑底白边按钮、页签主题在**同一视觉语言**内，降低「按钮一套、表单另一套」的割裂感。

---

## 视觉系统（与 `black_button_theme` / `settings_tab_theme` 对齐）

以下为本屏**权威样式来源**（实现见 `themes/*.tres` 与 `scenes/settings.tscn`）。

| 区域 | 主题资源 | 说明 |
|------|----------|------|
| 顶栏「返回」及需强调的操作按钮 | `themes/black_button_theme.tres` | 黑半透明底 `rgba(0,0,0,0.55)`、**1px 白描边**、圆角 **2**；悬停浅白底 + 黑字；按下白底 + 黑字。 |
| 自定义页签按钮（脚本覆盖样式） | `themes/settings_tab_theme.tres` + `settings_screen.gd` 中 `_build_tab_button_styles` | 与 tres 同色值、**无边框**；激活 Tab 白底黑字，未激活黑半透明底白字。 |
| 页签下方表单区（滑条、下拉、复选框、滚动条、下拉弹层） | `themes/settings_panel_theme.tres`（挂于 `SettingsTabContainer`） | 与上两者**同一套色板**：黑半透明底、白描边、圆角 **2**；滑块轨道/拖块/已填区域为黑白对比；`OptionButton` 与 `black_button` 的 normal/hover/pressed 逻辑一致；`TabContainer` 内容底板为**全透明**，避免继承全局 `game_ui_theme` 的金边 Tab 底板。 |

### 文案与标签色（保持现有场景覆盖）

- **标题**：`Label` 暖白（场景内已有 `theme_override_colors`）。  
- **分区提示**（如「音量与混音总线」）：muted 金棕 `Color(0.78, 0.72, 0.55)`。  
- **数据危险区**：沿用现有红系提示与 `self_modulate`，仅作语义强调，不改为灰蓝通用控件色。

### 明确不改动

- **布局**：`MarginContainer` / `VBoxContainer` / `HBoxContainer` / `ScrollContainer` / `TabContainer` 的尺寸与层级不变。  
- **页签交互逻辑**：仍由脚本切换 `TabContainer.current_tab` 与自定义 Tab 样式。

---

## 实现要点（供 UI 程序对照）

1. 根节点 `Settings` 仍使用 `game_ui_theme.tres`，仅对 **`SettingsTabContainer` 子树**挂载 `settings_panel_theme.tres`，使滑条/下拉/复选与按钮家族一致，而不影响顶栏已单独指定主题的控件。  
2. 对话框（清除确认、结果弹层）继续使用 `black_button_theme` 的按钮，与顶栏一致。  
3. 若未来新增设置项控件类型，优先在 `settings_panel_theme.tres` 中扩展，保持与 `black_button_theme` 的 normal/hover/pressed/disabled 语义一致。

---

## 验收标准（视觉）

- [ ] 五个页签下方区域内，**所有** `HSlider`、`OptionButton`、`CheckBox`、纵向滚动条与下拉弹层无「灰蓝大圆角」残留，整体为黑底白边、小圆角（约 2px）语言。  
- [ ] `OptionButton` 打开的下拉列表背景为深色 + 白边，与按钮态可读性一致。  
- [ ] 页签与顶栏「返回」在并排对比时，色相统一为黑白对比系，而非蓝灰游戏 UI 色。  
- [ ] 不改变各 Tab 内控件排列、最小高度与 `custom_minimum_size` 逻辑。  
- [ ] 数据清除相关红色强调与教程/网页隐藏逻辑行为与改主题前一致。

---

## 开放问题

- 若需在**游戏内覆盖层**打开同一设置场景，确认覆盖层根是否额外套主题 — 当前以场景内 `SettingsTabContainer` 挂载为准。

---

## 交叉引用

- 主题源文件：`themes/black_button_theme.tres`、`themes/settings_tab_theme.tres`、`themes/settings_panel_theme.tres`  
- 场景：`scenes/settings.tscn`  
- 逻辑：`scripts/ui/settings_screen.gd`（页签样式与 `settings_tab_theme` 对齐注释）
