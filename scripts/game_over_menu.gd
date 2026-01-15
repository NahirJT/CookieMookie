extends Control

var _is_transitioning: bool = false

@onready var _score_label: Label = $LabelContainer/ScoreLabel
@onready var _restart_button: Button = $ButtonContainer/RestartButton
@onready var _quit_button: Button = $ButtonContainer/QuitButton
@onready var _button_click: AudioStreamPlayer = $ButtonClick


func _ready() -> void:
	_score_label.text = "Score: %d" % GameState.score
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("place") and not _is_transitioning:
		_on_restart_pressed()


func _on_restart_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_restart_button.disabled = true
	await _play_button_click()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_quit_button.disabled = true
	await _play_button_click()
	get_tree().quit()


func _play_button_click() -> void:
	if _button_click:
		_button_click.play()
		await _button_click.finished
