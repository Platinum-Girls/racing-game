extends Node3D


@export var target: Node3D

@export var rotation_speed: float = 4
@export var mouse_sensibility: float  = 0.005

@export var cameras: Array[Camera3D]

var current = 0


func _ready() -> void:
	cameras[0].make_current()
	#DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"switch_view"):
		current += 1
		current = current % 2
		cameras[current].make_current()

func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(target.global_position, delta * 18)
	quaternion = quaternion.slerp(target.quaternion, delta * 12)
