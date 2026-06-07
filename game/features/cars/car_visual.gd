class_name CarVisual extends Node3D

var animation_tree: AnimationTree

@export var speed_smoothing: float = 1

var target_speed_factor: float
var speed_factor := 0.0

func _ready() -> void:
	print_tree_pretty()
	animation_tree = $AnimationTree
	
func _process(delta: float) -> void:
	speed_factor = lerpf(speed_factor, target_speed_factor, delta * speed_smoothing)
	animation_tree.set(&"parameters/speed_blend/blend_position", speed_factor)

func set_speed_blend(factor: float) -> void:
	target_speed_factor = factor
	
func trigger_hop() -> void:
	animation_tree.set(&"parameters/hop_trigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
