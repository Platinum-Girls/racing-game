extends Node3D


@export var target: Node3D

@export var rotation_speed: float = 4
@export var mouse_sensibility: float  = 0.005


func _ready() -> void:
	#DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	pass


func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(target.global_position, delta * 18)
	quaternion = quaternion.slerp(target.quaternion, delta * 12)
