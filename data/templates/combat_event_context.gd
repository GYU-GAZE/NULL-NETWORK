extends RefCounted
class_name CombatEventContext


var timing: CombatConstants.TriggerTiming = (
	CombatConstants.TriggerTiming.CYCLE_START
)
var cycle_index: int = 0
var action_slot: int = -1
var timeline_index: int = -1
var source: Variant = null
var target: Variant = null
var module: ModuleData
var amount: float = 0.0
var event_depth: int = 0
var event_id: int = 0


static func create(
	event_timing: CombatConstants.TriggerTiming,
	event_cycle_index: int,
	event_source: Variant = null,
	event_target: Variant = null,
	event_module: ModuleData = null,
	event_action_slot: int = -1,
	event_timeline_index: int = -1,
	event_amount: float = 0.0,
	depth: int = 0,
	id: int = 0
) -> CombatEventContext:
	var context := CombatEventContext.new()
	context.timing = event_timing
	context.cycle_index = event_cycle_index
	context.source = event_source
	context.target = event_target
	context.module = event_module
	context.action_slot = event_action_slot
	context.timeline_index = event_timeline_index
	context.amount = event_amount
	context.event_depth = depth
	context.event_id = id
	return context
