extends Resource
class_name APKData

enum FormType {
	INIT,
	BALANCED,
	VALOUR,
	LOGIC,
	SYNC,
	SELF,
	NULL,
	XVALOUR,
	XLOGIC,
	XSYNC,
	XSELF
}

@export_category("Identity")
@export var apk_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var species_line_id: String = ""
@export var form_id: String = ""
@export var form_type: FormType = FormType.INIT

@export_category("Starter Selection")
@export var selectable_as_starter: bool = false
@export_range(0, 100000, 1) var starter_sort_order: int = 0

@export_category("Presentation")
@export var sprites: Array[Texture2D] = []
@export var portraits: Array[Texture2D] = []
@export var combat_icon: Texture2D

@export_category("Natural Growth")
@export var level_100_stats: APKGrowthProfileData
@export_range(0, 100, 1) var stability_recovery: int = 20
@export_range(0.0, 1.0, 0.01) var dodge_chance: float = 0.05
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.05

@export_category("Individualization")
@export var available_personalities: Array[APKPersonalityData] = []
@export var available_address_terms: Array[AddressTermData] = []

@export_category("Modules")
@export var default_active_modules: Array[ModuleData] = []
@export var signature_passive: ModuleData
@export var learnable_modules: Array[APKLevelRewardData] = []

@export_category("Evolution")
@export var evolution_branches: Array[EvolutionBranchData] = []

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if apk_id.strip_edges().is_empty():
		errors.append("APKData has an empty apk_id.")
	if display_name.strip_edges().is_empty():
		errors.append("APK '%s' has no display name." % apk_id)
	if species_line_id.strip_edges().is_empty():
		errors.append("APK '%s' has no species_line_id." % apk_id)
	if form_id.strip_edges().is_empty():
		errors.append("APK '%s' has no form_id." % apk_id)
	if selectable_as_starter and form_type != FormType.INIT:
		errors.append("Selectable starter APK '%s' must use its INIT form." % apk_id)
	if level_100_stats == null:
		errors.append("APK '%s' has no level-100 growth profile." % apk_id)
	else:
		errors.append_array(level_100_stats.validate_data())
	if available_personalities.is_empty() or available_personalities.size() > 3:
		errors.append("APK '%s' must expose between one and three personalities." % apk_id)
	if available_address_terms.is_empty():
		errors.append("APK '%s' requires at least one address term." % apk_id)
	if default_active_modules.size() != 4:
		errors.append("APK '%s' must equip exactly four default active Modules." % apk_id)
	var personality_ids := PackedStringArray()
	for personality: APKPersonalityData in available_personalities:
		if personality == null:
			errors.append("APK '%s' contains a null personality." % apk_id)
			continue
		errors.append_array(personality.validate_data())
		var clean_id: String = personality.personality_id.strip_edges()
		if personality_ids.has(clean_id):
			errors.append("APK '%s' repeats personality '%s'." % [apk_id, clean_id])
		else:
			personality_ids.append(clean_id)
	var address_ids := PackedStringArray()
	for term: AddressTermData in available_address_terms:
		if term == null:
			errors.append("APK '%s' contains a null address term." % apk_id)
			continue
		errors.append_array(term.validate_data())
		var clean_id: String = term.address_term_id.strip_edges()
		if address_ids.has(clean_id):
			errors.append("APK '%s' repeats address term '%s'." % [apk_id, clean_id])
		else:
			address_ids.append(clean_id)
	for module: ModuleData in default_active_modules:
		if module == null:
			errors.append("APK '%s' has an empty default Module slot." % apk_id)
	for reward: APKLevelRewardData in learnable_modules:
		if reward == null:
			errors.append("APK '%s' contains a null level reward." % apk_id)
		else:
			errors.append_array(reward.validate_data())
	for branch: EvolutionBranchData in evolution_branches:
		if branch == null:
			errors.append("APK '%s' contains a null evolution branch." % apk_id)
		else:
			errors.append_array(branch.validate_data())
	return errors

func is_final_form() -> bool:
	return form_type in [FormType.NULL, FormType.XVALOUR, FormType.XLOGIC, FormType.XSYNC, FormType.XSELF]

func get_personality(personality_id: String) -> APKPersonalityData:
	var clean_id: String = personality_id.strip_edges()
	for personality: APKPersonalityData in available_personalities:
		if personality != null and personality.personality_id == clean_id:
			return personality
	return null

func get_address_term(address_term_id: String) -> AddressTermData:
	var clean_id: String = address_term_id.strip_edges()
	for term: AddressTermData in available_address_terms:
		if term != null and term.address_term_id == clean_id:
			return term
	return null
