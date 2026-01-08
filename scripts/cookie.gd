extends Node3D

@export var width: float = 2.0
@export var depth: float = 2.0
@export var height: float = 0.6

var movement_axis: String = "x"

@onready var _mesh_instance: MeshInstance3D = %MeshInstance3D
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D


func _ready():
	update_mesh()


func update_mesh():
	var cookie_mesh = BoxMesh.new()
	cookie_mesh.size = Vector3(width, height, depth)
	_mesh_instance.mesh = cookie_mesh

	var cookie_collision_shape = BoxShape3D.new()
	cookie_collision_shape.size = Vector3(width, height, depth)
	_collision_shape.shape = cookie_collision_shape

	# Offsets both mesh and collision so the cookie sits on top of its origin.
	var offset = Vector3(0, height * 0.5, 0)
	_mesh_instance.transform = Transform3D(Basis.IDENTITY, offset)
	_collision_shape.transform = Transform3D(Basis.IDENTITY, offset)
