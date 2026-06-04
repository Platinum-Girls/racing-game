class_name Boosting extends DriftState

const ticks_of_full: int = 50
var cur_ticks: int = 0

func enter_state(drift_module: DriftModule) -> bool:
	drift_module.engine_power_modifier = (drift_module.boost_progress/drift_module.min_boost_progress)*drift_module.boost_power_modifier
	drift_module.steering_limit_modifier = drift_module.boost_steering_modifier
	return true
	
func tick(drift_module: DriftModule, delta: float) -> void:
	cur_ticks += 1
	if cur_ticks < ticks_of_full:
		return
	if is_zero_approx(drift_module.boost_progress):
		drift_module.switch_state(drift_module.DriftStates.NO_DRIFT)
		return
	drift_module.engine_power_modifier = lerp(drift_module.engine_power_modifier, 1.0, drift_module.boost_progress / drift_module.ideal_boost_progress)
	drift_module.boost_progress -= drift_module.boost_progress_per_frame
	
func exit_state(drift_module: DriftModule) -> bool:
	drift_module.engine_power_modifier = 1.0
	drift_module.boost_progress = 0.0
	drift_module.steering_limit_modifier = 1.0
	cur_ticks = 0
	return true
