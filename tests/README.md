# Tests

GDUnit4 test suite for WildPigGun.

## Setup

Install the [GDUnit4](https://github.com/MikeSchulze/gdUnit4) plugin via the Godot Asset Library or by placing it in `addons/gdUnit4/`.

## Running Tests

Use the GDUnit4 panel in the Godot editor, or run via CLI:
```
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd
```

## 轻量数值校验（无 GDUnit4 时）

```bash
godot -s res://tests/balance_runner.gd
```

退出码 0 表示 `WaveData` 波次时长、`shop_price_scaled`、`cluster` batch、`pick_shop_offer` 确定性等检查通过。

## 手测清单（成品验收）

- [ ] 主菜单 → 选角 → 竞技场：第 1 波倒计时与刷怪正常。
- [ ] 波次结束：必须选升级后才可「开始下一波」；商店购买扣材料；标价随波次上涨；「刷新升级选项」消耗材料。
- [ ] 波次结束：若有收获属性，HUD 出现「收获 +N 材料」提示。
- [ ] 击杀获得经验；升级弹出独立三选一，可花材料刷新；Lv5/10/15/20 出现蓝档以上，Lv25+ 出现红档池。
- [ ] 多武器：商店购买「冲锋枪/铁锤」增加槽位；双「重型」标签激活时伤害协同（Debug 可看数值变化）。
- [ ] 第 9 / 15 波感知怪海（cluster）；含「强化图腾」时优先击杀外围图腾降低压力。
- [ ] 分裂怪死亡生成两只小怪；陷阱师在脚下放圈。
- [ ] 远程怪反制弹幕有间隔与次数上限，高攻速不致瞬间暴毙。
- [ ] 解锁「节俭者·猪」后：材料越多伤害越高、商店更贵、收获加成。
- [ ] 第 20 波结束后进入通关界面，存档中「通关次数」增加。
- [ ] 死亡结算返回主菜单，最高波次记录更新。
- [ ] ESC 暂停 / 继续；波间打开时 ESC 不改变波间暂停。
- [ ] 设置：主音量、全屏（桌面），重启后保留。
- [ ] Web：切换浏览器标签后游戏暂停，回到页签恢复（非波间）。
- [ ] Android：虚拟摇杆可见且可移动；商店按钮可点。
