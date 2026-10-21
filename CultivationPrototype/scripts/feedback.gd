extends Node2D
# Presentation only: never applies damage or changes attack cooldowns.
var kind: String = ""
var direction: Vector2 = Vector2.RIGHT
var amount: int = 0
var age: float = 0.0
var lifetime: float = 0.18
static func spawn(host: Node, effect_kind: String, point: Vector2, aim: Vector2 = Vector2.RIGHT, damage_amount: int = 0) -> Node2D:
	var effect = Node2D.new()
	effect.set_script(load("res://scripts/feedback.gd"))
	effect.kind = effect_kind
	effect.direction = aim
	effect.amount = damage_amount
	effect.position = point
	match effect_kind:
		"damage": effect.lifetime = 0.65
		"death": effect.lifetime = 0.24
	host.add_child(effect)
	return effect
func _ready() -> void:
	z_index = 20
	add_to_group("combat_feedback")
func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
	queue_redraw()
func _draw() -> void:
	var progress = clampf(age / lifetime, 0.0, 1.0)
	var alpha = 1.0 - progress
	match kind:
		"melee":
			var angle = direction.angle()
			draw_arc(Vector2.ZERO, 38.0 + 12.0 * progress, angle - 1.1, angle + 1.1, 16, Color(1.0, 0.91, 0.60, alpha), 5.0)
			draw_line(direction.rotated(-1.1 + 2.2 * progress) * 16.0, direction.rotated(-1.1 + 2.2 * progress) * 50.0, Color(1.0, 0.98, 0.84, alpha), 3.0)
		"ranged":
			draw_circle(direction * 18.0, 5.0 + 10.0 * progress, Color(0.55, 0.90, 1.0, alpha * 0.75))
			draw_line(direction * 18.0, direction * 38.0, Color(0.8, 0.98, 1.0, alpha), 3.0)
		"damage":
			var text = str(amount)
			var font = ThemeDB.fallback_font
			var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var point = Vector2(-width / 2.0, -26.0 - progress * 30.0)
			draw_string_outline(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color(0.1, 0.12, 0.15, alpha))
			draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.86, 0.48, alpha))
		"death":
			for i in 8:
				var point = Vector2.RIGHT.rotated(i * TAU / 8.0) * (8.0 + progress * 24.0)
				draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), Color(0.95, 0.60, 0.52, alpha))
