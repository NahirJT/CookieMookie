extends Node3D

# To use a custom mesh:
# 1. Create or import a model that is unit-sized (1x1x1) and centered at origin.
# 2. Place the model file in res://assets/models/.
# 3. Drag the mesh resource into the "Custom Mesh" export in the inspector.

const MAX_LIGHTNESS: float = 0.4
const LIGHTNESS_PER_LEVEL: float = 0.02
const CHIP_OFFSET_RANGE: float = 1000.0

@export var width: float = 2.0
@export var depth: float = 2.0
@export var height: float = 0.6
@export var custom_mesh: Mesh = null

var movement_axis: String = "x"
var stack_level: int = 0

var _material: ShaderMaterial = null
var _chip_offset: Vector2 = Vector2.ZERO

@onready var _mesh: MeshInstance3D = %MeshInstance3D
@onready var _collider: CollisionShape3D = %CollisionShape3D


func _ready():
	_generate_chip_offset()
	_setup_material()
	update_mesh()


func _generate_chip_offset():
	_chip_offset = Vector2(
		randf_range(-CHIP_OFFSET_RANGE, CHIP_OFFSET_RANGE),
		randf_range(-CHIP_OFFSET_RANGE, CHIP_OFFSET_RANGE)
	)


func _setup_material():
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/cookie.gdshader")
	_update_shader_parameters()


func update_mesh():
	if not _material:
		_setup_material()

	if custom_mesh:
		_mesh.mesh = custom_mesh
		_mesh.scale = Vector3(width, height, depth)
	else:
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3.ONE
		_mesh.mesh = box_mesh
		_mesh.scale = Vector3(width, height, depth)

	_mesh.material_override = _material

	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, height, depth)
	_collider.shape = box_shape

	# Offsets both mesh and collision so the cookie sits on top of its origin.
	var offset = Vector3(0, height * 0.5, 0)
	_mesh.transform.origin = offset
	_collider.transform.origin = offset

	_update_shader_parameters()


func _update_shader_parameters():
	if _material:
		var calculated_lightness = min(stack_level * LIGHTNESS_PER_LEVEL, MAX_LIGHTNESS)
		_material.set_shader_parameter("lightness", calculated_lightness)
		_material.set_shader_parameter("chip_offset", _chip_offset)
		_material.set_shader_parameter("cookie_scale", Vector3(width, height, depth))
