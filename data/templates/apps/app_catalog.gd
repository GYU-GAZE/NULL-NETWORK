extends Resource
class_name AppCatalog


@export var apps: Array[AppResource] = []


func get_app(app_id: String) -> AppResource:
	var clean_id: String = app_id.strip_edges()

	if clean_id.is_empty():
		return null

	for app: AppResource in apps:
		if app != null and app.app_id.strip_edges() == clean_id:
			return app

	return null


func get_ordered_apps() -> Array[AppResource]:
	var result: Array[AppResource] = []

	for app: AppResource in apps:
		if app != null:
			result.append(app)

	result.sort_custom(_sort_apps)
	return result


func get_default_app_ids() -> PackedStringArray:
	var result := PackedStringArray()

	for app: AppResource in get_ordered_apps():
		if app.installed_by_default:
			result.append(app.app_id.strip_edges())

	return result


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}

	for index: int in range(apps.size()):
		var app: AppResource = apps[index]

		if app == null:
			errors.append("App %d is null." % index)
			continue

		var clean_id: String = app.app_id.strip_edges()

		if not clean_id.is_empty() and seen_ids.has(clean_id):
			errors.append("Duplicate app_id '%s'." % clean_id)
		else:
			seen_ids[clean_id] = true

		for error: String in app.validate_data():
			errors.append("App %d: %s" % [index, error])

	return errors


func _sort_apps(first: AppResource, second: AppResource) -> bool:
	if first.sort_order == second.sort_order:
		return first.app_id.naturalnocasecmp_to(second.app_id) < 0

	return first.sort_order < second.sort_order
