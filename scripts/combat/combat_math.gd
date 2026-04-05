extends RefCounted
class_name CombatMath


static func roll_damage_with_crit(base_damage: int, crit_chance: float, crit_mult: float) -> Dictionary:
	var cch: float = clampf(crit_chance, 0.0, 1.0)
	var cm: float = maxf(1.0, crit_mult)
	var is_crit: bool = randf() < cch
	var out: int = base_damage
	if is_crit:
		out = maxi(1, int(round(float(base_damage) * cm)))
	return {"damage": out, "is_crit": is_crit}
