class_name MathUtils extends Node


static func clamp01(number: float) -> float:
	return clampf(abs(number), 0.0, 1.0) * sign(number)
