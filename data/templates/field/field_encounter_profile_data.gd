@tool
extends Resource
class_name FieldEncounterProfileData

enum AggroPolicy { FORCED_FREE, OFFER_VOLUNTARY, DISABLED }
@export var profile_id: String = ""
@export var voluntary_activity: ActivityDefinitionData
@export var forced_activity: ActivityDefinitionData
@export var aggro_policy: AggroPolicy = AggroPolicy.FORCED_FREE
@export var resolution: CombatResolutionData
@export var reward_profile: CombatRewardData
@export_range(0.0, 1000.0) var call_radius: float = 180.0
@export_range(0.0, 3.0) var signal_seconds: float = 0.45
@export_range(0.0, 1.0) var base_escape_chance: float = 0.45
@export var can_escape: bool = true

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id.is_empty() or resolution == null:
		errors.append("Field encounter requires identity and a CombatResolutionData.")
	elif not Engine.is_editor_hint():
		errors.append_array(resolution.validate_data())
	if voluntary_activity == null or voluntary_activity.action_cost != 1 or not voluntary_activity.commit_time_on_completion:
		errors.append("Independent field combat must reserve exactly one action block.")
	if aggro_policy == AggroPolicy.FORCED_FREE and (forced_activity == null or forced_activity.action_cost != 0 or forced_activity.requires_confirmation):
		errors.append("Forced aggro requires an explicit free, non-confirmed activity.")
	if reward_profile != null and not Engine.is_editor_hint():
		errors.append_array(reward_profile.validate_data())
	return errors
