extends Node2D
const SAVE_STORE = preload("res://scripts/save_store.gd")
const GAME_STATE = preload("res://scripts/game_state.gd")
const PLAYER = preload("res://scripts/player.gd")
const ENEMY = preload("res://scripts/enemy.gd")
var save_path: String = SAVE_STORE.DEFAULT_PATH
var session: Node
var save_status: Label
var status_remaining: float = 0.0
var player: CharacterBody2D
var hud: Label
var death_panel: PanelContainer
var cooldown_label: Label
var melee_bar: ProgressBar
var ranged_bar: ProgressBar
var hurt_overlay: ColorRect
var hurt_remaining: float = 0.0
func _ready() -> void:
	session = Node.new()
	session.set_script(GAME_STATE)
	add_child(session)
	setup_input()
	RenderingServer.set_default_clear_color(Color("182a30"))
	wall(Rect2(-20, -20, 1320, 20))
	wall(Rect2(-20, 960, 1320, 20))
	wall(Rect2(-20, 0, 20, 960))
	wall(Rect2(1280, 0, 20, 960))
	for rect in [Rect2(480, 240, 80, 160), Rect2(160, 560, 220, 48), Rect2(800, 540, 120, 96), Rect2(930, 160, 64, 160)]:
		wall(rect)
	player = CharacterBody2D.new()
	player.set_script(PLAYER)
	player.position = Vector2(320, 380)
	add_child(player)
	player.stats.changed.connect(func(): session.sync_health(player.stats.health))
	for point in [Vector2(650, 350), Vector2(720, 650), Vector2(1040, 450)]:
		spawn_enemy(point)
	var layer = CanvasLayer.new()
	add_child(layer)
	hurt_overlay = ColorRect.new()
	layer.add_child(hurt_overlay)
	hurt_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hurt_overlay.color = Color(1.0, 0.1, 0.08, 0.0)
	player.stats.damaged.connect(_on_player_damaged)
	hud = Label.new()
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	hud.add_theme_font_override("font", font)
	hud.position = Vector2(18, 16)
	hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud)
	cooldown_label = Label.new()
	cooldown_label.add_theme_font_override("font", font)
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.position = Vector2(18, 182)
	layer.add_child(cooldown_label)
	melee_bar = create_cooldown_bar(layer, Vector2(18, 213), Color("f5dc95"))
	ranged_bar = create_cooldown_bar(layer, Vector2(198, 213), Color("a9eeff"))
	save_status = Label.new()
	save_status.add_theme_font_override("font", font)
	save_status.add_theme_font_size_override("font_size", 16)
	save_status.position = Vector2(18, 590)
	layer.add_child(save_status)
	death_panel = PanelContainer.new()
	death_panel.position = Vector2(300, 235)
	death_panel.custom_minimum_size = Vector2(360, 150)
	var box = VBoxContainer.new()
	death_panel.add_child(box)
	var label = Label.new()
	label.add_theme_font_override("font", font)
	label.text = "身陨道消 · 世界状态保留\nF9 读取快照；尚未实现正式转世。"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var button = Button.new()
	button.add_theme_font_override("font", font)
	button.text = "重置测试场景（R，非转世）"
	button.pressed.connect(restart)
	box.add_child(button)
	layer.add_child(death_panel)
	death_panel.hide()
func spawn_enemy(point: Vector2) -> CharacterBody2D:
	var enemy = CharacterBody2D.new()
	enemy.set_script(ENEMY)
	enemy.position = point
	enemy.player = player
	add_child(enemy)
	return enemy
func setup_input() -> void:
	var keys = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "cultivate": [KEY_E], "restart": [KEY_R], "save": [KEY_F5], "load": [KEY_F9], "melee": [KEY_J], "ranged": [KEY_K]}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in keys[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	for pair in [["melee", MOUSE_BUTTON_LEFT], ["ranged", MOUSE_BUTTON_RIGHT]]:
		var event = InputEventMouseButton.new()
		event.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], event):
			InputMap.action_add_event(pair[0], event)
func wall(rect: Rect2) -> void:
	var body = StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	body.collision_layer = 1
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([-rect.size / 2, Vector2(rect.size.x, -rect.size.y) / 2, rect.size / 2, Vector2(-rect.size.x, rect.size.y) / 2])
	visual.color = Color("52636a")
	body.add_child(visual)
	add_child(body)
func create_cooldown_bar(layer: CanvasLayer, point: Vector2, tint: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = point
	bar.size = Vector2(160, 10)
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill = StyleBoxFlat.new()
	fill.bg_color = tint
	bar.add_theme_stylebox_override("fill", fill)
	layer.add_child(bar)
	return bar
func _on_player_damaged(_amount: int) -> void:
	hurt_remaining = 0.18
	hurt_overlay.color.a = 0.22
func _process(delta: float) -> void:
	status_remaining = maxf(0.0, status_remaining - delta)
	if status_remaining <= 0.0:
		save_status.text = "F5 保存快照 · F9 读取快照（手动单槽）"
	if Input.is_action_just_pressed("save"):
		save_game(save_path)
	if Input.is_action_just_pressed("load"):
		load_game(save_path)
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	hurt_overlay.color.a = 0.22 * hurt_remaining / 0.18
	melee_bar.value = 1.0 - player.combat.melee_cooldown / 0.38
	ranged_bar.value = 1.0 - player.combat.ranged_cooldown / 0.65
	var melee_text = "就绪" if player.combat.melee_cooldown <= 0.0 else "%.2fs" % player.combat.melee_cooldown
	var ranged_text = "就绪" if player.combat.ranged_cooldown <= 0.0 else "%.2fs" % player.combat.ranged_cooldown
	cooldown_label.text = "近战 %s      灵弹 %s" % [melee_text, ranged_text]
	if session.is_dead():
		melee_bar.value = 0
		ranged_bar.value = 0
		cooldown_label.text = "已身陨 · F9读取 · R仅重置测试场景"
	death_panel.visible = session.is_dead()
	hud.text = "修仙 / Prototype 0.2\n生命 %d / %d    炼气 %d 层    修为 %.0f / 100\nWASD / 方向键移动 · 鼠标瞄准\n左键 / J 挥剑 · 右键 / K 灵弹\n玉环内静止并按住 E 修炼（临时成长规则）\n%s" % [player.stats.health, player.stats.maximum, player.cultivation.rank, player.cultivation.experience, "正在修炼……" if player.training else ""]
	if Input.is_action_just_pressed("restart") and player.stats.health <= 0:
		restart()
func restart() -> void:
	get_tree().reload_current_scene()
func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 960), Color("243e3e"))
	for x in range(0, 1280, 32):
		for y in range(0, 960, 32):
			if (int(x / 32.0) + int(y / 32.0)) % 3 == 0:
				draw_rect(Rect2(x + 8, y + 14, 3, 5), Color("35534b"))
	draw_circle(Vector2(320, 320), 44, Color("355d59"))
	draw_arc(Vector2(320, 320), 38, 0, TAU, 32, Color("89ddbf"), 2)
	draw_rect(Rect2(312, 308, 16, 24), Color("89ddbf"))

func capture_snapshot() -> Dictionary:
	var enemies: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemies.append({"x": enemy.position.x, "y": enemy.position.y, "health": enemy.stats.health, "immunity": enemy.stats.immunity, "home_x": enemy.home.x, "home_y": enemy.home.y})
	return {"version": 1, "map_id": SAVE_STORE.MAP_ID, "player": {"x": player.position.x, "y": player.position.y, "health": player.stats.health, "immunity": player.stats.immunity, "rank": player.cultivation.rank, "experience": player.cultivation.experience, "melee_cooldown": player.combat.melee_cooldown, "ranged_cooldown": player.combat.ranged_cooldown}, "enemies": enemies}
func apply_snapshot(data: Dictionary) -> String:
	var error = SAVE_STORE.validate(data)
	if not error.is_empty():
		return error
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.remove_from_group("enemies")
		enemy.collision_layer = 0
		enemy.collision_mask = 0
		enemy.set_physics_process(false)
		enemy.queue_free()
	for transient in get_tree().get_nodes_in_group("combat_feedback") + get_tree().get_nodes_in_group("projectiles"):
		transient.set_process(false)
		transient.set_physics_process(false)
		if transient is CollisionObject2D:
			transient.collision_layer = 0
			transient.collision_mask = 0
		transient.queue_free()
	var saved: Dictionary = data.player
	player.position = Vector2(saved.x, saved.y)
	player.velocity = Vector2.ZERO
	player.stats.health = int(saved.health)
	player.stats.immunity = float(saved.immunity)
	player.cultivation.rank = int(saved.rank)
	player.cultivation.experience = float(saved.experience)
	player.combat.melee_cooldown = float(saved.melee_cooldown)
	player.combat.ranged_cooldown = float(saved.ranged_cooldown)
	player.combat.flash = 0.0
	player.training = false
	for entry in data.enemies:
		var enemy = spawn_enemy(Vector2(entry.x, entry.y))
		enemy.stats.health = int(entry.health)
		enemy.stats.immunity = float(entry.immunity)
		enemy.home = Vector2(entry.home_x, entry.home_y)
	session.sync_health(player.stats.health)
	hurt_remaining = 0.0
	hurt_overlay.color.a = 0.0
	player.stats.changed.emit()
	player.cultivation.changed.emit()
	return ""
func show_status(message: String) -> void:
	save_status.text = message
	status_remaining = 4.0
func save_game(path: String = SAVE_STORE.DEFAULT_PATH) -> String:
	var error = SAVE_STORE.write_snapshot(capture_snapshot(), path)
	show_status("快照已保存（含世界与角色状态）" if error.is_empty() else error)
	return error
func load_game(path: String = SAVE_STORE.DEFAULT_PATH) -> String:
	var result = SAVE_STORE.read_snapshot(path)
	var error: String = result.get("error", "")
	if error.is_empty():
		error = apply_snapshot(result.data)
	show_status("快照已读取" if error.is_empty() else error)
	return error
