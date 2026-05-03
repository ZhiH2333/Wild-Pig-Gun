# UX Spec：开局前选角与初始武器（Pre-Start）

> **Status**: Draft  
> **Last Updated**: 2026-05-03  
> **Scene**: `scenes/pre_start.tscn`  
> **Script**: `scripts/ui/pre_start.gd`

## 武器卡文案

- 武器卡正文与「特效」行必须来自 `data/weapons.json` 的 `card_desc`/`short_desc` 与 `effect_note`，与策划 HTML「初始武器」`fx-badge` **逐字一致**（由数据侧保证，UI 不做改写）。

## 验收要点（节选）

- [ ] 切换武器时，右侧「属性 / 特效」区与卡片上的「特效：」行与 JSON 一致。  
- [ ] 12 把初始武器均显示独立 `effect_note`，无占位符「—」。  
- [ ] 进入战斗后，各 `weapon_id` 的枪口 / 弹体 / 近战表现与 `effect_note` 语义一致（由玩法层 `WeaponFxProfiles` + 弹体脚本保证）。
