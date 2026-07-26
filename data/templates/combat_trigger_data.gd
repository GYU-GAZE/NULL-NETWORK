extends Resource
class_name CombatTriggerData


@export var timing: CombatConstants.TriggerTiming = (
	CombatConstants.TriggerTiming.CYCLE_END
)
@export var actor_relation: CombatConstants.TriggerActor = (
	CombatConstants.TriggerActor.HOLDER
)
@export_range(-1, 3) var action_slot: int = -1
@export var action_slot_id: StringName = &""
@export var position_slot_id: StringName = &""
@export var required_module_classification: StringName = &""
@export var required_status_classification: StringName = &""
@export_flags(
	"Damage",
	"Heal",
	"Status",
	"Dummy",
	"Defense",
	"Utility"
) var required_module_tags: int = 0
@export var require_all_module_tags: bool = false


func matches(
	context: CombatEventContext,
	holder: Dictionary
) -> bool:
	if context == null or context.timing != timing:
		return false

	if action_slot >= 0 and context.action_slot != action_slot:
		return false

	if (
		not action_slot_id.is_empty()
		and context.action_slot_id != action_slot_id
	):
		return false

	if (
		not position_slot_id.is_empty()
		and context.position_slot_id != position_slot_id
	):
		return false

	if not required_module_classification.is_empty():
		if (
			context.module == null
			or context.module.classification
			!= required_module_classification
		):
			return false

	if not required_status_classification.is_empty():
		if (
			context.status == null
			or context.status.classification
			!= required_status_classification
		):
			return false

	if required_module_tags != 0:
		if context.module == null:
			return false

		var matching_tags := (
			context.module.module_tags
			& required_module_tags
		)

		if require_all_module_tags:
			if matching_tags != required_module_tags:
				return false
		elif matching_tags == 0:
			return false

	return _matches_actor_relation(context, holder)


func describe() -> String:
	var label := _timing_label()

	if action_slot >= 0:
		label += " %d" % (action_slot + 1)

	if not action_slot_id.is_empty():
		label += " in %s" % action_slot_id

	if not position_slot_id.is_empty():
		label += " from %s" % position_slot_id

	if not required_module_classification.is_empty():
		label += " for %s modules" % (
			required_module_classification
		)

	if not required_status_classification.is_empty():
		label += " for %s statuses" % (
			required_status_classification
		)

	return label


func _matches_actor_relation(
	context: CombatEventContext,
	holder: Dictionary
) -> bool:
	if actor_relation == CombatConstants.TriggerActor.ANY:
		return true

	var subject: Variant = context.source

	if context.timing in [
		CombatConstants.TriggerTiming.DAMAGE_RECEIVED,
		CombatConstants.TriggerTiming.DAMAGE_BLOCKED,
		CombatConstants.TriggerTiming.STATUS_APPLIED,
		CombatConstants.TriggerTiming.STATUS_EXPIRED,
		CombatConstants.TriggerTiming.DUMMY_CREATED,
		CombatConstants.TriggerTiming.DUMMY_DESTROYED,
		CombatConstants.TriggerTiming.DUMMY_EXPIRED
	]:
		subject = context.target

	if not (subject is Dictionary):
		return actor_relation == CombatConstants.TriggerActor.HOLDER

	var event_actor := subject as Dictionary

	match actor_relation:
		CombatConstants.TriggerActor.HOLDER:
			return event_actor.get("uid") == holder.get("uid")
		CombatConstants.TriggerActor.HOLDER_ALLY:
			return (
				event_actor.get("is_ally")
				== holder.get("is_ally")
			)
		CombatConstants.TriggerActor.HOLDER_ENEMY:
			return (
				event_actor.get("is_ally")
				!= holder.get("is_ally")
			)

	return false


func _timing_label() -> String:
	match timing:
		CombatConstants.TriggerTiming.CONTINUOUS:
			return "continuously"
		CombatConstants.TriggerTiming.ENCOUNTER_START:
			return "at encounter start"
		CombatConstants.TriggerTiming.CYCLE_START:
			return "at cycle start"
		CombatConstants.TriggerTiming.BEFORE_ACTION:
			return "before action"
		CombatConstants.TriggerTiming.AFTER_ACTION:
			return "after action"
		CombatConstants.TriggerTiming.CYCLE_END:
			return "at cycle end"
		CombatConstants.TriggerTiming.MODULE_USED:
			return "when a module is used"
		CombatConstants.TriggerTiming.DAMAGE_DEALT:
			return "when dealing damage"
		CombatConstants.TriggerTiming.DAMAGE_RECEIVED:
			return "when receiving damage"
		CombatConstants.TriggerTiming.DAMAGE_BLOCKED:
			return "when blocking damage"
		CombatConstants.TriggerTiming.STATUS_APPLIED:
			return "when a status is applied"
		CombatConstants.TriggerTiming.STATUS_EXPIRED:
			return "when a status expires"
		CombatConstants.TriggerTiming.DUMMY_CREATED:
			return "when a dummy is created"
		CombatConstants.TriggerTiming.DUMMY_DESTROYED:
			return "when a dummy is destroyed"
		CombatConstants.TriggerTiming.DUMMY_EXPIRED:
			return "when a dummy expires"

	return "on event"
