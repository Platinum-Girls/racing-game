extends Label

@export var car: CarBase


func _physics_process(delta: float) -> void:
	
	var fwd_vel = car.velocity.slide(car.up_direction)
	var max_speed = sqrt((car.engine_power - car.friction) / (car.drag))
	
	text = (
		"Speed: %sm/s\nAcceleration: %sm/s²\nPress R to reset\n%s\n%s\nMAX SPEED: %s"
		% [car.velocity.slide(car.up_direction).length(), car.acceleration.length(), car.current_steer_direction,
		"GROUNDED" if car.is_on_floor() else "NOT GROUNDED", max_speed]
	)
