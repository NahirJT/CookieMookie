extends Control

@onready var _start_button: Button = $ButtonContainer/StartButton
@onready var _quit_button: Button = $ButtonContainer/QuitButton
@onready var _button_click: AudioStreamPlayer = $ButtonClick


func _ready() -> void:
	_start_button.pressed.connect(_on_start_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)


func _on_start_button_pressed() -> void:
	_start_button.disabled = true
	await _play_button_click()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_button_pressed() -> void:
	_quit_button.disabled = true
	await _play_button_click()
	get_tree().quit()


func _play_button_click() -> void:
	if _button_click:
		_button_click.play()
		await _button_click.finished
