extends Label


@onready var car: CarBase = $"../Car"




func _physics_process(delta: float) -> void:
	text = 'Speed: %sm/s\nAcceleration: %sm/s²\nPress R to reset' % [car.velocity.slide(car.up_direction).length(), car.acceleration.length()]
