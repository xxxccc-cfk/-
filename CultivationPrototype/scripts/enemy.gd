extends CharacterBody2D
const FEEDBACK = preload("res://scripts/feedback.gd")
const STATS = preload("res://scripts/stats.gd")
var stats: Node
var player: CharacterBody2D
var home: Vector2
var dead: bool = false
func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 3
	home = position
	stats = Node.new()
	stats.set_script(STATS)
	stats.maximum = 60
	stats.health = 60
	stats.immunity_duration = 0.12
	add_child(stats)
	stats.changed.connect(queue_redraw)
	stats.damaged.connect(_on_damaged)
	stats.died.connect(_on_died)
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(22, 22)
	collider.shape = shape
	add_child(collider)
func _physics_process(_delta: float) -> void:
	if dead or not is_instance_valid(player):
		return
	var offset = player.global_position - global_position
	velocity = offset.normalized() * 65.0 if offset.length() < 270.0 and player.stats.health > 0 else (home - position).limit_length(30.0)
	move_and_slide()
	if offset.length() < 31.0 and player.stats.health > 0:
		player.stats.damage(12)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-12, -12, 24, 24), Color("e88483") if stats.immunity <= 0 else Color.WHITE)
	draw_rect(Rect2(-7, -4, 4, 4), Color("382c45"))
	draw_rect(Rect2(3, -4, 4, 4), Color("382c45"))
	draw_rect(Rect2(-12, -19, 24, 3), Color("402f44"))
	draw_rect(Rect2(-12, -19, 24.0 * stats.health / stats.maximum, 3), Color("f1bd78"))

func _on_damaged(amount: int) -> void:
	FEEDBACK.spawn(get_parent(), "damage", global_position, Vector2.ZERO, amount)
func _on_died() -> void:
	dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemies")
	FEEDBACK.spawn(get_parent(), "death", global_position)
	hide()
	queue_free()
