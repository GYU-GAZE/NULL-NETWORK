extends GameEffectData
class_name GrantModuleEffectData


@export var module_id: String = ""


func _apply_effect(_context: GameEffectContext) -> bool:
	var clean_id: String = module_id.strip_edges()

	if ContentRegistry.get_module(clean_id) == null:
		return false

	CampaignState.learn_module(clean_id)
	return true


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_id: String = module_id.strip_edges()

	if clean_id.is_empty():
		errors.append("module_id cannot be empty.")
	elif ContentRegistry.get_module(clean_id) == null:
		errors.append("module_id '%s' is not registered." % clean_id)

	return errors
