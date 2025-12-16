extends Node3D

@export var width: float = 2.0
@export var depth: float = 2.0
@export var height: float = 0.6

var move_axis: String = "x"


@onready var _Mesh: MeshInstance3D = %Mesh
@onready var _Collision: CollisionShape3D = %Collision

func _ready():
	_update_mesh()
	
func _update_mesh():
	var sphere = SphereMesh.new()
	sphere.size = Vector3(width, height, depth)
	_Mesh.mesh = sphere
	
	var sphere_shape = SphereShape3D.new()
	sphere_shape.size = Vector3(width, height, depth)
	_Collision.shape = sphere_shape
	
