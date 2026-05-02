# 主菜单系全屏背景（与暂停遮罩对齐）

> **状态**：已与实现对齐  
> **最后更新**：2026-05-02（子页与暂停共用 `pause_overlay_background` LOD 模糊）  
> **模板**：交互模式摘录（Backdrop / Overlay）

---

## 用途

统一 **设置**、**个性化（角色画廊）**、**开始前（PreStart）**、**关于** 等使用 `mainmenu.png` 的全屏页：底图清晰；其上是与场内暂停 **同一着色器** `pause_overlay_background.gdshader`（mipmap `textureLod` 模糊）。子页使用 **`subpage_blur_mat.tres`**（`darken = 0`），压暗仍由 **`DimOverlay` `0.62`** 负责；场内暂停使用 **`pause_overlay_bg_material.tres`**（含 `darken`）。

---

## 层级（自下而上）

| 节点（典型命名） | 类型 | 说明 |
|------------------|------|------|
| `BlurredBackground` | `TextureRect` | 全屏 `mainmenu.png`，**无** `ShaderMaterial`（清晰底图）。 |
| `BackBufferCopy` | `BackBufferCopy` | `copy_mode = VIEWPORT(2)`，供屏幕纹理采样。 |
| `BlurBackdrop` | `ColorRect` | `subpage_blur_mat.tres`（与暂停同款 LOD 模糊，`darken = 0`）。 |
| `DimOverlay` | `ColorRect` | 全屏 **`Color(0, 0, 0, 0.62)`**（子页；场内暂停的压暗在材质 `darken` 内）。 |
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
| 场内暂停 | `scenes/arena.tscn` → `PauseOverlay`：`BackBufferCopy` + `Dim`（`pause_overlay_bg_material.tres`） |

---

## 性能与安全

- **性能**：单 pass，对 `screen_texture` 做一次 `textureLod`；`BackBufferCopy` 仅在当前场景可见帧绘制。`blur_lod` 越大越糊、略增采样成本；保持较低对 Web / 集显更友好。
- **泄漏**：无每帧 `load` 或手动 `ImageTexture` 分配；材质由场景引用，随场景释放由引擎回收，无典型 GPU/对象泄漏。

---

## 交叉引用

- 模糊材质仍可用于 **`scenes/char_select.tscn`** 等未迁移画面；新菜单页应以本文为准。
