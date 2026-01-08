extends Node3D

@export var start_cookie_width: float = 2.0
@export var start_cookie_depth: float = 2.0
@export var cookie_height: float = 0.3
@export var movement_range: float = 4.0
@export var movement_speed_base: float = 4.0
@export var speed_increase_per_level: float = 0.03
@export var perfect_threshold: float = 0.06
@export var minimum_overlap_to_continue: float = 0.01

@onready var _cookie_scene: PackedScene = preload("uid://ypbcdx745n4b")
@onready var _ui: Control = $CanvasLayer/UI
@onready var _camera: Camera3D = $Camera3D
@onready var _stack_root: Node3D = $StackRoot
@onready var _moving_cookie_root: Node3D = $MovingCookie

var score: int = 0
var game_over: bool = false

var _height_level: int = 0
var _movement_axis := "x"
var _current_cookie: Node3D = null
var _last_cookie: Node3D = null
var _movement_time: float = 0.0
var _camera_target_y: float = 6.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_start_game()


func _start_game() -> void:
	_clear_children(_stack_root)
	_clear_children(_moving_cookie_root)

	_height_level = 0
	score = 0
	_movement_axis = "x"
	_current_cookie = null
	_last_cookie = null
	game_over = false
	_movement_time = 0.0
	_camera_target_y = 6.0

	_spawn_base_cookie()


func _spawn_base_cookie() -> void:
	var base_cookie = _cookie_scene.instantiate() as Node3D
	base_cookie.name = "BaseCookie"
	base_cookie.position = Vector3.ZERO
	base_cookie.set("width", start_cookie_width)
	base_cookie.set("depth", start_cookie_depth)
	base_cookie.set("height", cookie_height)
	base_cookie.call_deferred("update_mesh")
	_stack_root.add_child(base_cookie)
	_last_cookie = base_cookie

	_spawn_moving_cookie()


func _spawn_moving_cookie() -> void:
	if game_over:
		return

	_current_cookie = _cookie_scene.instantiate() as Node3D
	_current_cookie.name = "Cookie_%d" % _height_level

	var last_width = _last_cookie.get("width")
	var last_depth = _last_cookie.get("depth")
	_current_cookie.set("width", last_width)
	_current_cookie.set("depth", last_depth)
	_current_cookie.set("height", cookie_height)
	_current_cookie.set("movement_axis", _movement_axis)
	_current_cookie.call_deferred("update_mesh")

	_moving_cookie_root.add_child(_current_cookie)

	var last_position = _last_cookie.global_transform.origin
	var spawn_position = Vector3(last_position.x, last_position.y + cookie_height, last_position.z)
	_current_cookie.global_transform = Transform3D(Basis.IDENTITY, spawn_position)

	_height_level += 1
	_movement_time = 0.0


func _move_current_cookie(delta: float) -> void:
	if not _current_cookie or not _last_cookie:
		return

	var speed = movement_speed_base + _height_level * speed_increase_per_level
	var offset = movement_range * sin(_movement_time * speed * 0.6 + _height_level * 0.5)

	var last_position = _last_cookie.global_transform.origin
	var new_position = _current_cookie.global_transform.origin

	if _current_cookie.get("movement_axis") == "x":
		new_position.x = last_position.x + offset
		new_position.z = last_position.z
	else:
		new_position.x = last_position.x
		new_position.z = last_position.z + offset

	new_position.y = last_position.y + cookie_height
	_current_cookie.global_transform = Transform3D(_current_cookie.global_transform.basis, new_position)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _physics_process(delta: float) -> void:
	if game_over:
		return

	_movement_time += delta
	_move_current_cookie(delta)
