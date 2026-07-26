extends RefCounted
class_name CombatPresentationEvent


enum EventKind {
	MODULE_ACTION_STARTED,
	MODULE_EXECUTION_STARTED,
	MODULE_TARGET_RESOLVED,
	MODULE_HIT,
	MODULE_MISSED,
	MODULE_BLOCKED,
	STATUS_ACTIVATED
}


var event_kind: EventKind = EventKind.MODULE_ACTION_STARTED
var presentation: CombatPresentationData
var context: CombatEventContext
var source: Variant = null
var target: Variant = null
var module: ModuleData
var status: StatusEffectData
var triggered_effect: CombatTriggeredEffectData


static func create(
	kind: EventKind,
	event_presentation: CombatPresentationData,
	event_context: CombatEventContext,
	event_source: Variant = null,
	event_target: Variant = null,
	event_module: ModuleData = null,
	event_status: StatusEffectData = null,
	event_triggered_effect: CombatTriggeredEffectData = null
) -> CombatPresentationEvent:
	var event := CombatPresentationEvent.new()
	event.event_kind = kind
	event.presentation = event_presentation
	event.context = event_context
	event.source = event_source
	event.target = event_target
	event.module = event_module
	event.status = event_status
	event.triggered_effect = event_triggered_effect
	return event


func has_visuals() -> bool:
	return (
		presentation != null
		and presentation.has_visuals()
	)


func get_execution_index() -> int:
	return (
		context.execution_index
		if context != null
		else 0
	)


func get_execution_count() -> int:
	return (
		context.execution_count
		if context != null
		else 1
	)
