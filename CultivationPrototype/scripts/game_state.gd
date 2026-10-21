extends Node
# Session state only. Reincarnation/world simulation are future systems.
signal state_changed
enum Mode { PLAYING, DEAD }
var mode: Mode = Mode.PLAYING
func sync_health(health: int) -> void:
	var next_mode = Mode.DEAD if health <= 0 else Mode.PLAYING
	if next_mode != mode:
		mode = next_mode
		state_changed.emit()
func is_dead() -> bool:
	return mode == Mode.DEAD
