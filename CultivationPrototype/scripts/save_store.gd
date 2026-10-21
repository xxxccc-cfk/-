extends RefCounted
# Versioned snapshot boundary; no simulation or UI dependencies.
const DEFAULT_PATH = "user://stage1-save.json"
const MAP_ID = "test_map_v1"
static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
static func between(value: Variant, minimum: float, maximum: float) -> bool:
	return number(value) and float(value) >= minimum and float(value) <= maximum
static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return between(value, minimum, maximum) and float(value) == floorf(float(value))
static func actor_valid(actor: Variant, enemy: bool) -> bool:
	if not actor is Dictionary:
		return false
	var margin = 11.0 if enemy else 9.0
	if not between(actor.get("x"), margin, 1280.0 - margin) or not between(actor.get("y"), 11.0 if enemy else 10.0, 949.0 if enemy else 950.0):
		return false
	if not integer(actor.get("health"), 1 if enemy else 0, 60 if enemy else 100):
		return false
	if not between(actor.get("immunity"), 0, 0.12 if enemy else 0.5):
		return false
	# Reject snapshots placing a collider inside the fixed test-map obstacles.
	var half = Vector2(11, 11) if enemy else Vector2(9, 10)
	var bounds = Rect2(Vector2(float(actor.x), float(actor.y)) - half, half * 2.0)
	for wall in [Rect2(480, 240, 80, 160), Rect2(160, 560, 220, 48), Rect2(800, 540, 120, 96), Rect2(930, 160, 64, 160)]:
		if bounds.intersects(wall.grow(-0.01)):
			return false
	if enemy:
		return between(actor.get("home_x"), 11, 1269) and between(actor.get("home_y"), 11, 949)
	return integer(actor.get("rank"), 1, 1000000) and between(actor.get("experience"), 0, 99.999999999) and between(actor.get("melee_cooldown"), 0, 0.38) and between(actor.get("ranged_cooldown"), 0, 0.65)
static func validate(data: Variant) -> String:
	if not data is Dictionary or data.get("version") != 1 or data.get("map_id") != MAP_ID:
		return "存档版本或地图不兼容"
	if not actor_valid(data.get("player"), false):
		return "玩家存档数据无效"
	var enemies: Variant = data.get("enemies")
	if not enemies is Array or enemies.size() > 64:
		return "敌人存档数据无效"
	for enemy in enemies:
		if not actor_valid(enemy, true):
			return "敌人存档数据无效"
	return ""
static func write_snapshot(data: Dictionary, path: String = DEFAULT_PATH) -> String:
	var validation = validate(data)
	if not validation.is_empty():
		return validation
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "无法写入存档目录"
	file.store_string(JSON.stringify(data))
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK:
		return "写入存档失败，旧存档保留"
	# Replace only after a full write. On rename failure the existing file remains.
	if DirAccess.rename_absolute(temporary, path) != OK:
		return "替换存档失败，旧存档保留"
	return ""
static func read_snapshot(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": "尚无存档，请先按 F5 保存"}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 2097152:
		return {"error": "存档无法读取或文件过大"}
	var parser = JSON.new()
	var content = file.get_as_text()
	file.close()
	if parser.parse(content) != OK:
		return {"error": "存档损坏，当前游戏状态未改变"}
	var error = validate(parser.data)
	if not error.is_empty():
		return {"error": error}
	return {"data": parser.data}
