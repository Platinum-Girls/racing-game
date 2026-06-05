extends Node3D

@export var car: CarBase

func round_places(number: float, places: int = 2) -> float:
	var tp = pow(10, places)
	return round(number * tp) / tp

func _process(delta: float) -> void:
	
	var fwd_vel = car.velocity.slide(car.up_direction)
	var max_speed = sqrt((car.engine_power - car.friction) / (car.drag))
	
	var text = "Speed: %sm/s\nMax Speed: %sm/s\nGrounded? %s" \
		% [round_places(car.velocity.slide(car.up_direction).length()), 
		round_places(max_speed), car.is_on_floor()]
		
	ImmediateGizmos3D.set_transform(self.global_transform)
	ImmediateGizmos3D.draw_text(text, Vector3.ZERO)
