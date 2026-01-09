extends Control

@onready var start_button: Button = $ButtonContainer/StartButton
@onready var quit_button: Button = $ButtonContainer/QuitButton


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
