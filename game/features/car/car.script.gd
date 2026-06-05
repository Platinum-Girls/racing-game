class_name CarBase extends CharacterBody3D

@export var input_provider: InputProvider
@export var mesh: Node3D
@export var front_right_wheel: Node3D
@export var front_left_wheel: Node3D
@export var floor_cast: ShapeCast3D
@export var front_ray: ShapeCast3D
@export var rear_ray: ShapeCast3D

@export_group("Physical Properties")
@export_custom(0, "suffix:m/s") var gravity: float = -20
@export_custom(0, "suffix:m/s") var jump_speed: float = 20
@export_custom(0, "suffix:m") var wheel_base: float = 0.6

@export_group("Steering")
@export_custom(0, "suffix:deg/10/s") var max_steering_speed := 10
@export_custom(0, "suffix:deg/10/s²") var steer_acceleration := 0.4
@export_custom(0, "suffix:deg/10/s²") var steer_deceleration := 0.4
@export var steer_wheel_angle_multiplier := 1.2
@export var steer_mesh_angle_multiplier := 1.2

@export_group("Engine")
@export_custom(0, "suffix:m/s²") var engine_power: float = 6
@export_custom(0, "suffix:m/s²") var braking: float = -9
@export_custom(0, "suffix:m/s²") var friction: float = 2
@export_custom(0, "suffix:m/s²") var lateral_friction: float = 10
@export_custom(0, "suffix:m/s²") var drag: float = 2
@export_custom(0, "suffix:m/s") var max_speed_reverse: float = 3

@export_group("Drifting")
@export_custom(0, "suffix:%") var base_drifting_acceleration_perc := 80.0
@export_custom(0, "suffix:deg/10/s²") var outward_centrifugal_force := 0.4
@export_custom(0, "suffix:deg/10/s") var base_drifting_turn_speed := 10.0
@export_custom(0, "suffix:deg/10/s") var inward_drifting_turn_speed := 10.0
@export_custom(0, "suffix:deg/10/s") var outward_drifting_turn_speed := 10.0

@export var drifting_mesh_angle_multiplier = 1.4
#@export_custom(0, "suffix:deg/10/s") var base_drifting_speed := 10

@onready var camera_container: Node3D = $CameraContainer
@onready var state_chart: StateChart = $"Car States"

const STICK_TO_LOOP_THRESHOLD = 16

# Car state properties
var current_steer_direction: float

var steer_input: float

static func clamp01(number: float) -> float:
	return clampf(number, 0.0, 1.0)

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


func apply_acceleration(delta: float) -> void:
	var acceleration = Vector3.ZERO
	if input_provider.is_accelerating():
		acceleration = -transform.basis.z * engine_power
	if input_provider.is_braking():
		acceleration = -transform.basis.z * braking
	
	velocity += acceleration * delta
	


func apply_friction(delta: float) -> void:
	var xz_vel = velocity.slide(up_direction)
	if xz_vel.length() < 0.1 and is_zero_approx(input_provider.get_acceleration_axis()):
		velocity = up_direction * velocity.dot(up_direction)
		return
		
	var fwd_vel = basis.z * velocity.dot(basis.z)
	velocity -= fwd_vel.normalized() * friction * delta
	var lateral_vel = basis.x * velocity.dot(basis.x)
	velocity -= lateral_vel.normalized() * lateral_friction * delta
	
	velocity -= velocity * velocity.length() * drag * delta
	
	if velocity.dot(-basis.z) < 0:
		velocity = velocity.normalized() * min(velocity.length(), max_speed_reverse)


func calculate_steer_direction() -> void:
	var target_steer_direction := steer_input * deg_to_rad(max_steering_speed/10.0)
	if input_provider.is_braking(): 
		target_steer_direction = -target_steer_direction
	
	var diff = target_steer_direction - current_steer_direction
	
	var speed = velocity.slide(up_direction).length()
	
	if speed > 2:
		var t = clampf(speed / 20.0, 0, 1)
		var accel := lerpf(0.0, steer_acceleration, t)
		var decel := steer_deceleration
		
		var acceleration_rate = accel if sign(target_steer_direction) != 0 else decel
		
		current_steer_direction += diff * acceleration_rate/10 # ignore delta since we're inside physics step
	else:
		current_steer_direction = lerp(current_steer_direction, 0.0, steer_deceleration)
	

func perform_steering() -> void:
	if floor_cast.is_colliding():
		var new_basis = velocity.rotated(basis.y, current_steer_direction).normalized()
		
		rotation.y += current_steer_direction
		
		velocity = velocity.length() * new_basis

func align_with_ground() -> void:
	# If either wheel is in the air, align to slope.
	if front_ray.is_colliding() or rear_ray.is_colliding():
		# If one wheel is in air, move it down
		var nf := front_ray.get_collision_normal(0) if front_ray.is_colliding() else Vector3.UP
		var nr := rear_ray.get_collision_normal(0) if rear_ray.is_colliding() else Vector3.UP
		var n := ((nr + nf) / 2.0).normalized()
		var xform := align_with_y(global_transform, n)
		global_transform = global_transform.interpolate_with(xform, 0.1)

func align_with_y(xform, new_y) -> Transform3D:
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
	
func steering_visual_feedback(delta: float) -> void:
	var speed = velocity.slide(up_direction).length()
	var mesh_yaw_t = pow(clampf(speed / 20, 0, 1), 0.5)
	
	var mesh_yaw := 0.0
	if speed > 2:
		mesh_yaw = lerp(0.0, steer_input * deg_to_rad(max_steering_speed) * steer_mesh_angle_multiplier, mesh_yaw_t)
	if input_provider.is_braking(): 
		mesh_yaw = -mesh_yaw

	var wheel_angle = lerp(0.0, steer_input * deg_to_rad(max_steering_speed) * steer_wheel_angle_multiplier, mesh_yaw_t)
	front_right_wheel.rotation.y = lerp_angle(front_right_wheel.rotation.y, wheel_angle, delta*4)
	front_left_wheel.rotation.y = lerp_angle(front_left_wheel.rotation.y, wheel_angle, delta*4)
	
	mesh.rotation.z = lerp_angle(mesh.rotation.z, -current_steer_direction*2, delta * 20)
	mesh.rotation.y = lerp_angle(mesh.rotation.y, mesh_yaw, delta*4)


func _on_grounded_physics_processing(delta: float) -> void:
	if velocity.length() > STICK_TO_LOOP_THRESHOLD:
		up_direction = floor_cast.get_collision_normal(0)
	else:
		up_direction = Vector3.UP
	
	apply_friction(delta)
	align_with_ground()

func _on_grounded_processing(delta: float) -> void:
	pass

var air_counter = 0
func _on_air_physics_processing(delta: float) -> void:
	current_steer_direction = 0
	up_direction = Vector3.UP
	air_counter += delta
	
	var mult = pow(clamp01(air_counter / 1), 2)
	
	quaternion = quaternion.slerp(Quaternion(Vector3.UP, rotation.y), delta * (0.1 + 2*mult))

func _on_air_processing(delta: float) -> void:
	steering_visual_feedback(delta)


func _on_air_exited() -> void:
	air_counter = 0


#region DRIFTING

func drifting_visual_feedback(delta: float) -> void:
	var turn_speed = calculate_drifting_turn_speed(sign(steer_input))
	
	var mesh_yaw = drifting_direction * deg_to_rad(turn_speed) * drifting_mesh_angle_multiplier

	var wheel_angle = drifting_direction * deg_to_rad(max_steering_speed) * steer_wheel_angle_multiplier
	front_right_wheel.rotation.y = lerp_angle(front_right_wheel.rotation.y, wheel_angle, delta*4)
	front_left_wheel.rotation.y = lerp_angle(front_left_wheel.rotation.y, wheel_angle, delta*4)
	
	#mesh.rotation.z = lerp_angle(mesh.rotation.z, -current_steer_direction*2, delta * 20)
	mesh.rotation.y = lerp_angle(mesh.rotation.y, mesh_yaw, delta*4)

func calculate_drifting_turn_speed(input: int) -> float:
	if input == drifting_direction:
		return inward_drifting_turn_speed
	elif input == -drifting_direction:
		return outward_drifting_turn_speed
	return base_drifting_turn_speed

var drifting_direction: int
func _on_drifting_entered() -> void:
	drifting_direction = sign(steer_input)


func _on_drifting_physics_processing(delta: float) -> void:
	velocity += -transform.basis.z * engine_power * delta
	
	var turn_speed = calculate_drifting_turn_speed(sign(steer_input))
	current_steer_direction = drifting_direction * deg_to_rad(turn_speed/10.0)
	perform_steering()
	
	# outward drifting
	if sign(steer_input) != drifting_direction:
		velocity += basis.x * drifting_direction * outward_centrifugal_force * delta
	


func _on_drifting_processing(delta: float) -> void:
	drifting_visual_feedback(delta)
	
	camera_container.rotation.y = lerp_angle(camera_container.rotation.y, drifting_direction*deg_to_rad(-5), delta * 4)


#endregion


func _on_normal_state_processing(delta: float) -> void:
	steering_visual_feedback(delta)
	camera_container.rotation.y = lerp_angle(camera_container.rotation.y, 0, delta * 4)


func _on_normal_state_physics_processing(delta: float) -> void:
	apply_acceleration(delta)
	calculate_steer_direction()
	perform_steering()
