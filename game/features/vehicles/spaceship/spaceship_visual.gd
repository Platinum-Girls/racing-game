extends VehicleVisual
@onready var pivot: SpinRotator = $Pivot

@export var ufo_rotate_multiplier := 20

func _process(delta: float) -> void:
	super._process(delta)
	
	
	var speed_multiplier := 1.0
	if sign(pivot.rotate_speed) != sign(target_wheel_rot):
		speed_multiplier *= 4
	
	pivot.rotate_speed = lerp(
		pivot.rotate_speed, 
		target_wheel_rot * ufo_rotate_multiplier, 
		delta * speed_multiplier * 1.35
		)
