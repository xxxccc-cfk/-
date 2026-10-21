extends SceneTree
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
	check(player.stats.health == 100, "initial health")
	check(is_equal_approx(player.stats.immunity_duration, 0.5), "player configured protection is 0.5 seconds")
	var start: Vector2 = player.position
	Input.action_press("right")
	await frames(20)
	Input.action_release("right")
	check(player.position.x > start.x + 20, "movement through input")
	player.position = Vector2(450, 300)
	Input.action_press("right")
	await frames(30)
	Input.action_release("right")
	check(player.position.x < 472, "wall blocks movement")
	player.position = Vector2(320, 380)
	var enemy = world.spawn_enemy(Vector2(360, 380))
	enemy.set_physics_process(false)
	player.combat.melee(Vector2.RIGHT)
	check(enemy.stats.health == 35, "melee directional hit")
	player.combat.melee(Vector2.RIGHT)
	check(enemy.stats.health == 35, "melee cooldown")
	enemy.stats.immunity = 0.0
	player.combat.ranged(Vector2.RIGHT)
	await frames(15)
	check(enemy.stats.health == 15, "projectile physics hit")
	enemy.position = player.position + Vector2(25, 0)
	enemy.set_physics_process(true)
	await frames(4)
	check(player.stats.health < 100, "enemy contact damage")
	var health: int = player.stats.health
	player.stats.damage(12)
	check(player.stats.health == health, "damage immunity")
	enemy.queue_free()
	await frames(1)
	await create_timer(0.25).timeout
	player.stats.damage(12)
	check(player.stats.health == health, "player protection still blocks damage after 0.25 seconds")
	await create_timer(0.3).timeout
	player.stats.damage(12)
	check(player.stats.health == health - 12, "player can take damage after protection expires")
	var regression_enemy = world.spawn_enemy(player.position + Vector2(40, 0))
	regression_enemy.set_physics_process(false)
	check(is_equal_approx(regression_enemy.stats.immunity_duration, 0.12), "enemy configured protection is 0.12 seconds")
	player.combat.melee(Vector2.RIGHT)
	check(regression_enemy.stats.health == 35, "regression first melee deals full 25 damage")
	player.combat.melee(Vector2.RIGHT)
	check(regression_enemy.stats.health == 35, "regression melee during cooldown does not deal damage")
	await create_timer(0.20).timeout
	check(regression_enemy.stats.immunity == 0.0 and player.combat.melee_cooldown > 0.0, "enemy protection expires before melee cooldown")
	player.combat.melee(Vector2.RIGHT)
	check(regression_enemy.stats.health == 35, "melee cooldown blocks damage even after enemy protection expires")
	await create_timer(0.20).timeout
	check(player.combat.melee_cooldown == 0.0, "regression melee cooldown expires naturally")
	player.combat.melee(Vector2.RIGHT)
	check(regression_enemy.stats.health == 10, "regression second legal melee deals full 25 damage")
	print("EVIDENCE direct melee HP: 60 -> 35 -> 35 -> 35 -> ", regression_enemy.stats.health)
	regression_enemy.queue_free()
	await create_timer(0.40).timeout
	# Exercise player input/physics, not only direct combat calls. Keep the target
	# stationary in front of the mouse-facing player to isolate hit timing.
	var held_enemy = world.spawn_enemy(player.position + player.facing * 40.0)
	held_enemy.set_physics_process(false)
	Input.action_press("melee")
	await frames(2)
	check(held_enemy.stats.health == 35, "held input first melee deals full damage")
	await create_timer(0.20).timeout
	check(held_enemy.stats.health == 35, "held input cannot bypass melee cooldown")
	await create_timer(0.20).timeout
	Input.action_release("melee")
	check(held_enemy.stats.health == 10, "held input second melee deals full damage after cooldown")
	print("EVIDENCE held melee HP: 60 -> 35 -> 35 -> ", held_enemy.stats.health)
	held_enemy.queue_free()
	player.position = Vector2(320, 320)
	Input.action_press("cultivate")
	await frames(30)
	Input.action_release("cultivate")
	check(player.cultivation.experience > 0, "cultivation interaction")
	player.cultivation.cultivate(10)
	check(player.cultivation.rank == 2, "cultivation rank progress")
	player.stats.immunity = 0.0
	player.stats.damage(1000)
	await frames(3)
	check(player.stats.health == 0 and world.death_panel.visible, "death and restart UI")
	start = player.position
	Input.action_press("right")
	await frames(5)
	Input.action_release("right")
	check(player.position == start, "dead player cannot move")
	world.restart()
	await frames(5)
	check(current_scene != world and current_scene.player.stats.health == 100, "scene restart resets health")
	check(get_nodes_in_group("enemies").size() == 3, "restart resets enemies")
	print("RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
