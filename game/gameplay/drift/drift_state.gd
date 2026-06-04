@abstract
class_name DriftState extends RefCounted

@abstract
func enter_state(drift_module: DriftModule) -> bool

@abstract
func tick(drift_module: DriftModule, delta: float) -> void

@abstract
func exit_state(drift_module: DriftModule) -> bool
