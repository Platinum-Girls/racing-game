class_name Overdrift extends DriftState

const ticks_of_stall: int = 100
var cur_ticks: int = 0

func enter_state(drift_module: DriftModule) -> bool:
	drift_module.engine_power_modifier = 0.0
	return true
	
func tick(drift_module: DriftModule, delta: float) -> void:
	cur_ticks += 1
	if cur_ticks < ticks_of_stall:
		return
	drift_module.engine_power_modifier = (drift_module.overboost - drift_module.boost_progress) / drift_module.overboost
	drift_module.boost_progress -= drift_module.boost_progress_per_frame
	if is_zero_approx(drift_module.boost_progress):
		drift_module.switch_state(drift_module.DriftStates.NO_DRIFT)
	
func exit_state(drift_module: DriftModule) -> bool:
	drift_module.engine_power_modifier = 1.0
	cur_ticks = 0
	return true
