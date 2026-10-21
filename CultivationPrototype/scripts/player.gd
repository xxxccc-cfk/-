extends CharacterBody2D
const FEEDBACK = preload("res://scripts/feedback.gd")
const STATS = preload("res://scripts/stats.gd")
const CULTIVATION = preload("res://scripts/cultivation.gd")
const COMBAT = preload("res://scripts/combat.gd")
var stats: Node
var cultivation: Node
var combat: Node
var facing: Vector2 = Vector2.RIGHT
var training: bool = false
func _ready() -> void:
	collision_layer = 2
	collision_mask = 5
	stats = Node.new()
	stats.set_script(STATS)
	add_child(stats)
	cultivation = Node.new()
	cultivation.set_script(CULTIVATION)
	add_child(cultivation)
	combat = Node.new()
	combat.set_script(COMBAT)
	add_child(combat)
	combat.attack_started.connect(_on_attack_started)
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(18, 20)
	collider.shape = shape
	add_child(collider)
	var camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1280
	camera.limit_bottom = 960
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
func _physics_process(delta: float) -> void:
	if stats.health <= 0:
		velocity = Vector2.ZERO
		training = false
		queue_redraw()
		return
	var input = Input.get_vector("left", "right", "up", "down")
	var aim = get_global_mouse_position() - global_position
	if aim.length() > 2.0:
		facing = aim.normalized()
	training = Input.is_action_pressed("cultivate") and position.distance_to(Vector2(320, 320)) < 48.0 and input == Vector2.ZERO
	if training:
		cultivation.cultivate(delta)
	velocity = input * 150.0
	move_and_slide()
	if Input.is_action_pressed("melee"):
		combat.melee(facing)
	if Input.is_action_pressed("ranged"):
		combat.ranged(facing)
	queue_redraw()
func _draw() -> void:
	var tint = Color("78d6cc") if stats.health > 0 else Color("686778")
	if stats.immunity > 0:
		tint = Color("ffffff")
	draw_rect(Rect2(-9, -10, 18, 22), tint)
	draw_rect(Rect2(-6, -17, 12, 9), Color("eed6ac"))
	draw_line(Vector2.ZERO, facing * 18.0, Color("f5dc95"), 3.0)
func _on_attack_started(kind: String, direction: Vector2) -> void:
	FEEDBACK.spawn(get_parent(), kind, global_position, direction)
