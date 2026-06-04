class_name DriftModule extends Node

enum DriftStates {
	NO_DRIFT = 0, DRIFTING = 1, BOOSTING = 2, OVERDRIFT = 3
}

var states : Array[DriftState] = [NoDrift.new(), Drifting.new(), Boosting.new(), Overdrift.new()]

@export var boost_progress_per_frame: float = .5
@export var min_boost_progress: float = 30.0
@export var ideal_boost_progress: float = 60.0
@export var overboost: float = 75.0

const boost_power_modifier: float = 5.0
const drift_steering_modifier: float = 1.5
const boost_steering_modifier: float = 0.75

var cur_state: DriftStates = DriftStates.NO_DRIFT
var boost_progress: float = 0.0
var engine_power_modifier: float = 1.0
var steering_limit_modifier: float = 1.0

func _ready() -> void:
	states[cur_state].enter_state(self)

func switch_state(to_state: DriftStates) -> void:
	if !states[cur_state].exit_state(self):
		return
	if states[to_state].enter_state(self):
		cur_state = to_state

###TODO: Rename
func drift(delta: float) -> void:
	states[cur_state].tick(self, delta)
