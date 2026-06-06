class_name CarVisual extends Node3D

var animation_tree: AnimationTree

func _ready() -> void:
	print_tree_pretty()
	animation_tree = $AnimationTree

func set_speed_blend(factor: float) -> void:
	animation_tree.set(&"parameters/speed_blend/blend_amount", factor)
	
func trigger_hop() -> void:
	animation_tree.set(&"parameters/hop/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
