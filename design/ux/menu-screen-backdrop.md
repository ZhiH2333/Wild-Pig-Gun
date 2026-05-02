# 主菜单系全屏背景（与暂停遮罩对齐）

> **状态**：已与实现对齐  
> **最后更新**：2026-05-02  
> **模板**：交互模式摘录（Backdrop / Overlay）

---

## 用途

统一 **设置**、**个性化（角色画廊）**、**开始前（PreStart）**、**关于** 等使用 `mainmenu.png` 的全屏页：与场内暂停叠层 **同款** 的黑色半透明遮罩，**不再** 对底图使用模糊着色器。

---

## 层级（自下而上）

| 节点（典型命名） | 类型 | 说明 |
|------------------|------|------|
| `BlurredBackground` | `TextureRect` | 全屏 `mainmenu.png`，**无** `ShaderMaterial`（清晰底图）。 |
| `DimOverlay` | `ColorRect` | 全屏 **`Color(0, 0, 0, 0.62)`**，与 `arena.tscn` 中 `PauseOverlay/Dim` 一致。 |
| `Vignette` | `ColorRect`（可选） | 设置 / 画廊 / 关于保留全屏边缘压暗 `Color(0, 0, 0, 0.18)`；PreStart 无此项。 |

---

## 设置页：数据清除确认叠层

`DeleteConfirmOverlay` 内 **`RedBlurBackdrop`** 仅保留 **`ColorRect`** 着色（红调半透明），**不再** 挂载 `menu_blurred_bg_material`；与主画面同一原则（无模糊材质）。

---

## 实现对照

| 场景 | 路径 |
|------|------|
| 设置 | `scenes/settings.tscn` |
| 开始前 | `scenes/pre_start.tscn` |
| 个性化（画廊） | `scenes/char_gallery.tscn` |
| 关于 | `scenes/about.tscn` |
| 场内暂停 | `scenes/arena.tscn` → `PauseOverlay/Dim`（无底图，仅遮罩） |

---

## 交叉引用

- 模糊材质仍可用于 **`scenes/char_select.tscn`** 等未迁移画面；新菜单页应以本文为准。
