@abstract
class_name InputProvider extends Node

@abstract
func is_accelerating() -> bool

@abstract
func is_braking() -> bool

@abstract
func get_acceleration_axis() -> float

@abstract
func get_steering_axis() -> float

@abstract
func is_jump_pressed() -> bool
	

@abstract
func is_drifting() -> bool

@abstract
func is_drift_pressed() -> bool
