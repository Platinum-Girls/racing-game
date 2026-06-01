class_name CarBase extends CharacterBody3D

@export var input_provider: InputProvider
@export var front_right_wheel: Node3D
@export var front_left_wheel: Node3D
@export var floor_cast: ShapeCast3D
@export var front_ray: ShapeCast3D
@export var rear_ray: ShapeCast3D

@export_group("Car Properties")
@export_custom(0, "suffix:m/s") var gravity: float = -20
@export_custom(0, "suffix:m") var wheel_base: float = 0.6
@export_custom(0, "suffix:deg") var steering_limit: float = 10
@export_custom(0, "suffix:deg/s") var steering_speed: float = 8
@export_custom(0, "suffix:m/s") var engine_power: float = 6
@export_custom(0, "suffix:m/s") var braking: float = -9
@export_custom(0, "suffix:m/s") var friction: float = -2
@export_custom(0, "suffix:m/s²") var drag: float = -2
@export_custom(0, "suffix:m/s") var max_speed_reverse: float = 3

const STICK_TO_LOOP_THRESHOLD: float = 16

# Car state properties
var acceleration := Vector3.ZERO
var steer_angle: float = 0.0


func xz(vec: Vector3) -> Vector3:
	return Vector3(vec.x, 0, vec.z)


func _physics_process(delta: float) -> void:
	acceleration = Vector3.ZERO
	if is_on_floor():
		apply_input(delta)
		apply_friction(delta)
		calculate_steering(delta)
	velocity += acceleration * delta

	velocity += get_gravity_vector() * delta

	move_and_slide()

	align_with_ground()


func get_gravity_vector() -> Vector3:
	if is_on_floor() and floor_cast.is_colliding() and velocity.length() > STICK_TO_LOOP_THRESHOLD:
		up_direction = floor_cast.get_collision_normal(0)
	else:
		up_direction = Vector3.UP

	return up_direction * gravity


func apply_input(delta: float) -> void:
	var steer := input_provider.get_steering_axis()
	steer_angle = lerp(steer_angle, steer * deg_to_rad(steering_limit), delta * steering_speed)

	front_right_wheel.rotation.y = steer_angle
	front_left_wheel.rotation.y = steer_angle

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
	var rear_wheel: Vector3 = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel: Vector3 = transform.origin - transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(transform.basis.y, steer_angle) * delta
	var new_heading := rear_wheel.direction_to(front_wheel)
	var d := new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = new_heading * velocity.length()
	elif d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	look_at(transform.origin + new_heading, transform.basis.y)


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
