class_name Drifting extends DriftState

func enter_state(drift_module: DriftModule) -> bool:
	drift_module.steering_limit_modifier = drift_module.drift_steering_modifier
	return true

func tick(drift_module: DriftModule, delta: float) -> void:
	if drift_module.boost_progress > drift_module.overboost:
		drift_module.switch_state(drift_module.DriftStates.OVERDRIFT)
		return
		
	if !Input.is_action_just_released("drift"):
		drift_module.boost_progress += drift_module.boost_progress_per_frame
		drift_module.engine_power_modifier = lerp(
						drift_module.engine_power_modifier, 0.5, 
						drift_module.boost_progress/drift_module.ideal_boost_progress
						)
		return
		
	if drift_module.boost_progress < drift_module.min_boost_progress:
		drift_module.switch_state(drift_module.DriftStates.NO_DRIFT)
	else:
		drift_module.switch_state(drift_module.DriftStates.BOOSTING)

	
func exit_state(drift_module: DriftModule) -> bool:
	drift_module.steering_limit_modifier = 1
	return true
