extends Resource
class_name AppearanceCatalogData

@export var options: Array[AppearanceOptionData] = []

func get_options(category: int) -> Array[AppearanceOptionData]:
	var result: Array[AppearanceOptionData] = []
	for option_value in options:
		var option := option_value as AppearanceOptionData
		if option != null and option.category == category:
			result.append(option)
	return result

func get_option(option_id: String) -> AppearanceOptionData:
	var clean_id := option_id.strip_edges()
	for option_value in options:
		var option := option_value as AppearanceOptionData
		if option != null and option.option_id == clean_id:
			return option
	return null

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := PackedStringArray()
	for option_value in options:
		var option := option_value as AppearanceOptionData
		if option == null:
			errors.append("Appearance catalog contains a null option.")
			continue
		errors.append_array(option.validate_data())
		if ids.has(option.option_id):
			errors.append("Appearance catalog repeats option '%s'." % option.option_id)
		else:
			ids.append(option.option_id)
	for category_value in AppearanceOptionData.Category.values():
		var category := int(category_value)
		if get_options(category).is_empty() and category not in [
			AppearanceOptionData.Category.HAT,
			AppearanceOptionData.Category.FACIAL_ACCESSORY
		]:
			errors.append(
				"Appearance catalog has no required option for category %s."
				% AppearanceOptionData.Category.keys()[category]
			)
	return errors
