extends Resource
class_name EvolutionBranchData


@export var branch_id: String = ""
@export var target_apk_id: String = ""
@export var combat_only: bool = true
@export var core_requirements: Array[CoreRequirementData] = []
@export var evolution_catalysts: Array[EvolutionCatalystData] = []
@export var windows: Array[EvolutionWindowData] = []
@export var prompt_player: bool = true
@export var forced_if_valid: bool = false
@export var once_per_battle: bool = true


func is_valid(partner: PartnerStateData, log: CombatTendencyLog) -> bool:
	if partner == null or log == null or target_apk_id.strip_edges().is_empty():
		return false

	for requirement: CoreRequirementData in core_requirements:
		if requirement == null or not requirement.is_met(partner, log):
			return false

	if evolution_catalysts.is_empty():
		return false

	for catalyst: EvolutionCatalystData in evolution_catalysts:
		if catalyst != null and catalyst.is_met(log):
			return true

	return false


func supports_window(kind: EvolutionWindowData.WindowKind) -> bool:
	if windows.is_empty():
		return kind == EvolutionWindowData.WindowKind.END_OF_CYCLE

	for window: EvolutionWindowData in windows:
		if window != null and window.window_kind == kind:
			return true

	return false


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if branch_id.strip_edges().is_empty():
		errors.append("EvolutionBranchData has an empty branch_id.")

	if target_apk_id.strip_edges().is_empty():
		errors.append("Evolution branch '%s' has no target APK." % branch_id)

	if core_requirements.is_empty():
		errors.append("Evolution branch '%s' has no Core Requirements." % branch_id)

	if evolution_catalysts.is_empty():
		errors.append("Evolution branch '%s' has no Catalysts." % branch_id)

	for requirement: CoreRequirementData in core_requirements:
		if requirement == null:
			errors.append("Evolution branch '%s' contains a null Core Requirement." % branch_id)
		else:
			errors.append_array(requirement.validate_data())

	for catalyst: EvolutionCatalystData in evolution_catalysts:
		if catalyst == null:
			errors.append("Evolution branch '%s' contains a null Catalyst." % branch_id)
		else:
			errors.append_array(catalyst.validate_data())

	for window: EvolutionWindowData in windows:
		if window == null:
			errors.append("Evolution branch '%s' contains a null window." % branch_id)
		else:
			errors.append_array(window.validate_data())

	return errors
