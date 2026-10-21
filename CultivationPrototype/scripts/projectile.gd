extends CharacterBody2D
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 1.6
func _ready() -> void:
	add_to_group("projectiles")
	collision_layer = 0
	collision_mask = 5
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var hit = move_and_collide(direction * 380.0 * delta)
	if hit:
		var target = hit.get_collider()
		if target.is_in_group("enemies"):
			target.stats.damage(20)
		queue_free()
func _draw() -> void:
	draw_rect(Rect2(-5, -3, 10, 6), Color("a9eeff"))
