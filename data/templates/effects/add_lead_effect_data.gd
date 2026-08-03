extends GameEffectData
class_name AddLeadEffectData


@export var lead_id: String = ""


func _apply_effect(_context: GameEffectContext) -> bool:
	var clean_id: String = lead_id.strip_edges()

	if ContentRegistry.get_lead(clean_id) == null:
		return false

	CampaignState.activate_lead(clean_id)
	return true


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_id: String = lead_id.strip_edges()

	if clean_id.is_empty():
		errors.append("lead_id cannot be empty.")
	elif ContentRegistry.get_lead(clean_id) == null:
		errors.append("lead_id '%s' is not registered." % clean_id)

	return errors
