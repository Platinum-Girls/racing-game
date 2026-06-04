extends Label

@export var car: CarBase


func _physics_process(_delta: float) -> void:
	text = (
		"Speed: %sm/s\nAcceleration: %sm/s²\nBoost Progress: %s\nPress R to reset"
		% [car.velocity.slide(car.up_direction).length(), car.acceleration.length(), car.drift_module.boost_progress]
	)
