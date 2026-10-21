extends Node
signal attack_started(kind: String, direction: Vector2)
const PROJECTILE = preload("res://scripts/projectile.gd")
var melee_cooldown: float = 0.0
var ranged_cooldown: float = 0.0
var flash: float = 0.0
func _process(delta: float) -> void:
	melee_cooldown = maxf(0.0, melee_cooldown - delta)
	ranged_cooldown = maxf(0.0, ranged_cooldown - delta)
	flash = maxf(0.0, flash - delta)
func melee(direction: Vector2) -> void:
	if melee_cooldown > 0.0 or get_parent().stats.health <= 0:
		return
	melee_cooldown = 0.38
	flash = 0.15
	attack_started.emit("melee", direction)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.global_position - get_parent().global_position
		if offset.length() < 58.0 and offset.normalized().dot(direction) > 0.15:
			enemy.stats.damage(25)
func ranged(direction: Vector2) -> void:
	if ranged_cooldown > 0.0 or get_parent().stats.health <= 0:
		return
	ranged_cooldown = 0.65
	attack_started.emit("ranged", direction)
	var shot = CharacterBody2D.new()
	shot.set_script(PROJECTILE)
	shot.direction = direction
	shot.position = get_parent().global_position + direction * 20.0
	get_tree().current_scene.add_child(shot)
