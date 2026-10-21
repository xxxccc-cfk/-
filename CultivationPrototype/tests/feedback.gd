extends SceneTree
var failures: int = 0
func check(condition: bool, title: String) -> void:
	print(("PASS " if condition else "FAIL ") + title)
	if not condition:
		failures += 1
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func effects(kind: String) -> Array:
	return get_nodes_in_group("combat_feedback").filter(func(effect): return effect.kind == kind and not effect.is_queued_for_deletion())
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await frames(3)
	var player = world.player
	check(world.melee_bar.value == 1.0 and world.ranged_bar.value == 1.0, "cooldown bars initially ready")
	check(world.hurt_overlay.color.a == 0.0, "hurt overlay initially transparent")
	var enemy = world.spawn_enemy(player.position + Vector2(40, 0))
	enemy.set_physics_process(false)
	var damage_events: Array = []
	enemy.stats.damaged.connect(func(amount): damage_events.append(amount))
	player.combat.melee(Vector2.RIGHT)
	check(effects("melee").size() == 1, "legal melee creates one slash effect")
	check(effects("damage").size() == 1 and effects("damage")[0].amount == 25, "accepted hit shows actual damage number")
	check(enemy.stats.health == 35 and enemy.stats.immunity > 0.0, "hit updates health and starts white flash")
	player.combat.melee(Vector2.RIGHT)
	check(effects("melee").size() == 1 and damage_events == [25], "blocked attack emits no extra slash or damage event")
	player.combat.ranged(Vector2.UP)
	check(effects("ranged").size() == 1, "legal ranged attack creates muzzle effect")
	player.combat.ranged(Vector2.UP)
	check(effects("ranged").size() == 1, "ranged cooldown blocks duplicate muzzle effect")
	await frames(3)
	check(world.melee_bar.value < 1.0 and world.ranged_bar.value < 1.0, "cooldown bars display ongoing recovery")
	check(world.cooldown_label.text.contains("s"), "cooldown label displays remaining time")
	await create_timer(0.23).timeout
	check(effects("melee").is_empty() and effects("ranged").is_empty(), "slash and muzzle effects expire")
	check(effects("damage").size() == 1 and effects("damage")[0].age > 0.0, "floating number remains during its lifetime")
	check(enemy.stats.health == 35, "presentation effects never apply extra damage")
	await create_timer(0.45).timeout
	check(effects("damage").is_empty(), "floating number cleans itself up")
	check(world.melee_bar.value == 1.0 and world.ranged_bar.value == 1.0, "cooldown bars return to ready")
	enemy.stats.damage(1000)
	check(enemy.dead and not enemy.is_physics_processing(), "lethal hit immediately stops enemy AI")
	check(enemy.collision_layer == 0 and enemy.collision_mask == 0, "lethal hit immediately clears enemy collision")
	check(not enemy.is_in_group("enemies"), "dead enemy immediately leaves target group")
	check(effects("death").size() == 1, "enemy death creates dissipation effect")
	check(damage_events == [25, 35], "overkill number uses actual remaining health")
	enemy.position = player.position
	enemy._physics_process(0.016)
	check(player.stats.health == 100, "dead enemy cannot cause contact damage")
	await frames(3)
	check(not is_instance_valid(enemy), "dead enemy actor is freed")
	await create_timer(0.7).timeout
	check(effects("death").is_empty() and effects("damage").is_empty(), "death feedback fully cleans itself up")
	player.stats.damage(12)
	check(world.hurt_overlay.color.a > 0.0, "accepted player damage triggers red overlay")
	var pulse: float = world.hurt_remaining
	player.stats.damage(12)
	check(world.hurt_remaining == pulse and player.stats.health == 88, "immune damage neither repeats pulse nor removes health")
	await create_timer(0.25).timeout
	check(world.hurt_overlay.color.a == 0.0 and player.stats.immunity > 0.0, "red overlay expires independently of player protection")
	player.stats.immunity = 0.0
	player.stats.damage(1000)
	await frames(3)
	check(world.session.is_dead() and world.death_panel.visible, "death enters dead session state")
	check(get_nodes_in_group("enemies").size() == 3, "player death preserves remaining world enemies")
	load("res://scripts/feedback.gd").spawn(world, "damage", player.position, Vector2.ZERO, 1)
	world.restart()
	await frames(5)
	check(get_nodes_in_group("combat_feedback").is_empty(), "explicit test reset removes old feedback")
	check(not current_scene.session.is_dead() and current_scene.hurt_overlay.color.a == 0.0, "explicit test reset clears dead state and hurt overlay")
	print("RESULT feedback failures=", failures)
	quit(0 if failures == 0 else 1)
