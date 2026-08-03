extends Resource
class_name CombatResolutionData


@export var resolution_id: String = ""
@export var player_actions: Array[PlayerActionData] = []
@export var combat_style_rule: CombatStyleRuleData
@export var escape_attempt_tendency_gains: Array[CombatTendencyGainData] = []
@export var victory_effects: Array[GameEffectData] = []
@export var defeat_effects: Array[GameEffectData] = []
@export var escape_effects: Array[GameEffectData] = []


func get_player_action(action_id: String) -> PlayerActionData:
	var clean_id: String = action_id.strip_edges()

	for action: PlayerActionData in player_actions:
		if action != null and action.action_id == clean_id:
			return action

	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var action_ids := PackedStringArray()

	if resolution_id.strip_edges().is_empty():
		errors.append("CombatResolutionData has an empty resolution_id.")

	if combat_style_rule == null:
		errors.append("Combat resolution '%s' has no Combat Style rule." % resolution_id)
	else:
		errors.append_array(combat_style_rule.validate_data())

	for gain: CombatTendencyGainData in escape_attempt_tendency_gains:
		if gain == null:
			errors.append("Combat resolution '%s' contains a null escape tendency gain." % resolution_id)
		else:
			errors.append_array(gain.validate_data())

	for action: PlayerActionData in player_actions:
		if action == null:
			errors.append("Combat resolution '%s' contains a null Player Action." % resolution_id)
			continue

		errors.append_array(action.validate_data())

		if action_ids.has(action.action_id):
			errors.append("Combat resolution '%s' repeats Player Action '%s'." % [resolution_id, action.action_id])
		else:
			action_ids.append(action.action_id)

	return errors
