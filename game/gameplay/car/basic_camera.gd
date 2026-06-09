extends Node3D

@export var target: Node3D

@export var rotation_speed: float = 4
@export var mouse_sensibility: float = 0.005

@export var position_decay_rate: float = 0.0
@export var rotation_decay_rate: float = 0.0

@export var cameras: Array[Camera3D]

var current: int = 0


func _ready() -> void:
	cameras[0].make_current()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"switch_view"):
		current += 1
		current = current % 2
		cameras[current].make_current()


func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(
		target.global_position, MathUtils.lerp_delta_decay(position_decay_rate, delta)
	)
	global_basis = (
		global_basis
		. slerp(
			target.global_basis.orthonormalized(),
			MathUtils.lerp_delta_decay(rotation_decay_rate, delta)
		)
		. get_rotation_quaternion()
	)
	#TODO: Are there still ocasional invalid basis errors?
