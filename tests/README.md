# Tests

GDUnit4 test suite for WildPigGun.

## Setup

Install the [GDUnit4](https://github.com/MikeSchulze/gdUnit4) plugin via the Godot Asset Library or by placing it in `addons/gdUnit4/`.

## Running Tests

Use the GDUnit4 panel in the Godot editor, or run via CLI:
```
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd
```

## 手测清单（成品验收）

- [ ] 主菜单 → 选角 → 竞技场：第 1 波倒计时与刷怪正常。
- [ ] 波次结束：必须选升级后才可「开始下一波」；商店购买扣材料。
- [ ] 第 20 波结束后进入通关界面，存档中「通关次数」增加。
- [ ] 死亡结算返回主菜单，最高波次记录更新。
- [ ] ESC 暂停 / 继续；波间打开时 ESC 不改变波间暂停。
- [ ] 设置：主音量、全屏（桌面），重启后保留。
- [ ] Web：切换浏览器标签后游戏暂停，回到页签恢复（非波间）。
- [ ] Android：虚拟摇杆可见且可移动；商店按钮可点。
