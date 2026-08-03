extends GameEffectData
class_name UnlockAppEffectData


@export var app_id: String = ""


func _apply_effect(context: GameEffectContext) -> bool:
	var clean_id: String = app_id.strip_edges()

	if ContentRegistry.get_app(clean_id) == null:
		return false

	return AppInstallationManager.install_app(clean_id, context)


func _validate_effect() -> PackedStringArray:
	return _validate_registered_id(
		ContentRegistry.CATEGORY_APPS,
		app_id,
		"app_id"
	)


func _validate_registered_id(
	category: StringName,
	content_id: String,
	field_name: String
) -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_id: String = content_id.strip_edges()

	if clean_id.is_empty():
		errors.append("%s cannot be empty." % field_name)
	elif not ContentRegistry.has(category, clean_id):
		errors.append("%s '%s' is not registered." % [field_name, clean_id])

	return errors
