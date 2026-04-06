extends RefCounted
class_name AttackRangeBalance

## 攻击范围平衡参数：在此调节默认半径、商店增量与 R 键预览虚线样式

## 基础半径（像素），不含商店/调试加成
const BASE_RADIUS_PX: float = 540.0
## 商店单次「攻击范围」物品增加量（须与 data/shop_items.json 中 value 一致）
const SHOP_BONUS_RADIUS_PX: float = 52.0
## 有效半径下限（防止调试/存档写成极小值）
const MIN_RADIUS_PX: float = 120.0
## 按住 R 时红色虚线：圆周细分段总数（越大越圆）
const PREVIEW_CIRCLE_SEGMENTS: int = 96
## 虚线：连续短划占的细分段数
const PREVIEW_DASH_SEGMENTS: int = 5
## 虚线：间隔占的细分段数
const PREVIEW_GAP_SEGMENTS: int = 4
## 预览线宽（像素）
const PREVIEW_LINE_WIDTH: float = 2.0
## 预览颜色（红色虚线）
const PREVIEW_COLOR: Color = Color(0.95, 0.16, 0.12, 0.9)
