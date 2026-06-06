@tool
extends MeshInstance3D

@export var rotate_speed: float = 0

func _ready() -> void:
	rotation_degrees.x = 0

func _process(delta: float) -> void:
	rotation_degrees.x += rotate_speed * delta
