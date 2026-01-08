extends Node3D

@export var width: float = 2.0
@export var depth: float = 2.0
@export var height: float = 0.6
@export var custom_mesh: Mesh = null

var movement_axis: String = "x"

@onready var _mesh: MeshInstance3D = %MeshInstance3D
@onready var _collider: CollisionShape3D = %CollisionShape3D


func _ready():
	update_mesh()


func update_mesh():
	if custom_mesh:
		_mesh.mesh = custom_mesh
		_mesh.scale = Vector3(width, height, depth)
	else:
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3.ONE
		_mesh.mesh = box_mesh
		_mesh.scale = Vector3(width, height, depth)

	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, height, depth)
	_collider.shape = box_shape

	# Offsets both mesh and collision so the cookie sits on top of its origin.
	var offset = Vector3(0, height * 0.5, 0)
	_mesh.transform.origin = offset
	_collider.transform.origin = offset
