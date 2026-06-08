class_name CarBase extends CharacterBody3D

@export var input_provider: InputProvider
@export var mesh_scene: PackedScene
@export var character_scene: PackedScene

@export var floor_cast: ShapeCast3D
@export var front_ray: ShapeCast3D
@export var rear_ray: ShapeCast3D

@export_group("Physical Properties")
@export_custom(0, "suffix:m/s") var gravity: float = -20
@export_custom(0, "suffix:m/s") var jump_speed: float = 20
@export_custom(0, "suffix:m") var wheel_base: float = 0.6
@export var align_with_ground_lerp_weight: float          = 0.1


@export_group("Steering")
@export_custom(0, "suffix:deg") var max_tire_angle: float = 0.75
@export_custom(0, "suffix:deg/s²") var  wheel_turn_acceleration: float = .001
@export var air_steer_control := 0.35

@export_group("Engine")
@export_custom(0, "suffix:m/s²") var engine_power: float = 6
@export_custom(0, "suffix:m/s²") var braking: float = -9
@export_custom(0, "suffix:m/s²") var friction: float = 2
@export_custom(0, "suffix:m/s²") var lateral_friction: float = 10
@export_custom(0, "suffix:m/s²") var drag: float = 2
@export_custom(0, "suffix:m/s") var max_speed_reverse: float = 3

@export_group("Drifting")
@export_custom(0, "suffix:%") var base_drifting_acceleration_perc := 80.0
@export_custom(0, "suffix:m/s²") var outward_centrifugal_force := 23
@export_custom(0, "suffix:m/s²") var outward_centrifugal_erase := 5
@export_custom(0, "suffix:deg/s") var base_drifting_turn_speed := 10.0
@export_custom(0, "suffix:deg/s") var inward_drifting_turn_speed := 10.0
@export_custom(0, "suffix:deg/s") var outward_drifting_turn_speed := 10.0

@export_group("Visual Levers")
const drift_camera_angle_modifier: float = 2
const drift_camera_decay_rate: float     = 0.1

@export var camera_container: Node3D
@export var state_chart: StateChart

var visual: VehicleVisual
var character: Node3D

const FRICTION_STOP_THRESHOLD: float = 0.1
const STICK_TO_LOOP_THRESHOLD: float = 16
##Weighting to velocity so turn rate is proportional to velocity. Set 1 one for rotation to snap to heaidng direction.
const VELO_Z_TURN_WEIGHT: float = .2


# Car state properties
var current_steer_direction: float
var wheel_turn_speed: float = 0

var steer_input: float
var drifting_direction: int

func _ready() -> void:
	if mesh_scene and character_scene:
		setup_visual()

func setup_visual() -> void:
	visual = mesh_scene.instantiate()
	character = character_scene.instantiate()
	add_child(visual)
	visual.character_root.add_child(character)


func _physics_process(delta: float) -> void:
	move_and_slide()
	
	steer_input = input_provider.get_steering_axis()
	
	if input_provider.is_jump_pressed() && floor_cast.is_colliding():
		velocity.y += jump_speed
	else:
		velocity += up_direction * gravity * delta
	
	state_chart.set_expression_property(&"drifting", input_provider.is_drifting())
	state_chart.set_expression_property(&"accelerating", input_provider.is_accelerating())
	state_chart.set_expression_property(&"grounded", floor_cast.is_colliding())
	state_chart.set_expression_property(&"steer_input", roundi(steer_input))
	state_chart.set_expression_property(&"velocity", velocity.slide(up_direction).length())
	
	
	if input_provider.is_drift_pressed():
		state_chart.send_event(&"drift_pressed")


func apply_acceleration(delta: float) -> void:
	var acceleration: Vector3 = Vector3.ZERO
	if input_provider.is_accelerating():
		acceleration = -transform.basis.z * engine_power
	if input_provider.is_braking():
		acceleration = -transform.basis.z * braking
	
	velocity += acceleration * delta
	

func apply_friction(delta: float) -> void:
	var xz_vel: Vector3 = velocity.slide(up_direction)
	if xz_vel.length() < FRICTION_STOP_THRESHOLD and is_zero_approx(input_provider.get_acceleration_axis()):
		velocity = up_direction * velocity.dot(up_direction)
		return
		
	var fwd_vel: Vector3 = basis.z * velocity.dot(basis.z)
	velocity -= fwd_vel.normalized() * friction * delta
	var lateral_vel: Vector3 = basis.x * velocity.dot(basis.x)
	velocity -= lateral_vel.normalized() * lateral_friction * delta
	
	velocity -= velocity * velocity.length() * drag * delta
	
	if velocity.dot(-basis.z) < 0:
		velocity = velocity.normalized() * min(velocity.length(), max_speed_reverse)


func calculate_steer_direction(delta: float, multiplier: float  = 1, turn_angle: float = max_tire_angle) -> void:
	#If player is changing between backing up/going forward begin changing direction of turn. if 0 use current speed sign to simulate carrying inertia
	var acceleration_sign: float = sign(input_provider.get_acceleration_axis_sign())
	if acceleration_sign == 0:
		acceleration_sign = sign(velocity.slide(up_direction).dot(basis.z))
		
	var target_steer_direction := -steer_input * acceleration_sign * deg_to_rad(max_tire_angle) * multiplier
	wheel_turn_speed = move_toward(wheel_turn_speed, deg_to_rad(turn_angle), deg_to_rad(wheel_turn_acceleration) * delta)
	current_steer_direction = move_toward(current_steer_direction, target_steer_direction, wheel_turn_speed)

func perform_steering() -> void:
	var new_heading: Vector3 = velocity.rotated(basis.y, current_steer_direction).normalized()
	basis = basis.slerp(basis.rotated(up_direction, current_steer_direction), MathUtils.clamp01(velocity.slide(up_direction).length() * VELO_Z_TURN_WEIGHT)).orthonormalized()

	velocity = velocity.length() * new_heading

func align_with_ground() -> void:
	# If either wheel is in the air, align to slope.
	if front_ray.is_colliding() or rear_ray.is_colliding():
		# If one wheel is in air, move it down
		var nf := front_ray.get_collision_normal(0) if front_ray.is_colliding() else Vector3.UP
		var nr := rear_ray.get_collision_normal(0) if rear_ray.is_colliding() else Vector3.UP
		var n := ((nr + nf) / 2.0).normalized()
		var xform: Transform3D = align_with_y(global_transform, n)
		global_transform = global_transform.interpolate_with(xform, align_with_ground_lerp_weight)

func align_with_y(xform, new_y) -> Transform3D:
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

#region GROUND STATE

func _on_grounded_physics_processing(delta: float) -> void:
	if velocity.length() > STICK_TO_LOOP_THRESHOLD:
		up_direction = floor_cast.get_collision_normal(0)
	else:
		up_direction = Vector3.UP
	
	apply_friction(delta)
	align_with_ground()

func _on_grounded_processing(_delta: float) -> void:
	var fwd_vel: float = velocity.slide(up_direction).dot(-basis.z)
	var blend: float   = 0
	if fwd_vel > 0: # accelerating
		blend = MathUtils.clamp01(fwd_vel / 20.0)
	else: # reversing
		blend = MathUtils.clamp01(fwd_vel / max_speed_reverse)

	visual.set_speed_blend(blend)

#endregion


#region GROUND DRIFTING

func drifting_visual_feedback() -> void:
	var turn_speed: float = calculate_drifting_turn_speed(sign(steer_input))
	visual.set_drifting_yaw_rot(drifting_direction * deg_to_rad(turn_speed))
	visual.set_wheel_rot(drifting_direction)
	visual.set_target_roll_rot(current_steer_direction)
	

func calculate_drifting_turn_speed(input: int) -> float:
	if input == drifting_direction:
		return inward_drifting_turn_speed
	elif input == -drifting_direction:
		return outward_drifting_turn_speed
	return base_drifting_turn_speed

func _on_drifting_entered() -> void:
	drifting_direction = sign(steer_input)
	visual.trigger_hop()

func _on_drifting_state_exited() -> void:
	camera_container.rotation.y = 0 #reset camera drift rotation, camera lerps its own rotation
	camera_container.basis = camera_container.basis.orthonormalized()

func _on_drifting_physics_processing(delta: float) -> void:
	velocity += -transform.basis.z * engine_power * delta
	
	var turn_speed: float = calculate_drifting_turn_speed(sign(steer_input))
	current_steer_direction = drifting_direction * deg_to_rad(turn_speed) #force set directly to drifting turn speed
	perform_steering()
#	print_debug("---------------------")
#	print_debug(velocity)
#	# outward drifting
#	if sign(steer_input) == -drifting_direction:
#		velocity += basis.x * drifting_direction * outward_centrifugal_force * delta
#	else: # erase outward drifting faster 
#		var outward_velocity := velocity.dot(basis.x)
#		velocity -= basis.x * outward_velocity * outward_centrifugal_erase * delta
#	print_debug(velocity)


func _on_drifting_processing(delta: float) -> void:
	drifting_visual_feedback()
	camera_container.rotation.y = lerp_angle(camera_container.rotation.y, drifting_direction*drift_camera_angle_modifier, MathUtils.lerp_delta_decay(drift_camera_decay_rate, delta))


#endregion

#region GROUND NORMAL

func _on_normal_state_processing(_delta: float) -> void:
	visual.set_target_roll_rot(current_steer_direction)
	visual.set_speed_based_yaw(steer_input * deg_to_rad(max_tire_angle), velocity.dot(-basis.z))
	visual.set_wheel_rot(steer_input)

func _on_normal_state_physics_processing(delta: float) -> void:
	apply_acceleration(delta)
	calculate_steer_direction(delta)
	perform_steering()

#endregion

#region AIR STATE

const AIR_RIGHTING_DECAY_RATE := 0.12
func _on_air_physics_processing(delta: float) -> void:
	visual.set_speed_blend(0)
	
	calculate_steer_direction(delta, air_steer_control)
	perform_steering()
	
	up_direction = Vector3.UP
	
	quaternion = quaternion.slerp(Quaternion(Vector3.UP, rotation.y), MathUtils.lerp_delta_decay(AIR_RIGHTING_DECAY_RATE, delta))

func _on_air_processing(_delta: float) -> void:
	visual.set_target_roll_rot(current_steer_direction)
	visual.set_speed_based_yaw(steer_input * deg_to_rad(max_tire_angle), velocity.dot(-basis.z))
	visual.set_wheel_rot(steer_input)
	


func _on_air_exited() -> void:
	pass

#endregion
