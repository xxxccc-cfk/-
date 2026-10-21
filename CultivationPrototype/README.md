# 修仙动作 RPG · 第一阶段 / Prototype 0.2

可运行的 Godot 4.x / GDScript 单机 2D 俯视角原型。保留既有地图、移动、战斗和修炼，补齐战斗反馈、场景状态和手动存档基础。无付费资产、插件或服务。

## 启动

本工作区双击 **Start-Game.cmd**；或在 PowerShell 中执行 `./Start-Game.ps1`。脚本默认使用工作区 `work/godot/Godot_v4.7.2-stable_win64_console.exe`。

也可在 Godot 中导入本目录 `project.godot` 后按 F5。ZIP 为源码交付，不含引擎和独立 EXE；移动目录后执行 `./Start-Game.ps1 -GodotPath 'Godot 可执行文件完整路径'`。运行不需要 Python。已在 Windows / Godot 4.7.2 stable / OpenGL Compatibility 实测。

## 操作

| 操作 | 按键 |
|---|---|
| 移动 / 瞄准 | WASD 或方向键 / 鼠标 |
| 近战 / 灵弹 | 左键或 J / 右键或 K，可按住 |
| 修炼 | 玉绿色圆环范围内静止并按住 E |
| 保存 / 读取手动快照 | F5 / F9 |
| 死亡后重置测试场景 | R 或按钮；这是测试工具，不是正式转世 |

近战伤害 25、冷却 0.38 秒；灵弹伤害 20、冷却 0.65 秒。玩家生命 100、受击保护 0.5 秒；敌人生命 60、保护 0.12 秒，接触伤害 12。升级暂不影响战斗数值。黄色/蓝色冷却条、挥剑与发射效果、敌人伤害数字/闪白、玩家短暂红色提示和死亡消散用于区分攻击与命中。

建议试玩：在玉环修炼 → 走近石墙验证碰撞 → 绕墙接敌并连续攻击 → F5 保存 → 移动和受伤 → F9 读取 → 验证击杀敌人不会在读档后复活 → 验证玩家死亡状态和显式场景重置。

## 状态与存档

死亡不会自动重置世界；当前没有正式转世，R 仅重置测试场景。手动快照为持久化测试能力，正式死亡与读档规则仍待设计。

单槽文件为 `user://stage1-save.json`，Windows 默认展开为 `%APPDATA%/Godot/app_userdata/Cultivation Prototype 0.2/stage1-save.json`。F5 需主动保存，关闭游戏不会自动保存；下次启动后按 F9 读取。新存档覆盖旧槽位前先完成临时文件写入。缺失/损坏/不兼容的存档不会改变正在运行的游戏。

记录玩家位置、生命、受击保护、攻击冷却、修为与层数，以及存活敌人的状态。死亡快照仍是死亡状态，被击杀敌人保持消失。瞬态特效与已发射弹体不保存；读取时清理。没有多槽、迁移、离线推进或完整 NPC 世界存档。

## 结构

- `scenes/main.tscn`：入口；`scripts/world.gd`：地图装配、UI、状态接线及快照采集/应用。
- `player.gd` / `enemy.gd`：角色控制与装配；`combat.gd` / `projectile.gd`：战斗规则。
- `stats.gd` / `cultivation.gd`：属性与成长数据；`feedback.gd`：纯视觉表现。
- `game_state.gd`：生存/死亡状态；`save_store.gd`：存档校验及读写。
- `tests/`：基础回归、反馈生命周期、持久化与渲染检查。
- `docs/DESIGN.md`：正式方向、实现范围、占位规则与扩展计划。

## 验证

执行 `./Test-Project.ps1`，可传 `-GodotPath`。顺序执行编辑器检查及 smoke / feedback / save 三组测试；失败返回非零退出码。测试使用专用存档路径，不覆盖用户槽位。逐项实际结果见 `TEST_REPORT.md`，日志在 `verification/`，画面在 `preview.png` 和 `previews/`。

## 当前限制

仅固定 1280×960 测试地图、三只敌人、一种近战和一种远程。敌人不绕障碍寻路，可互相重叠。没有音效、精细动画、战利品、回血或正式属性成长。初始「炼气1层」及修炼数值沿用旧技术占位，正式「凡人起步」尚未实现。

没有完整开放世界、炼丹交易、产业、护卫、宗门势力、NPC 人生、寿元、世界历史、转世、前世记忆或多人联机。长期规则已写入设计文档，不宣称这些系统完成。其他平台、其他 Godot 小版本、长时间战斗和平衡性未完整验证。

## 引擎来源

官方发布：https://github.com/godotengine/godot/releases/tag/4.7.2-stable
下载：Godot_v4.7.2-stable_win64.exe.zip
SHA256：731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953（已核对官方 asset 摘要）。引擎旁 `_sc_` 标记启用自包含设置。保留旧版本交付包，不覆盖已有重要文件。
