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
@export var steer_wheel_angle_multiplier := 1.2
@export var steer_mesh_angle_multiplier := 1.2

@export_group("Engine")
@export_custom(0, "suffix:m/s") var engine_power: float = 6
@export_custom(0, "suffix:m/s") var braking: float = -9
@export_custom(0, "suffix:m/s") var friction: float = -2
@export_custom(0, "suffix:m/s²") var drag: float = -2
@export_custom(0, "suffix:m/s") var max_speed_reverse: float = 3


const STICK_TO_LOOP_THRESHOLD = 16

# Car state properties
var acceleration := Vector3.ZERO
var current_steer_direction: float

var steer_input: float


func xz(vec: Vector3) -> Vector3:
	return Vector3(vec.x, 0, vec.z)


func _physics_process(delta: float) -> void:
	acceleration = Vector3.ZERO
	steer_input = input_provider.get_steering_axis()
	
	if floor_cast.is_colliding():
		apply_acceleration()
		apply_friction(delta)
		
	calculate_steering(delta)
	velocity += acceleration * delta

	if input_provider.is_jumping() && floor_cast.is_colliding():
		velocity.y += jump_speed
	else:
		velocity += get_gravity_vector() * delta
	
	move_and_slide()

	align_with_ground()


func get_gravity_vector() -> Vector3:
	if floor_cast.is_colliding() and floor_cast.is_colliding() and velocity.length() > STICK_TO_LOOP_THRESHOLD:
		up_direction = floor_cast.get_collision_normal(0)
	else:
		up_direction = Vector3.UP

	return up_direction * gravity


func apply_acceleration() -> void:
	if input_provider.is_accelerating():
		acceleration = -transform.basis.z * engine_power
	if input_provider.is_braking():
		acceleration = -transform.basis.z * braking


func apply_friction(delta: float) -> void:
	if xz(velocity).length() < 0.2 and xz(acceleration).length() < 0.01:
		velocity.x = 0
		velocity.z = 0
		return

	var friction_force: Vector3 = velocity * friction * delta
	var drag_force: Vector3 = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force


func calculate_steering(delta: float) -> void:
	
	
	var target_steer_direction := steer_input * deg_to_rad(max_steering_speed/10.0)
	var diff = target_steer_direction - current_steer_direction
	
	var speed = velocity.slide(up_direction).length()
	
	var t = clampf(speed / 10.0, 0, 1)
	var accel = lerp(0.0, steer_acceleration, t)
	current_steer_direction += diff * accel/10 # ignore delta since we're inside physics step
	
	
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



func _process(delta: float) -> void:
	steering_visual_feedback(delta)
	
func steering_visual_feedback(delta: float) -> void:
	var speed = velocity.slide(up_direction).length()
	var mesh_yaw_t = pow(clampf(speed / 15, 0, 1), 0.5)
	var mesh_yaw = lerp(0.0, steer_input * deg_to_rad(max_steering_speed) * steer_mesh_angle_multiplier, mesh_yaw_t)
	
	mesh.rotation.z = lerp_angle(mesh.rotation.z, -current_steer_direction*2, delta * 20)
	front_right_wheel.rotation.y = current_steer_direction * steer_wheel_angle_multiplier
	front_left_wheel.rotation.y = current_steer_direction * steer_wheel_angle_multiplier
	mesh.rotation.y = lerp_angle(mesh.rotation.y, mesh_yaw, delta*4)
