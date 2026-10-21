extends Node
signal changed
var experience: float = 0.0
var rank: int = 1
func cultivate(delta: float) -> void:
	experience += delta * 12.0
	while experience >= 100.0:
		experience -= 100.0
		rank += 1
	changed.emit()
