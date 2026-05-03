extends RefCounted
class_name WeaponFxProfiles

## 静态表：供弹体与枪口 FX 读取

## 按 weapon_id 驱动弹体与枪口表现；未知 id 回退为仅元素色圆点。


static func profile(weapon_id: String) -> Dictionary:
	match weapon_id:
		"crude_pistol":
			return {
				"trail_segments": 5,
				"trail_width": 2.0,
				"trail_color": Color(0.92, 0.88, 0.72, 0.35),
				"core_scale": 1.0,
				"glow_scale": 1.15,
				"muzzle_smoke": true,
				"muzzle_shell": true,
			}
		"wild_shotgun":
			return {
				"trail_segments": 11,
				"trail_width": 4.0,
				"trail_color": Color(1.0, 0.52, 0.08, 0.78),
				"core_scale": 0.92,
				"glow_scale": 1.35,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
		"spin_revolver":
			return {
				"trail_segments": 6,
				"trail_width": 2.2,
				"trail_color": Color(1.0, 0.92, 0.55, 0.45),
				"core_scale": 1.05,
				"glow_scale": 1.25,
				"muzzle_smoke": false,
				"muzzle_shell": true,
			}
		"electric_gun":
			return {
				"trail_segments": 7,
				"trail_width": 2.8,
				"trail_color": Color(0.35, 0.65, 1.0, 0.82),
				"core_scale": 1.12,
				"glow_scale": 1.6,
				"chain_lightning": true,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
		"feather_bow":
			return {
				"trail_segments": 16,
				"trail_width": 2.4,
				"trail_color": Color(0.25, 0.88, 0.42, 0.72),
				"core_scale": 1.0,
				"glow_scale": 1.2,
				"charge_glow": true,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
		"fire_snout":
			return {
				"trail_segments": 14,
				"trail_width": 5.0,
				"trail_color": Color(1.0, 0.38, 0.05, 0.55),
				"core_scale": 1.15,
				"glow_scale": 1.7,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
		"magnetic_cannon":
			return {
				"trail_segments": 8,
				"trail_width": 3.2,
				"trail_color": Color(0.45, 0.78, 1.0, 0.65),
				"core_scale": 1.35,
				"glow_scale": 1.85,
				"magnetic_ring": true,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
		"frost_sprayer":
			return {
				"trail_segments": 12,
				"trail_width": 3.0,
				"trail_color": Color(0.82, 0.94, 1.0, 0.7),
				"core_scale": 1.05,
				"glow_scale": 1.4,
				"snow_sparkle": true,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
		"boar_grenade":
			return {
				"trail_segments": 9,
				"trail_width": 3.5,
				"trail_color": Color(1.0, 0.55, 0.15, 0.5),
				"core_scale": 1.45,
				"glow_scale": 1.5,
				"grenade_arc": true,
				"muzzle_smoke": true,
				"muzzle_shell": false,
			}
		"sniper_chicken":
			return {
				"trail_segments": 20,
				"trail_width": 2.6,
				"trail_color": Color(1.0, 0.12, 0.12, 0.88),
				"core_scale": 1.1,
				"glow_scale": 1.3,
				"sniper_hitstop": true,
				"sniper_laser": true,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
		_:
			return {
				"trail_segments": 5,
				"trail_width": 0.0,
				"trail_color": Color(1, 1, 1, 0.0),
				"core_scale": 1.0,
				"glow_scale": 1.0,
				"muzzle_smoke": false,
				"muzzle_shell": false,
			}
