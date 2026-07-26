extends Resource
class_name CombatSlotSelector


enum SlotKind {
	POSITION,
	ACTION
}


enum TeamRelation {
	CASTER_TEAM,
	OPPOSING_TEAM,
	ALLY_TEAM,
	ENEMY_TEAM,
	ANY_TEAM
}


@export var slot_kind: SlotKind = SlotKind.POSITION
@export var team_relation: TeamRelation = (
	TeamRelation.CASTER_TEAM
)
@export var slot_id: StringName = &""
@export_range(-1, 7) var slot_index: int = -1
@export var use_context_slot: bool = false
@export var include_disabled: bool = true


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if (
		not slot_id.is_empty()
		and slot_index >= 0
	):
		errors.append(
			"CombatSlotSelector cannot use slot_id and "
			+ "slot_index at the same time."
		)

	if (
		use_context_slot
		and (
			not slot_id.is_empty()
			or slot_index >= 0
		)
	):
		errors.append(
			"CombatSlotSelector using the context slot "
			+ "cannot also define a fixed slot."
		)

	return errors


func describe() -> String:
	if use_context_slot:
		return "the event slot"

	if not slot_id.is_empty():
		return "slot '%s'" % slot_id

	var team_text := _team_label()
	var kind_text := (
		"position"
		if slot_kind == SlotKind.POSITION
		else "action"
	)

	if slot_index >= 0:
		return "%s %s %d" % [
			team_text,
			kind_text,
			slot_index + 1
		]

	return "all %s %s slots" % [
		team_text,
		kind_text
	]


func _team_label() -> String:
	match team_relation:
		TeamRelation.CASTER_TEAM:
			return "caster-team"
		TeamRelation.OPPOSING_TEAM:
			return "opposing-team"
		TeamRelation.ALLY_TEAM:
			return "ally"
		TeamRelation.ENEMY_TEAM:
			return "enemy"
		TeamRelation.ANY_TEAM:
			return "matching"

	return "matching"
