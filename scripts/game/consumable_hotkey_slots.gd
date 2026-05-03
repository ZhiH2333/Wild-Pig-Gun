extends RefCounted
class_name ConsumableHotkeySlots

## 局内 1–6 键与触控条槽位对应的商店消耗品 id（与 arena 快捷键一致）

const SHOP_IDS: Array[String] = [
	"shop_medkit",
	"shop_grenade",
	"shop_smoke",
	"shop_emp",
	"shop_super_stim",
	"shop_master_key",
]


static func shop_id_for_slot_one_based(slot: int) -> String:
	var i: int = clampi(slot, 1, SHOP_IDS.size()) - 1
	return SHOP_IDS[i]
