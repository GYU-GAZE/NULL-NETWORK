extends GameEffectData
class_name AddLeadEffectData


@export var lead_id: String = ""


func _apply_effect(context: GameEffectContext) -> bool:
	var clean_id: String = lead_id.strip_edges()

	if ContentRegistry.get_lead(clean_id) == null:
		return false

	var source_id: String = ""

	if context != null:
		source_id = context.source_id.strip_edges()

	return LeadIncidentManager.activate_lead(clean_id, source_id)


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()

	if lead_id.strip_edges().is_empty():
		errors.append("lead_id cannot be empty.")

	# Cross-reference validation belongs to the owning content catalog.
	# ContentRegistry builds proposed indexes only after Resource validation,
	# so checking the live registry here would reject valid new catalogs.
	return errors
