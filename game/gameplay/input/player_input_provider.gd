class_name PlayerInputProvider extends InputProvider


func is_accelerating() -> bool:
	return Input.is_action_pressed(&"accelerate")


func is_braking() -> bool:
	return Input.is_action_pressed(&"brake")


func get_acceleration_axis() -> float:
	return Input.get_axis(&"accelerate", &"brake")


func get_steering_axis() -> float:
	return Input.get_axis(&"steer_right", &"steer_left")
	
func is_jumping() -> bool:
	return Input.is_action_just_pressed("jump")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		get_tree().reload_current_scene()
