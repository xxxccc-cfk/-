extends Node
signal changed
signal damaged(amount: int)
signal died
@export var maximum: int = 100
@export_range(0.0, 10.0, 0.01) var immunity_duration: float = 0.5
var health: int = 100
var immunity: float = 0.0
func _process(delta: float) -> void:
	immunity = maxf(0.0, immunity - delta)
func damage(amount: int) -> void:
	if health <= 0 or immunity > 0.0:
		return
	var actual_damage = mini(health, amount)
	health = maxi(0, health - amount)
	immunity = immunity_duration
	changed.emit()
	damaged.emit(actual_damage)
	if health == 0:
		died.emit()
