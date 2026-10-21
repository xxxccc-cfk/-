extends SceneTree
const STORE = preload("res://scripts/save_store.gd")
const TEST_PATH = "user://automated-stage1-snapshot.json"
var failures: int = 0
func check(condition: bool, title: String) -> void:
	print(("PASS " if condition else "FAIL ") + title)
	if not condition:
		failures += 1
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await frames(3)
	var player = world.player
	var seed = world.capture_snapshot()
	check(STORE.validate(seed).is_empty(), "initial live snapshot passes schema validation")
	# All persistence tests use a dedicated file, never the user's slot.
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	check(not STORE.read_snapshot(TEST_PATH).get("error", "").is_empty(), "missing snapshot gives recoverable error")
	player.position = Vector2(360, 420)
	player.stats.health = 73
	player.stats.immunity = 0.33
	player.cultivation.rank = 2
	player.cultivation.experience = 42.0
	player.combat.melee_cooldown = 0.20
	player.combat.ranged_cooldown = 0.40
	var defeated = get_nodes_in_group("enemies")[0]
	defeated.stats.damage(1000)
	var living = get_nodes_in_group("enemies")[0]
	living.stats.health = 35
	living.stats.immunity = 0.08
	var expected = world.capture_snapshot()
	check(world.save_game(TEST_PATH).is_empty(), "snapshot writes to disk")
	check(world.save_game(TEST_PATH).is_empty(), "saving again safely replaces existing snapshot")
	var disk = STORE.read_snapshot(TEST_PATH)
	check(disk.has("data") and disk.data.player.health == 73, "snapshot parses and validates after disk round trip")
	player.stats.health = 20
	player.position = Vector2(300, 420)
	player.cultivation.rank = 9
	var stray = CharacterBody2D.new()
	stray.set_script(load("res://scripts/projectile.gd"))
	stray.position = player.position
	stray.direction = Vector2.UP
	world.add_child(stray)
	check(get_nodes_in_group("projectiles").size() == 1, "load fixture contains an active projectile")
	check(world.load_game(TEST_PATH).is_empty(), "snapshot loads successfully")
	check(not stray.is_physics_processing() and stray.collision_mask == 0, "load immediately disables old projectile before deletion")
	check(player.position == Vector2(360, 420) and player.stats.health == 73, "load restores position and health")
	check(player.cultivation.rank == 2 and player.cultivation.experience == 42.0, "load restores cultivation progress")
	check(is_equal_approx(player.stats.immunity, 0.33) and is_equal_approx(player.combat.melee_cooldown, 0.20) and is_equal_approx(player.combat.ranged_cooldown, 0.40), "load preserves protection and attack cooldowns")
	check(get_nodes_in_group("enemies").size() == 2, "defeated enemy stays absent after load")
	check(world.capture_snapshot().enemies == expected.enemies, "load restores surviving enemy health position home and protection")
	check(not world.session.is_dead(), "live snapshot restores playing session state")
	await frames(3)
	check(get_nodes_in_group("combat_feedback").is_empty() and get_nodes_in_group("projectiles").is_empty(), "load removes obsolete transient effects and projectiles")
	var invalid = expected.duplicate(true)
	invalid.version = 99
	var unchanged = world.capture_snapshot()
	check(not world.apply_snapshot(invalid).is_empty() and world.capture_snapshot() == unchanged, "incompatible snapshot rejected without changing world")
	invalid = expected.duplicate(true)
	invalid.player.health = -1
	check(not STORE.validate(invalid).is_empty(), "negative health rejected")
	invalid.player.health = 1.5
	check(not STORE.validate(invalid).is_empty(), "fractional health rejected")
	invalid = expected.duplicate(true)
	invalid.player.x = 500
	invalid.player.y = 300
	check(not STORE.validate(invalid).is_empty(), "position inside wall rejected")
	invalid = expected.duplicate(true)
	invalid.player.rank = "two"
	check(not STORE.validate(invalid).is_empty(), "wrong field type rejected")
	invalid = expected.duplicate(true)
	invalid.enemies[0].health = 61
	check(not STORE.validate(invalid).is_empty(), "invalid enemy health rejected")
	check(not STORE.write_snapshot(invalid, TEST_PATH).is_empty(), "invalid data cannot overwrite good snapshot")
	check(STORE.read_snapshot(TEST_PATH).data.player.health == 73, "good on-disk snapshot survives rejected write")
	check(not STORE.write_snapshot(expected, "user://missing-stage1-test-dir/file.json").is_empty(), "unwritable destination returns recoverable error")
	var broken = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	unchanged = world.capture_snapshot()
	check(not world.load_game(TEST_PATH).is_empty() and world.capture_snapshot() == unchanged, "corrupt snapshot leaves running game unchanged")
	player.stats.immunity = 0.0
	player.stats.damage(1000)
	var dead_snapshot = world.capture_snapshot()
	check(world.session.is_dead() and dead_snapshot.enemies.size() == 2, "death preserves world in snapshot")
	check(world.save_game(TEST_PATH).is_empty(), "dead world snapshot can be saved")
	check(world.apply_snapshot(seed).is_empty(), "initial fixture restores without rebuilding scene")
	check(world.load_game(TEST_PATH).is_empty() and player.stats.health == 0 and world.session.is_dead(), "loading dead snapshot does not resurrect player")
	check(get_nodes_in_group("enemies").size() == 2, "loading dead snapshot does not reset world")
	# Test a genuine new scene/session reading the file from disk.
	world.restart()
	await frames(5)
	check(current_scene.load_game(TEST_PATH).is_empty() and current_scene.player.stats.health == 0 and get_nodes_in_group("enemies").size() == 2, "new scene can restore saved dead world")
	check(InputMap.action_get_events("melee").size() == 2, "scene reset does not duplicate mouse bindings")
	current_scene.save_path = TEST_PATH
	current_scene.apply_snapshot(seed)
	Input.action_press("save")
	await frames(3)
	Input.action_release("save")
	check(STORE.read_snapshot(TEST_PATH).data.player.health == 100, "save action writes configured snapshot slot")
	current_scene.player.stats.health = 40
	current_scene.player.cultivation.experience = 80
	Input.action_press("load")
	await frames(3)
	Input.action_release("load")
	check(current_scene.player.stats.health == 100 and current_scene.player.cultivation.experience == 0, "load action restores configured snapshot slot")
	print("USER_SAVE_PATH ", ProjectSettings.globalize_path(STORE.DEFAULT_PATH))
	DirAccess.remove_absolute(TEST_PATH)
	if FileAccess.file_exists(TEST_PATH + ".tmp"):
		DirAccess.remove_absolute(TEST_PATH + ".tmp")
	print("RESULT save failures=", failures)
	quit(0 if failures == 0 else 1)
