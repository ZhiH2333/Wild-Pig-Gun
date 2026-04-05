extends Area2D
class_name Projectile

## 子弹脚本：直线飞行，按阵营命中目标，飞出屏幕后自动销毁
## 需求：2.4、2.5、2.6

const ENEMY_BULLET_TEXTURE: Texture2D = preload("res://assets/sprites/enemy_bullets.png")

const TEAM_PLAYER: StringName = &"player"
const TEAM_ENEMY: StringName = &"enemy"
const DEFAULT_SPEED: float = 400.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
## 发射方阵营：player 只伤害 enemies；enemy 只伤害 player
var team: StringName = TEAM_PLAYER
var speed: float = DEFAULT_SPEED
## 额外穿透目标数，总命中次数 = 1 + pierce_extra（仅玩家弹）
var pierce_extra: int = 0
var _hits_remaining: int = 1
var _damaged_ids: Dictionary = {}
var damage_element: StringName = &"physical"

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if team == TEAM_PLAYER:
		_hits_remaining = 1 + maxi(0, pierce_extra)
	else:
		_hits_remaining = 1
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	_setup_visual()


func _setup_visual() -> void:
	if _sprite == null:
		return
	if team == TEAM_ENEMY:
		_sprite.texture = ENEMY_BULLET_TEXTURE
		var th: float = float(ENEMY_BULLET_TEXTURE.get_height())
		var target_h: float = 14.0
		_sprite.scale = Vector2.ONE * (target_h / maxf(1.0, th))
		_sprite.rotation = direction.angle()
	else:
		_sprite.texture = null


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


## 玩家弹：按元素着色圆点；敌人弹使用 Sprite2D 贴图
func _draw() -> void:
	if team == TEAM_ENEMY:
		return
	var c: Color = Color(1, 1, 0.4, 1.0)
	if damage_element == &"fire":
		c = Color(1.0, 0.45, 0.12, 1.0)
	elif damage_element == &"ice":
		c = Color(0.55, 0.85, 1.0, 1.0)
	elif damage_element == &"poison":
		c = Color(0.45, 0.95, 0.35, 1.0)
	elif damage_element == &"shock":
		c = Color(0.95, 0.95, 0.35, 1.0)
	draw_circle(Vector2.ZERO, 5.0, c)


## 命中物体时：仅对敌对阵营造成伤害并销毁自身
func _on_body_entered(body: Node2D) -> void:
	if team == TEAM_PLAYER:
		if not body.is_in_group("enemies"):
			return
		var bid: int = body.get_instance_id()
		if _damaged_ids.has(bid):
			return
		_damaged_ids[bid] = true
		if body.has_method("take_damage"):
			var dmg_base: int = damage
			var pl: Node = get_tree().get_first_node_in_group("player")
			if damage_element == &"fire" and pl != null and "stat_fire_damage_mult" in pl:
				dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_fire_damage_mult))))
			elif damage_element == &"ice" and pl != null and "stat_ice_damage_mult" in pl:
				dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_ice_damage_mult))))
			elif damage_element == &"poison" and pl != null and "stat_poison_damage_mult" in pl:
				dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_poison_damage_mult))))
			elif damage_element == &"shock" and pl != null and "stat_shock_damage_mult" in pl:
				dmg_base = maxi(1, int(round(float(damage) * float(pl.stat_shock_damage_mult))))
			var final_dmg: int = dmg_base
			var is_crit: bool = false
			if pl != null and "stat_crit_chance" in pl and "stat_crit_mult" in pl:
				var roll: Dictionary = CombatMath.roll_damage_with_crit(
					dmg_base,
					float(pl.stat_crit_chance),
					float(pl.stat_crit_mult)
				)
				final_dmg = int(roll["damage"])
				is_crit = bool(roll["is_crit"])
			body.take_damage(final_dmg, is_crit, damage_element)
			if damage_element == &"fire" and body.has_method("apply_status_burn"):
				var pl2: Node = get_tree().get_first_node_in_group("player")
				var bdps: float = 2.0
				if pl2 != null and "stat_burn_dps_flat" in pl2:
					bdps += float(pl2.stat_burn_dps_flat)
				body.call("apply_status_burn", bdps, 3.2)
			elif damage_element == &"ice" and body.has_method("apply_status_slow"):
				var pl3: Node = get_tree().get_first_node_in_group("player")
				var dur: float = 2.6
				if pl3 != null and "stat_ice_duration_bonus" in pl3:
					dur += float(pl3.stat_ice_duration_bonus)
				body.call("apply_status_slow", 0.68, dur)
			elif damage_element == &"poison" and body.has_method("apply_status_poison"):
				var pl4: Node = get_tree().get_first_node_in_group("player")
				var pdps: float = 1.1
				var pdur: float = 4.0
				if pl4 != null:
					if "stat_poison_dps_flat" in pl4:
						pdps += float(pl4.stat_poison_dps_flat)
					if "stat_poison_duration_pct" in pl4:
						pdur *= 1.0 + float(pl4.stat_poison_duration_pct)
				body.call("apply_status_poison", pdps, pdur)
			elif damage_element == &"shock" and body.has_method("apply_status_shock_vuln"):
				var pl5: Node = get_tree().get_first_node_in_group("player")
				var sv: float = 0.14
				if pl5 != null and "stat_shock_vuln_apply_flat" in pl5:
					sv += float(pl5.stat_shock_vuln_apply_flat)
				body.call("apply_status_shock_vuln", sv, 4.5)
		_hits_remaining -= 1
		if _hits_remaining <= 0:
			queue_free()
		return
	if team == TEAM_ENEMY:
		if not body.is_in_group("player"):
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()


## 飞出屏幕时销毁自身，防止内存泄漏
func _on_screen_exited() -> void:
	queue_free()
