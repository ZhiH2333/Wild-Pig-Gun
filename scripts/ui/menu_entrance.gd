extends RefCounted
class_name MenuEntrance

## 与压暗主菜单相近的实色遮罩（非纯黑），减少闪屏与刺眼感
const COVER_COLOR := Color(0.056, 0.048, 0.042, 1.0)
## 启动页：切场景前淡入同色遮罩，盖住可能的引擎清屏帧
const PRE_SCENE_SWITCH_SEC := 0.28
## 主菜单：自遮罩渐显（时间较长）
const ENTRANCE_REVEAL_SEC := 1.28
