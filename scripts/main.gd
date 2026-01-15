extends Node3D

const PERFECT_SCALE_FACTOR: float = 1.06
const PERFECT_SCALE_DURATION: float = 0.08
const CAMERA_MOVE_DURATION: float = 0.15
const FALLING_DISTANCE: float = 10.0
const FALLING_DURATION: float = 1.0
const SIZE_EPSILON: float = 0.001
const MUSIC_FADE_DURATION: float = 1.0

const TRACKS: Array[String] = [
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_1.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_2.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_3.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_4.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_5.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_6.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_7.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_8.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_9.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_10.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_11.wav",
	"res://assets/audio/tracks/4bae3f43-ce35-4921-9a90-ec2b814a4f34_12.wav",
]

@export var initial_width: float = 2.0
@export var initial_depth: float = 2.0
@export var cookie_height: float = 0.3
@export var movement_range: float = 4.0
@export var base_movement_speed: float = 4.0
@export var speed_increase_per_level: float = 0.03
@export var perfect_threshold: float = 0.06
@export var minimum_overlap: float = 0.01

@onready var _cookie_scene: PackedScene = preload("uid://ypbcdx745n4b")
@onready var _camera: Camera3D = $Camera3D
@onready var _stack: Node3D = $Stack
@onready var _active_cookie_holder: Node3D = $ActiveCookie
@onready var _place_sound: AudioStreamPlayer = $PlaceSound
@onready var _background_music: AudioStreamPlayer = $BackgroundMusic

var score: int = 0
var is_game_over: bool = false

var _stack_count: int = 0
var _movement_axis := "x"
var _active_cookie: Node3D = null
var _top_cookie: Node3D = null
var _movement_time: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_random_track()
	_start_game()


func _play_random_track() -> void:
	if not _background_music:
		return
	var track_path = TRACKS.pick_random()
	_background_music.stream = load(track_path)
	_background_music.volume_db = 0.0
	_background_music.play()


func _start_game() -> void:
	_clear_children(_stack)
	_clear_children(_active_cookie_holder)

	_stack_count = 0
	score = 0
	_movement_axis = "x"
	_active_cookie = null
	_top_cookie = null
	is_game_over = false
	_movement_time = 0.0

	_spawn_base_cookie()


func _spawn_base_cookie() -> void:
	var base_cookie = _cookie_scene.instantiate() as Node3D
	base_cookie.name = "BaseCookie"
	base_cookie.position = Vector3.ZERO
	base_cookie.set("width", initial_width)
	base_cookie.set("depth", initial_depth)
	base_cookie.set("height", cookie_height)
	base_cookie.set("stack_level", 0)
	base_cookie.call_deferred("update_mesh")
	_stack.add_child(base_cookie)
	_top_cookie = base_cookie

	_spawn_moving_cookie()


func _spawn_moving_cookie() -> void:
	if is_game_over:
		return

	_active_cookie = _cookie_scene.instantiate() as Node3D
	_active_cookie.name = "Cookie_%d" % _stack_count

	var top_width = _top_cookie.get("width")
	var top_depth = _top_cookie.get("depth")
	_active_cookie.set("width", top_width)
	_active_cookie.set("depth", top_depth)
	_active_cookie.set("height", cookie_height)
	_active_cookie.set("movement_axis", _movement_axis)
	_active_cookie.set("stack_level", _stack_count)
	_active_cookie.call_deferred("update_mesh")

	_active_cookie_holder.add_child(_active_cookie)

	var top_position = _top_cookie.global_transform.origin
	var spawn_position = Vector3(top_position.x, top_position.y + cookie_height, top_position.z)
	_active_cookie.global_transform = Transform3D(Basis.IDENTITY, spawn_position)

	_stack_count += 1


func _move_active_cookie() -> void:
	if not _active_cookie or not _top_cookie:
		return

	var speed = base_movement_speed + _stack_count * speed_increase_per_level
	var offset = movement_range * sin(_movement_time * speed)

	var top_position = _top_cookie.global_transform.origin
	var new_position = _active_cookie.global_transform.origin

	if _active_cookie.get("movement_axis") == "x":
		new_position.x = top_position.x + offset
		new_position.z = top_position.z
	else:
		new_position.x = top_position.x
		new_position.z = top_position.z + offset

	new_position.y = top_position.y + cookie_height
	_active_cookie.global_transform = Transform3D(_active_cookie.global_transform.basis, new_position)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _physics_process(delta: float) -> void:
	if is_game_over:
		return

	_movement_time += delta
	_move_active_cookie()

	if Input.is_action_just_pressed("place"):
		_place_cookie()


func _place_cookie() -> void:
	if not _active_cookie or is_game_over:
		return

	var saved_transform = _active_cookie.global_transform
	if _active_cookie.get_parent() == _active_cookie_holder:
		_active_cookie_holder.remove_child(_active_cookie)

	_stack.add_child(_active_cookie)
	_active_cookie.global_transform = saved_transform

	var result = _calculate_slice(_active_cookie, _top_cookie)
	if result.get("is_game_over", false):
		_on_game_over()
		return

	if _place_sound:
		_place_sound.play()

	if result.get("is_perfect", false):
		_active_cookie.set("width", _top_cookie.get("width"))
		_active_cookie.set("depth", _top_cookie.get("depth"))
		_active_cookie.call_deferred("update_mesh")
		_play_perfect_animation(_active_cookie)
	else:
		_active_cookie.set("width", result.get("remain_width"))
		_active_cookie.set("depth", result.get("remain_depth"))
		_active_cookie.call_deferred("update_mesh")

		var falling_size: Vector3 = result.get("falling_size")
		if falling_size.x > SIZE_EPSILON or falling_size.z > SIZE_EPSILON:
			_spawn_falling_piece(falling_size, result.get("falling_center"))

	_top_cookie = _active_cookie
	score += 1

	_move_camera_up()
	_movement_axis = "z" if _movement_axis == "x" else "x"
	_spawn_moving_cookie()


func _play_perfect_animation(cookie: Node3D) -> void:
	var tween = create_tween()
	tween.tween_property(cookie, "scale", Vector3.ONE * PERFECT_SCALE_FACTOR, PERFECT_SCALE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(cookie, "scale", Vector3.ONE, PERFECT_SCALE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _move_camera_up() -> void:
	var tween = create_tween()
	var new_position = _camera.global_transform.origin + Vector3(0, cookie_height, 0)
	tween.tween_property(_camera, "global_transform:origin", new_position, CAMERA_MOVE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _calculate_slice(current: Node3D, previous: Node3D) -> Dictionary:
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
	var falling_center = Vector3.ZERO

	if axis == "x":
		var diff = current_pos.x - previous_pos.x
		var overlap = previous_width - abs(diff)

		# Check for perfect placement.
		if abs(diff) <= perfect_threshold:
			return _make_perfect_result(previous_width, previous_depth, axis)

		# Check for game over.
		if overlap <= minimum_overlap:
			return {"is_game_over": true}

		remain_width = overlap

		# Reposition the current cookie to be centered on the overlap.
		var new_center_x = previous_pos.x + diff * 0.5
		var local_pos = _stack.to_local(Vector3(new_center_x, current_pos.y, current_pos.z))
		var cookie_pos = current.position
		cookie_pos.x = local_pos.x
		current.position = cookie_pos

		# Calculate falling piece.
		var falling_width = current_width - remain_width
		if falling_width > SIZE_EPSILON:
			falling_size = Vector3(falling_width, cookie_height, current_depth)
			var direction_sign = 1.0 if diff >= 0.0 else -1.0
			var falling_x = new_center_x + direction_sign * (remain_width * 0.5 + falling_width * 0.5)
			falling_center = Vector3(falling_x, current_pos.y, current_pos.z)
	else:
		var diff = current_pos.z - previous_pos.z
		var overlap = previous_depth - abs(diff)

		# Check for perfect placement.
		if abs(diff) <= perfect_threshold:
			return _make_perfect_result(previous_width, previous_depth, axis)

		# Check for game over.
		if overlap <= minimum_overlap:
			return {"is_game_over": true}

		remain_depth = overlap

		# Reposition the current cookie to be centered on the overlap.
		var new_center_z = previous_pos.z + diff * 0.5
		var local_pos = _stack.to_local(Vector3(current_pos.x, current_pos.y, new_center_z))
		var cookie_pos = current.position
		cookie_pos.z = local_pos.z
		current.position = cookie_pos

		# Calculate falling piece.
		var falling_depth = current_depth - remain_depth
		if falling_depth > SIZE_EPSILON:
			falling_size = Vector3(current_width, cookie_height, falling_depth)
			var direction_sign = 1.0 if diff >= 0.0 else -1.0
			var falling_z = new_center_z + direction_sign * (remain_depth * 0.5 + falling_depth * 0.5)
			falling_center = Vector3(current_pos.x, current_pos.y, falling_z)

	return {
		"is_game_over": false,
		"is_perfect": false,
		"remain_width": remain_width,
		"remain_depth": remain_depth,
		"axis": axis,
		"falling_size": falling_size,
		"falling_center": falling_center
	}


func _make_perfect_result(width: float, depth: float, axis: String) -> Dictionary:
	return {
		"is_game_over": false,
		"is_perfect": true,
		"remain_width": width,
		"remain_depth": depth,
		"axis": axis,
		"falling_size": Vector3.ZERO,
		"falling_center": Vector3.ZERO
	}


func _spawn_falling_piece(size: Vector3, world_center: Vector3) -> void:
	var falling_piece = _cookie_scene.instantiate() as Node3D
	falling_piece.name = "FallingPiece"
	falling_piece.set("width", size.x)
	falling_piece.set("height", size.y)
	falling_piece.set("depth", size.z)
	falling_piece.set("stack_level", _active_cookie.get("stack_level"))
	falling_piece.call_deferred("update_mesh")

	add_child(falling_piece)
	falling_piece.global_transform.origin = world_center

	var tween = create_tween()
	tween.set_parallel(true)

	var fall_target = world_center + Vector3(0, -FALLING_DISTANCE, 0)
	tween.tween_property(falling_piece, "global_transform:origin", fall_target, FALLING_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var random_rotation = Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2))
	tween.tween_property(falling_piece, "rotation", random_rotation, FALLING_DURATION)

	tween.chain().tween_callback(falling_piece.queue_free)


func _on_game_over() -> void:
	is_game_over = true
	GameState.score = score

	# Fade out music before changing scene.
	if _background_music and _background_music.playing:
		var tween = create_tween()
		tween.tween_property(_background_music, "volume_db", -40.0, MUSIC_FADE_DURATION)
		await tween.finished

	get_tree().change_scene_to_file("res://scenes/game_over_menu.tscn")
