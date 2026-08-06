extends Resource
class_name CombatResolutionData


enum PartnerLossPolicy {
	RECOVERABLE,
	DEFINITIVE_ON_DEFEAT,
	DEFINITIVE_AT_ZERO_HP
}

@export var resolution_id: String = ""
@export_category("Commitment")
## RECOVERABLE keeps the partner at zero HP for another system to recover.
## DEFINITIVE_ON_DEFEAT resolves Partner Loss only when the encounter ends in defeat.
## DEFINITIVE_AT_ZERO_HP resolves Partner Loss whenever the partner reached zero,
## including mutual collapse or a victory completed by surviving party members.
@export var partner_loss_policy: PartnerLossPolicy = PartnerLossPolicy.RECOVERABLE
@export_range(0, 100, 1) var partner_loss_infestation_increase: int = 1
@export_range(0, 100, 1) var operator_loss_infestation_increase: int = 3
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


func should_resolve_partner_loss(
	outcome: CombatResult.Outcome,
	partner_hp: float
) -> bool:
	if partner_hp > 0.0:
		return false

	match partner_loss_policy:
		PartnerLossPolicy.RECOVERABLE:
			return false
		PartnerLossPolicy.DEFINITIVE_ON_DEFEAT:
			return outcome == CombatResult.Outcome.DEFEAT
		PartnerLossPolicy.DEFINITIVE_AT_ZERO_HP:
			return true

	return false


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var action_ids := PackedStringArray()

	if resolution_id.strip_edges().is_empty():
		errors.append("CombatResolutionData has an empty resolution_id.")

	if partner_loss_policy < PartnerLossPolicy.RECOVERABLE \
		or partner_loss_policy > PartnerLossPolicy.DEFINITIVE_AT_ZERO_HP:
		errors.append("Combat resolution has an invalid Partner Loss policy.")

	if partner_loss_infestation_increase < 0:
		errors.append("Partner Loss infestation increase cannot be negative.")

	if operator_loss_infestation_increase < partner_loss_infestation_increase:
		errors.append(
			"Operator Loss infestation increase cannot be lower than Partner Loss."
		)

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
