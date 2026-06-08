class_name VehicleVisual extends Node3D

@export var animation_tree: AnimationTree
@export var character_root: Marker3D

@export var speed_smoothing: float = 0.1

@export var wheel_angle_multiplier := 12.0
@export var drifting_yaw_multiplier := 20.0
@export var mesh_yaw_multiplier := 10.0
@export var mesh_roll_multiplier := -500.0

@export var tire_rot_speed: float = 2
@export var mesh_yaw_speed: float = 1
@export var mesh_roll_speed: float = .2

@export var max_speed_yaw := 20

@export var rotating_wheels: Array[Node3D]

var target_roll_rot: float
var target_yaw_rot: float
var target_wheel_rot: float
var target_speed_factor: float
var speed_factor := 0.0


func _ready() -> void:
	print_tree_pretty()
	
func _process(delta: float) -> void:
	speed_factor = lerpf(speed_factor, target_speed_factor, MathUtils.lerp_delta_decay(speed_smoothing, delta))
	animation_tree.set(&"parameters/speed_blend/blend_position", speed_factor)
	
	rotation.y = rotate_toward(rotation.y, target_yaw_rot, mesh_yaw_speed * delta)
	rotation.z = rotate_toward(rotation.z, target_roll_rot, mesh_roll_speed * delta)
	
	for wheel in rotating_wheels:
		wheel.rotation.y = rotate_toward(wheel.rotation.y, target_wheel_rot, tire_rot_speed * delta)


## [method set_speed_based_yaw] uses this value to divide speed into a [0, 1] range, 
## which is then passed to [method set_target_yaw_rot] to drive mesh yaw rotation.[br]
## This value defines the speed the vehicle needs to achieve in order to be able to 
## rotate and steer with max values
func set_speed_based_yaw(intended_yaw: float, speed: float) -> void:
	var yaw_multiplier := pow(MathUtils.clamp01(abs(speed) / max_speed_yaw), 0.5)
	if speed < 0:
		yaw_multiplier = -1.0
	
	set_target_yaw_rot(intended_yaw * yaw_multiplier)

func set_drifting_yaw_rot(yaw: float) -> void:
	target_yaw_rot = yaw * drifting_yaw_multiplier
	

func set_target_yaw_rot(yaw: float) -> void:
	target_yaw_rot = yaw * mesh_yaw_multiplier


func set_target_roll_rot(roll: float) -> void:
	target_roll_rot = deg_to_rad(roll * mesh_roll_multiplier)

func set_wheel_rot(yaw: float) -> void:
	target_wheel_rot = yaw * wheel_angle_multiplier


# ANIMATION TREE HANDLES

func set_speed_blend(factor: float) -> void:
	target_speed_factor = factor
	
func trigger_hop() -> void:
	animation_tree.set(&"parameters/hop_trigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
