extends Node3D

@export var start_block_width: float = 2.0
@export var start_block_depth: float = 2.0
@export var block_height: float = 0.3
@export var move_range: float = 4.0
@export var move_speed_base: float = 4.0
@export var speed_increase_per_level: float = 0.03
@export var perfect_threshold: float = 0.06
@export var min_overlap_to_continue: float = 0.01

@onready var BlockScene: PackedScene = preload("res://scenes/block.tscn")


@onready var stack_root: Node3D = $StackRoot
@onready var moving_holder: Node3D = $MovingBlock
@onready var hud: Node = $CanvasLayer/HUD
@onready var game_camera: Camera3D = $Camera3D


var level: int = 0
var score: int = 0
var direction := "x"
var current_block: Node3D = null
var last_block: Node3D = null
var game_over: bool = false
var move_time: float = 0.0
var camera_target_y: float = 6.0
