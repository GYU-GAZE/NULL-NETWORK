extends GameEffectData
class_name SelectStarterEffectData


@export var starter_apk_id: String = ""
@export var nickname: String = ""
@export var personality_roll: int = -1
@export var address_term_roll: int = -1
@export var skip_if_partner_exists: bool = true


func _apply_effect(_context: GameEffectContext) -> bool:
	var clean_apk_id: String = starter_apk_id.strip_edges()

	if clean_apk_id.is_empty():
		return false

	if not CampaignState.partner.is_empty():
		return skip_if_partner_exists

	return APKProgressionService.select_starter(
		clean_apk_id,
		nickname,
		personality_roll,
		address_term_roll
	).is_empty()


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_apk_id: String = starter_apk_id.strip_edges()

	if clean_apk_id.is_empty():
		errors.append("starter_apk_id cannot be empty.")
	elif ContentRegistry.get_apk(clean_apk_id) == null:
		errors.append("starter_apk_id '%s' is not registered." % clean_apk_id)

	return errors
