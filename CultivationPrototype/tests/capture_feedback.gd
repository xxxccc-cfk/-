extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path, " result=", error)
	if error != OK:
		failures += 1
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 8:
		await process_frame
	await shot("res://preview.png")
	var enemy = world.spawn_enemy(world.player.position + Vector2(40, 0))
	enemy.set_physics_process(false)
	world.player.combat.melee(Vector2.RIGHT)
	world.player.combat.ranged(Vector2.UP)
	await shot("res://previews/combat.png")
	world.player.stats.damage(12)
	await shot("res://previews/hurt.png")
	enemy.stats.immunity = 0.0
	enemy.stats.damage(1000)
	await shot("res://previews/enemy-death.png")
	world.player.stats.immunity = 0.0
	world.player.stats.damage(1000)
	for i in 3:
		await process_frame
	await shot("res://previews/player-death.png")
	quit(0 if failures == 0 else 1)
