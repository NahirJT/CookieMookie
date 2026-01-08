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
	var box = BoxMesh.new()
	box.size = Vector3(width, height, depth)
	_Mesh.mesh = box
	
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, height, depth)
	_Collision.shape = box_shape
	
	_Mesh.transform = Transform3D(Basis.IDENTITY, Vector3(0, height * 0.5, 0))
	
func set_color(hue: float):
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_hsv(hue, 0.6, 1.0)
	mat.metallic = 0.0
	_Mesh.set_surface_override_material(0, mat)
	
func duplicate_block() -> Node3D:
	var dup = duplicate() as Node3D
	return dup
	
