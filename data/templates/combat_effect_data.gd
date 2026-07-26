extends Resource
class_name CombatEffectData


enum EffectType {
	DAMAGE,
	HEAL,
	MODIFY_STABILITY,
	APPLY_STATUS,
	REMOVE_STATUS,
	MODIFY_STAT,
	SPAWN_DUMMY,
	MODIFY_DAMAGE_TAKEN,
	MODIFY_DAMAGE_DEALT,
	REDIRECT_NEXT_DAMAGE,
	SET_SLOT_ENABLED,
	MOVE_ACTOR,
	ADD_ACTION_SLOT,
	MOVE_ACTION_SLOT
}


enum SpawnSlotRule {
	FIRST_EMPTY,
	LEFTMOST_EMPTY,
	RIGHTMOST_EMPTY,
	ADJACENT_LEFT,
	ADJACENT_RIGHT,
	SPECIFIC_SLOT
}


@export_category("Operation")
@export var effect_type: EffectType = EffectType.DAMAGE
@export var target_selector: CombatTargetSelector
@export var value_formula: CombatValueFormula

@export_category("Damage and Healing")
@export var defense_stat: CombatConstants.Stat = CombatConstants.Stat.DEF
@export var ignore_defense: bool = false
@export var can_crit: bool = true
@export var crit_multiplier: float = 3.0
@export var applies_unstability_on_crit: bool = true
@export_range(-1.0, 1.0, 0.01) var accuracy_override: float = -1.0

@export_category("Status")
@export var status_effect: StatusEffectData
@export var status_id_to_remove: StringName = &""
@export var remove_all_stacks: bool = true

@export_category("Stat")
@export var target_stat: CombatConstants.Stat = CombatConstants.Stat.ATK

@export_category("Dummy")
@export var dummy_data: DummyData
@export var spawn_slot_rule: SpawnSlotRule = SpawnSlotRule.FIRST_EMPTY
@export_range(0, 3) var specific_spawn_slot: int = 0

@export_category("Redirect")
@export var redirect_duration_actions: int = 1

@export_category("Runtime Slots")
@export var slot_selector: CombatSlotSelector
@export var slot_enabled: bool = false
@export var swap_occupants_when_moving: bool = true
@export_range(0, 3) var added_action_actor_index: int = 0
@export var add_action_for_caster_team: bool = true
@export var insert_action_after_selection: bool = true
@export_range(0, 15) var destination_action_order: int = 0


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if (
		target_selector == null
		and effect_type not in [
			EffectType.SPAWN_DUMMY,
			EffectType.SET_SLOT_ENABLED,
			EffectType.ADD_ACTION_SLOT,
			EffectType.MOVE_ACTION_SLOT
		]
	):
		errors.append(
			"CombatEffectData type %d has no target selector."
			% effect_type
		)

	if _requires_value_formula() and value_formula == null:
		errors.append(
			"CombatEffectData type %d has no value formula."
			% effect_type
		)

	if effect_type == EffectType.APPLY_STATUS:
		if status_effect == null:
			errors.append(
				"APPLY_STATUS effect has no StatusEffectData."
			)
		else:
			errors.append_array(status_effect.validate_data())

	if (
		effect_type == EffectType.REMOVE_STATUS
		and status_id_to_remove.is_empty()
	):
		errors.append(
			"REMOVE_STATUS effect has no status_id_to_remove."
		)

	if effect_type == EffectType.SPAWN_DUMMY:
		if dummy_data == null:
			errors.append(
				"SPAWN_DUMMY effect has no DummyData."
			)
		else:
			errors.append_array(dummy_data.validate_data())

	if effect_type in [
		EffectType.SET_SLOT_ENABLED,
		EffectType.MOVE_ACTOR,
		EffectType.MOVE_ACTION_SLOT
	]:
		if slot_selector == null:
			errors.append(
				"Slot mutation effect type %d has no "
				% effect_type
				+ "CombatSlotSelector."
			)
		else:
			errors.append_array(
				slot_selector.validate_data()
			)

	if (
		effect_type == EffectType.ADD_ACTION_SLOT
		and slot_selector != null
	):
		errors.append_array(slot_selector.validate_data())

	if (
		effect_type == EffectType.MOVE_ACTOR
		and slot_selector != null
		and slot_selector.slot_kind
		!= CombatSlotSelector.SlotKind.POSITION
	):
		errors.append(
			"MOVE_ACTOR requires a position slot selector."
		)

	if (
		effect_type in [
			EffectType.ADD_ACTION_SLOT,
			EffectType.MOVE_ACTION_SLOT
		]
		and slot_selector != null
		and slot_selector.slot_kind
		!= CombatSlotSelector.SlotKind.ACTION
	):
		errors.append(
			"Action slot mutation requires an action slot selector."
		)

	return errors


func describe() -> String:
	var target_text := (
		target_selector.describe()
		if target_selector != null
		else "team slot"
	)
	var value_text := (
		value_formula.describe()
		if value_formula != null
		else ""
	)

	match effect_type:
		EffectType.DAMAGE:
			return "Damage %s to %s" % [value_text, target_text]
		EffectType.HEAL:
			return "Heal %s on %s" % [value_text, target_text]
		EffectType.MODIFY_STABILITY:
			return "Stability %s on %s" % [value_text, target_text]
		EffectType.APPLY_STATUS:
			var status_name := (
				status_effect.display_name
				if status_effect != null
				else "status"
			)
			return "Apply %s stacks of %s to %s" % [
				value_text,
				status_name,
				target_text
			]
		EffectType.REMOVE_STATUS:
			return "Remove %s from %s" % [
				status_id_to_remove,
				target_text
			]
		EffectType.MODIFY_STAT:
			return "Modify %s by %s on %s" % [
				CombatConstants.stat_label(target_stat),
				value_text,
				target_text
			]
		EffectType.SPAWN_DUMMY:
			return "Create %s" % (
				dummy_data.display_name
				if dummy_data != null
				else "dummy"
			)
		EffectType.MODIFY_DAMAGE_TAKEN:
			return "Damage received × %s on %s" % [
				value_text,
				target_text
			]
		EffectType.MODIFY_DAMAGE_DEALT:
			return "Damage dealt × %s on %s" % [
				value_text,
				target_text
			]
		EffectType.REDIRECT_NEXT_DAMAGE:
			return "Redirect next damage from %s" % target_text
		EffectType.SET_SLOT_ENABLED:
			return "%s %s" % [
				"Enable" if slot_enabled else "Disable",
				slot_selector.describe()
					if slot_selector != null
					else "slot"
			]
		EffectType.MOVE_ACTOR:
			return "Move %s to %s" % [
				target_text,
				slot_selector.describe()
					if slot_selector != null
					else "position slot"
			]
		EffectType.ADD_ACTION_SLOT:
			return "Add action %d for the %s team" % [
				added_action_actor_index + 1,
				"caster"
					if add_action_for_caster_team
					else "opposing"
			]
		EffectType.MOVE_ACTION_SLOT:
			return "Move %s to timeline order %d" % [
				slot_selector.describe()
					if slot_selector != null
					else "action slot",
				destination_action_order + 1
			]

	return "Combat effect"


func _requires_value_formula() -> bool:
	return effect_type in [
		EffectType.DAMAGE,
		EffectType.HEAL,
		EffectType.MODIFY_STABILITY,
		EffectType.APPLY_STATUS,
		EffectType.MODIFY_STAT,
		EffectType.MODIFY_DAMAGE_TAKEN,
		EffectType.MODIFY_DAMAGE_DEALT
	]
