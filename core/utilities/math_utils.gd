class_name MathUtils extends Node


static func clamp01(number: float) -> float:
	return clampf(abs(number), 0.0, 1.0) * sign(number)

##Properly lerp across delta to keep lerp framerate independent. time_factor should be: 0 < f < 1
static func lerp_delta_decay(time_factor: float, delta: float) -> float:
	if time_factor < 0 or time_factor > 1:
		push_error("time_factor out of bounds, is: " + str(time_factor))
	return 1 - pow(time_factor, delta)
