extends Label

@export var car: CarBase


func _physics_process(_delta: float) -> void:
	text = (
		"Speed: %sm/s\nAcceleration: %sm/s²\nPress R to reset"
		% [car.velocity.slide(car.up_direction).length(), car.acceleration.length()]
	)
