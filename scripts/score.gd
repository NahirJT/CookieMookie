extends Node

signal score_changed(new_score: int)

var current_score: int = 0

func reset_score() -> void:
	current_score = 0
	score_changed.emit(current_score)

func add_point() -> void:
	current_score += 1
	score_changed.emit(current_score)

func get_score() -> int:
	return current_score

func set_score(value: int) -> void:
	current_score = value
	score_changed.emit(current_score)
