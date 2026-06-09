@tool
class_name SpinRotator extends Node3D

@export var rotate_speed: float = 0
@export var rotate_axis: Vector3 = Vector3.UP


func _ready() -> void:
	rotation_degrees *= (Vector3.ONE - rotate_axis)


func _process(delta: float) -> void:
	rotation_degrees += rotate_axis * rotate_speed * delta
