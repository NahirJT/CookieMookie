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
@onready var _camera: Camera3D = $Camera3D
@onready var _ui: Control = $CanvasLayer/UI
@onready var _stack_root: Node3D = $StackRoot
@onready var _moving_cookie_root: Node3D = $MovingCookie

var score: int = 0
var game_over: bool = false

var _height_level: int = 0
var _movement_axis := "x"
var _current_cookie: Node3D = null
var _last_cookie: Node3D = null
var _movement_time: float = 0.0


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


func _move_current_cookie(_delta: float) -> void:
	if not _current_cookie or not _last_cookie:
		return

	var speed = movement_speed_base + _height_level * speed_increase_per_level
	var offset = movement_range * sin(_movement_time * speed)

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

	if Input.is_action_just_pressed("drop"):
		_drop_cookie()


func _drop_cookie() -> void:
	if not _current_cookie or game_over:
		return

	var saved_transform = _current_cookie.global_transform
	if _current_cookie.get_parent() == _moving_cookie_root:
		_moving_cookie_root.remove_child(_current_cookie)

	_stack_root.add_child(_current_cookie)
	_current_cookie.global_transform = saved_transform

	var info = _slice_with_last(_current_cookie, _last_cookie)
	if info.get("game_over", false):
		_on_game_over()
		return

	if info.get("perfect", false):
		_current_cookie.set("width", _last_cookie.get("width"))
		_current_cookie.set("depth", _last_cookie.get("depth"))
		_current_cookie.call_deferred("update_mesh")

		var tween = create_tween()
		tween.tween_property(_current_cookie, "scale", Vector3(1.06, 1.06, 1.06), 0.08) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_current_cookie, "scale", Vector3.ONE, 0.08) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		_current_cookie.set("width", info.get("remain_width"))
		_current_cookie.set("depth", info.get("remain_depth"))
		_current_cookie.call_deferred("update_mesh")

		var falling_size: Vector3 = info.get("falling_size")
		if falling_size.x > 0.001 or falling_size.z > 0.001:
			_spawn_falling_piece(falling_size, info.get("falling_world_center"), info.get("axis"))

	_last_cookie = _current_cookie
	score += 1

	# Bump camera up.
	var camera_tween = create_tween()
	var new_camera_pos = _camera.global_transform.origin + Vector3(0, cookie_height, 0)
	camera_tween.tween_property(_camera, "global_transform:origin", new_camera_pos, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_movement_axis = "z" if _movement_axis == "x" else "x"
	_spawn_moving_cookie()


func _slice_with_last(current: Node3D, previous: Node3D) -> Dictionary:
	var axis = current.get("movement_axis")
	var current_pos = current.global_transform.origin
	var previous_pos = previous.global_transform.origin

	var current_width = current.get("width")
	var current_depth = current.get("depth")
	var previous_width = previous.get("width")
	var previous_depth = previous.get("depth")

	var remain_width = current_width
	var remain_depth = current_depth
	var falling_size = Vector3.ZERO
	var falling_world_center = Vector3.ZERO

	if axis == "x":
		var diff = current_pos.x - previous_pos.x
		var overlap = previous_width - abs(diff)

		# Check for perfect placement.
		if abs(diff) <= perfect_threshold:
			return {
				"game_over": false,
				"remain_width": previous_width,
				"remain_depth": previous_depth,
				"axis": axis,
				"falling_size": Vector3.ZERO,
				"falling_world_center": Vector3.ZERO,
				"perfect": true
			}

		# Check for game over.
		if overlap <= minimum_overlap_to_continue:
			return {"game_over": true}

		remain_width = overlap

		# Reposition the current cookie to be centered on the overlap.
		var new_center_x = previous_pos.x + diff * 0.5
		var new_local = _stack_root.to_local(Vector3(new_center_x, current_pos.y, current_pos.z))
		var pos = current.position
		pos.x = new_local.x
		current.position = pos

		# Calculate falling piece.
		var falling_piece_width = current_width - remain_width
		if falling_piece_width > 0.001:
			falling_size = Vector3(falling_piece_width, cookie_height, current_depth)
			var direction_sign = 1.0 if diff >= 0.0 else -1.0
			var falling_center_x = new_center_x + direction_sign * (remain_width * 0.5 + falling_piece_width * 0.5)
			falling_world_center = Vector3(falling_center_x, current_pos.y, current_pos.z)
	else:
		var diff = current_pos.z - previous_pos.z
		var overlap = previous_depth - abs(diff)

		# Check for perfect placement.
		if abs(diff) <= perfect_threshold:
			return {
				"game_over": false,
				"remain_width": previous_width,
				"remain_depth": previous_depth,
				"axis": axis,
				"falling_size": Vector3.ZERO,
				"falling_world_center": Vector3.ZERO,
				"perfect": true
			}

		# Check for game over.
		if overlap <= minimum_overlap_to_continue:
			return {"game_over": true}

		remain_depth = overlap

		# Reposition the current cookie to be centered on the overlap.
		var new_center_z = previous_pos.z + diff * 0.5
		var new_local = _stack_root.to_local(Vector3(current_pos.x, current_pos.y, new_center_z))
		var pos = current.position
		pos.z = new_local.z
		current.position = pos

		# Calculate falling piece.
		var falling_piece_depth = current_depth - remain_depth
		if falling_piece_depth > 0.001:
			falling_size = Vector3(current_width, cookie_height, falling_piece_depth)
			var direction_sign = 1.0 if diff >= 0.0 else -1.0
			var falling_center_z = new_center_z + direction_sign * (remain_depth * 0.5 + falling_piece_depth * 0.5)
			falling_world_center = Vector3(current_pos.x, current_pos.y, falling_center_z)

	return {
		"game_over": false,
		"remain_width": remain_width,
		"remain_depth": remain_depth,
		"axis": axis,
		"falling_size": falling_size,
		"falling_world_center": falling_world_center,
		"perfect": false
	}


func _spawn_falling_piece(size: Vector3, world_center: Vector3, _axis: String) -> void:
	var falling_piece = _cookie_scene.instantiate() as Node3D
	falling_piece.name = "FallingPiece"
	falling_piece.set("width", size.x)
	falling_piece.set("height", size.y)
	falling_piece.set("depth", size.z)
	falling_piece.call_deferred("update_mesh")

	add_child(falling_piece)
	falling_piece.global_transform.origin = world_center

	var tween = create_tween()
	tween.set_parallel(true)

	var fall_target = world_center + Vector3(0, -10, 0)
	tween.tween_property(falling_piece, "global_transform:origin", fall_target, 1.0) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var random_rotation = Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2))
	tween.tween_property(falling_piece, "rotation", random_rotation, 1.0)

	tween.chain().tween_callback(falling_piece.queue_free)


func _on_game_over() -> void:
	game_over = true
	print("Game Over! Score: %d" % score)
