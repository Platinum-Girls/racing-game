extends VehicleVisual
@export var pivot: SpinRotator

@export var ufo_rotate_multiplier: float = 20
@export var base_rotate_speed_multiplier: float = 999
@export var rotate_speed_change_dir_multiplier: float = 10

func _process(delta: float) -> void:
	super._process(delta)
	
	var speed_multiplier: float = base_rotate_speed_multiplier
	if sign(pivot.rotate_speed) != sign(target_wheel_rot):
		speed_multiplier *= rotate_speed_change_dir_multiplier
	
	pivot.rotate_speed = move_toward(
		pivot.rotate_speed, 
		target_wheel_rot * ufo_rotate_multiplier, 
		delta * speed_multiplier
		)
