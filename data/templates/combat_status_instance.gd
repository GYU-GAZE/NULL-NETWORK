extends RefCounted
class_name CombatStatusInstance


var data: StatusEffectData
var stacks: int = 1
var remaining_cycles: int = -1
var source_uid: int = -1
var applied_cycle: int = 0
var last_triggered_cycle: Dictionary = {}
var expiring: bool = false


static func create(
	status_data: StatusEffectData,
	initial_stacks: int,
	source_actor_uid: int,
	current_cycle: int
) -> CombatStatusInstance:
	var instance := CombatStatusInstance.new()
	instance.data = status_data
	instance.stacks = clampi(
		initial_stacks,
		1,
		maxi(1, status_data.max_stacks)
	)
	instance.remaining_cycles = status_data.duration_cycles
	instance.source_uid = source_actor_uid
	instance.applied_cycle = current_cycle
	return instance
