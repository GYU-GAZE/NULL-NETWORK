extends Resource
class_name CoreRequirementData


@export_range(1, 100, 1) var min_level: int = 1
@export var required_current_apk_id: String = ""
@export var required_global_tendency: TendencyStateData.Tendency = TendencyStateData.Tendency.VALOUR
@export_range(0, 1000000, 1) var min_global_tendency: int = 0
@export var require_global_dominance: bool = false
@export_range(0, 1000000, 1) var global_dominance_margin: int = 0
@export var required_projected_dominant_tendency: TendencyStateData.Tendency = TendencyStateData.Tendency.VALOUR
@export var require_projected_dominance: bool = false
@export_range(0, 1000000, 1) var dominance_margin: int = 0
@export var required_flags: PackedStringArray = PackedStringArray()
@export var forbidden_flags: PackedStringArray = PackedStringArray()


func is_met(partner: PartnerStateData, log: CombatTendencyLog) -> bool:
	if partner == null or log == null or partner.level < min_level:
		return false

	if not required_current_apk_id.strip_edges().is_empty() \
		and partner.apk_id != required_current_apk_id:
		return false

	if CampaignState.tendencies.get_value(required_global_tendency) < min_global_tendency:
		return false

	if require_global_dominance:
		var global_value: int = CampaignState.tendencies.get_value(required_global_tendency)

		for raw_tendency: int in TendencyStateData.Tendency.values():
			if raw_tendency == required_global_tendency:
				continue

			if global_value - CampaignState.tendencies.get_value(raw_tendency) < global_dominance_margin:
				return false

	if require_projected_dominance:
		var required_value: int = log.get_projected_tendency(required_projected_dominant_tendency)

		for raw_tendency: int in TendencyStateData.Tendency.values():
			if raw_tendency == required_projected_dominant_tendency:
				continue

			if required_value - log.get_projected_tendency(raw_tendency) < dominance_margin:
				return false

	for flag_id: String in required_flags:
		if not GameState.get_flag(flag_id):
			return false

	for flag_id: String in forbidden_flags:
		if GameState.get_flag(flag_id):
			return false

	return true


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if required_current_apk_id.strip_edges().is_empty():
		errors.append("Evolution Core Requirement has no source APK ID.")

	return errors
