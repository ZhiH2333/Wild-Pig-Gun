extends Object
class_name GameCollisionLayers

## 2D 物理层（bit）：1=player，2=enemy，3=player_bullet，4=enemy_bullet，5=wall
const LAYER_PLAYER: int = 1
const LAYER_ENEMY: int = 2
const LAYER_PLAYER_BULLET: int = 4
const LAYER_ENEMY_BULLET: int = 8
const LAYER_WALL: int = 16

## 子弹 mask（与策划一致）
const MASK_PLAYER_BULLET: int = LAYER_ENEMY | LAYER_WALL
const MASK_ENEMY_BULLET: int = LAYER_PLAYER | LAYER_WALL

## 角色：在子弹规则基础上增加墙体与彼此 CharacterBody 碰撞（否则无法挤墙/接触伤害）
const MASK_PLAYER_BODY: int = LAYER_ENEMY | LAYER_ENEMY_BULLET | LAYER_WALL
const MASK_ENEMY_BODY: int = LAYER_PLAYER | LAYER_PLAYER_BULLET | LAYER_WALL
## 场地边界：阻挡玩家、敌人、双方子弹
const MASK_WALL: int = LAYER_PLAYER | LAYER_ENEMY | LAYER_PLAYER_BULLET | LAYER_ENEMY_BULLET
