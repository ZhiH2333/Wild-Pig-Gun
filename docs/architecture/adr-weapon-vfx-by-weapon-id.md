# ADR：武器表现由 weapon_id 与静态 FX 表驱动

- **状态**: Accepted  
- **日期**: 2026-05-03  

## 背景

弹体原仅按 `damage_element` 绘制单色圆点，无法在开局 UI 与战斗表现之间建立与策划案一致的「每武器可读特效」。

## 决策

1. `Projectile` 增加 `source_weapon_id`，由 `Weapon._spawn_projectile` 写入。  
2. 视觉参数集中在 `WeaponFxProfiles`（`scripts/weapons/weapon_fx_profiles.gd`），按 `weapon_id` 返回字典；未知 id 回退为无拖尾、仅元素色核心。  
3. 全屏短时反馈（狙击慢动作、屏震）经 `WeaponCameraFx`，避免散落修改 `Engine.time_scale`。  
4. 枪口一次性粒子 / 抛壳经 `WeaponMuzzleFx`，挂在武器节点或当前场景。  
5. 敌人燃烧 / 冻结叠层由 `EnemyBase` 状态 + `StatusVfxLayer` 子节点绘制，不侵入各敌人 `_draw` 身体几何。

## 后果

- 新增武器需在 `WeaponFxProfiles` 补充条目（及可选 JSON `effect_note`）。  
- 链电、榴弹 AOE 等会改变局部伤害分布，需随 `balance_runner` 与手感测试迭代。
