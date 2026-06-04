class_name NoDrift extends DriftState

func enter_state(drift_module: DriftModule) -> bool:
	drift_module.boost_progress = 0.0
	drift_module.engine_power_modifier = 1.0
	return true
	
func tick(drift_module: DriftModule, delta: float) -> void:
	if Input.is_action_pressed("drift"):
		drift_module.switch_state(drift_module.DriftStates.DRIFTING)
	
func exit_state(drift_module: DriftModule) -> bool:
	return true
