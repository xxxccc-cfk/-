# 第一阶段 / Prototype 0.2 实际验收报告

日期：2026-10-21（Asia/Shanghai）。Godot 4.7.2.stable.official.ed1daf0bf；Windows；Compatibility / OpenGL 3.3 / NVIDIA GeForce RTX 4060 Ti。

## 检查对象与完成范围

沿用现有 outputs/CultivationPrototype 项目，未重建。检查时已有地图、移动、镜头、碰撞、敌人、近远程战斗、生命与死亡、修炼及 27 项测试；上次中断前已接入的战斗反馈代码一并保留并完成验证。未新增依赖、付费工具或外部服务。

本阶段完成：反馈专项测试、PLAYING / DEAD 状态、单槽手动存档基础、正式方向与实现状态分离的设计文档。死亡不会自动重置世界；R 明确为测试场景重置而非正式转世。普通敌人保护 0.12 秒、玩家 0.5 秒、近战冷却 0.38 秒等既有数值不变。

## 实际执行结果

| 检查 | 结果 |
|---|---|
| 开始实施前原有基线 | 27 / 27 PASS |
| Test-Project.ps1 编辑器导入检查 | 退出码 0，无脚本解析错误 |
| smoke 基础与连续攻击回归 | 27 / 27 PASS，原脚本未修改 |
| feedback 表现生命周期与死亡清理 | 30 / 30 PASS |
| save 状态与持久化 | 34 / 34 PASS |
| 总计 | 91 / 91 PASS，三组 failures=0，测试脚本退出码 0 |
| 原有 capture.gd 图形检查 | 实际启动并写出截图，退出码 0 |
| 新增 capture_feedback.gd 图形检查 | 5 张截图写入均返回 OK，退出码 0 |
| 默认主场景启动 | 实际图形运行 120 帧后退出，退出码 0 |

实际截图已目视检查：中文 HUD、冷却条、挥剑与灵弹发射、敌人伤害数字/闪白、玩家红色受伤提示、敌人消散和死亡菜单显示正常。原有 27 项断言全部保留，没有跳过或改弱。

### 关键验证证据

- 连续近战：直接调用生命 60 → 35 → 35 → 35 → 10；按住攻击输入生命 60 → 35 → 35 → 10。等待引擎自然推进保护与冷却，不清零回归目标的受击状态。
- 特效不产生额外伤害；冷却中不重复发射特效；挥击、发射、伤害数字和消散均能清理。玩家受击保护内不再次触发红屏。
- 敌人死亡立即关闭 AI、碰撞和攻击目标资格，随后释放角色；仅表现节点继续短暂播放消散。
- 玩家死亡后原有敌人仍在，不自动刷新或重建地图。读取死亡快照仍为 0 生命，不自动复活。
- 快照经过真实磁盘写入、重复覆盖、校验后读回及新场景读取，恢复位置、生命、保护、冷却、修为和敌人状态；击杀的敌人不重生。
- 缺失、JSON 损坏、版本错误、字段类型错误、非法生命和墙内位置均被拒绝。拒绝读取不改变当前世界，拒绝写入不覆盖已有好档。写入失败返回错误。
- 真实输入动作 save/load 已覆盖，测试使用专用文件 automated-stage1-snapshot.json 并清理，不触碰用户 stage1-save.json。
- 加载立即停止旧弹体并清理瞬态；反复重置不会累加鼠标绑定。

## 逐项实际结果

### smoke：27 项

| 序号 | 与日志一致的测试名称 | 结果 |
|---|---|---|
| 1 | initial health | PASS |
| 2 | player configured protection is 0.5 seconds | PASS |
| 3 | movement through input | PASS |
| 4 | wall blocks movement | PASS |
| 5 | melee directional hit | PASS |
| 6 | melee cooldown | PASS |
| 7 | projectile physics hit | PASS |
| 8 | enemy contact damage | PASS |
| 9 | damage immunity | PASS |
| 10 | player protection still blocks damage after 0.25 seconds | PASS |
| 11 | player can take damage after protection expires | PASS |
| 12 | enemy configured protection is 0.12 seconds | PASS |
| 13 | regression first melee deals full 25 damage | PASS |
| 14 | regression melee during cooldown does not deal damage | PASS |
| 15 | enemy protection expires before melee cooldown | PASS |
| 16 | melee cooldown blocks damage even after enemy protection expires | PASS |
| 17 | regression melee cooldown expires naturally | PASS |
| 18 | regression second legal melee deals full 25 damage | PASS |
| 19 | held input first melee deals full damage | PASS |
| 20 | held input cannot bypass melee cooldown | PASS |
| 21 | held input second melee deals full damage after cooldown | PASS |
| 22 | cultivation interaction | PASS |
| 23 | cultivation rank progress | PASS |
| 24 | death and restart UI | PASS |
| 25 | dead player cannot move | PASS |
| 26 | scene restart resets health | PASS |
| 27 | restart resets enemies | PASS |

### feedback：30 项

| 序号 | 与日志一致的测试名称 | 结果 |
|---|---|---|
| 1 | cooldown bars initially ready | PASS |
| 2 | hurt overlay initially transparent | PASS |
| 3 | legal melee creates one slash effect | PASS |
| 4 | accepted hit shows actual damage number | PASS |
| 5 | hit updates health and starts white flash | PASS |
| 6 | blocked attack emits no extra slash or damage event | PASS |
| 7 | legal ranged attack creates muzzle effect | PASS |
| 8 | ranged cooldown blocks duplicate muzzle effect | PASS |
| 9 | cooldown bars display ongoing recovery | PASS |
| 10 | cooldown label displays remaining time | PASS |
| 11 | slash and muzzle effects expire | PASS |
| 12 | floating number remains during its lifetime | PASS |
| 13 | presentation effects never apply extra damage | PASS |
| 14 | floating number cleans itself up | PASS |
| 15 | cooldown bars return to ready | PASS |
| 16 | lethal hit immediately stops enemy AI | PASS |
| 17 | lethal hit immediately clears enemy collision | PASS |
| 18 | dead enemy immediately leaves target group | PASS |
| 19 | enemy death creates dissipation effect | PASS |
| 20 | overkill number uses actual remaining health | PASS |
| 21 | dead enemy cannot cause contact damage | PASS |
| 22 | dead enemy actor is freed | PASS |
| 23 | death feedback fully cleans itself up | PASS |
| 24 | accepted player damage triggers red overlay | PASS |
| 25 | immune damage neither repeats pulse nor removes health | PASS |
| 26 | red overlay expires independently of player protection | PASS |
| 27 | death enters dead session state | PASS |
| 28 | player death preserves remaining world enemies | PASS |
| 29 | explicit test reset removes old feedback | PASS |
| 30 | explicit test reset clears dead state and hurt overlay | PASS |

### save：34 项

| 序号 | 与日志一致的测试名称 | 结果 |
|---|---|---|
| 1 | initial live snapshot passes schema validation | PASS |
| 2 | missing snapshot gives recoverable error | PASS |
| 3 | snapshot writes to disk | PASS |
| 4 | saving again safely replaces existing snapshot | PASS |
| 5 | snapshot parses and validates after disk round trip | PASS |
| 6 | load fixture contains an active projectile | PASS |
| 7 | snapshot loads successfully | PASS |
| 8 | load immediately disables old projectile before deletion | PASS |
| 9 | load restores position and health | PASS |
| 10 | load restores cultivation progress | PASS |
| 11 | load preserves protection and attack cooldowns | PASS |
| 12 | defeated enemy stays absent after load | PASS |
| 13 | load restores surviving enemy health position home and protection | PASS |
| 14 | live snapshot restores playing session state | PASS |
| 15 | load removes obsolete transient effects and projectiles | PASS |
| 16 | incompatible snapshot rejected without changing world | PASS |
| 17 | negative health rejected | PASS |
| 18 | fractional health rejected | PASS |
| 19 | position inside wall rejected | PASS |
| 20 | wrong field type rejected | PASS |
| 21 | invalid enemy health rejected | PASS |
| 22 | invalid data cannot overwrite good snapshot | PASS |
| 23 | good on-disk snapshot survives rejected write | PASS |
| 24 | unwritable destination returns recoverable error | PASS |
| 25 | corrupt snapshot leaves running game unchanged | PASS |
| 26 | death preserves world in snapshot | PASS |
| 27 | dead world snapshot can be saved | PASS |
| 28 | initial fixture restores without rebuilding scene | PASS |
| 29 | loading dead snapshot does not resurrect player | PASS |
| 30 | loading dead snapshot does not reset world | PASS |
| 31 | new scene can restore saved dead world | PASS |
| 32 | scene reset does not duplicate mouse bindings | PASS |
| 33 | save action writes configured snapshot slot | PASS |
| 34 | load action restores configured snapshot slot | PASS |

## 实际修改文件

本轮开始时的文件哈希基线与最终文件已比较；以下为实际改动，不将已有反馈代码冒充新写。

| 文件 | 本轮改动 |
|---|---|
| scripts/world.gd | 接入状态与存档、保存/读取输入和提示、快照采集/恢复；明确测试重置语义；防止重复鼠标绑定 |
| scripts/projectile.gd | 添加弹体分组，供读档即时停止与清理 |
| scripts/game_state.gd | 新增独立会话状态 |
| scripts/save_store.gd | 新增版本化快照校验、临时文件写入及读回 |
| tests/feedback.gd | 新增 30 项反馈与死亡清理测试 |
| tests/save.gd | 新增 34 项状态与存档测试 |
| tests/capture_feedback.gd | 新增反馈与死亡画面截图检查 |
| Test-Project.ps1 | 运行全部三组断言，失败返回非零 |
| docs/DESIGN.md | 新增正式设计方向、占位规则、实现状态和后续边界 |
| README.md | 更新启动、操作、存档与当前限制 |
| TEST_REPORT.md | 更新为本报告及全部 91 项实际结果 |
| verification/ | 更新检查日志，新增反馈/存档日志及源码哈希清单 |
| preview.png / previews/*.png | 实际运行重新生成截图 |
| 新脚本对应的 *.gd.uid | Godot 自动生成的脚本标识 |

stats.gd、combat.gd、player.gd、enemy.gd、feedback.gd 中上次中断前已接入的 damaged 信号、视觉效果与敌人即时死亡清理，本轮完成测试且文件未改动。project.godot 已在上次工作中标为 0.2，本轮未再更改。原 smoke.gd 和 capture.gd 保留未改。

交付另生成 CultivationPrototype-stage1-0.2.zip，保留所有旧包；新包与当前源码、文档和日志逐文件核对，不包含 .godot 缓存、用户存档或引擎。

## 已知限制与验收边界

仍是固定小地图，敌人无绕障碍寻路、可重叠，无战利品、回血、音效、正式属性增长或完整开放世界。初始「炼气1层」是保留的占位，正式凡人起步、寿元、转世和世界长期演化均未实现。设计文档只记录方向，不宣称完成这些系统。

存档是手动单槽快照，没有自动保存、多槽、迁移、加密或离线推进；瞬态弹体与特效不持久化。人工 R 是显式测试重置，F9 可以回到旧快照，不代表正式死亡后的继承或回档规则已经确定。

自动化覆盖输入动作、真实物理帧和真实文件 IO，不能替代长时间人工移动瞄准、硬件鼠标点击、关闭进程后完整用户操作及其他平台验收。图形运行与图像目视检查已经完成；没有导出独立 EXE，也未做跨平台或长时间压力验证。

建议下一阶段先确认「凡人起步到首次突破」的一段完整规则，再逐步加入探索收益与成长闭环，不并行展开社会模拟。当前阶段停止，等待人工验收。
