extends RefCounted
class_name SaveSectionRegistry


signal provider_registered(section_id: StringName)
signal provider_unregistered(section_id: StringName)


const REQUIRED_METHODS: Array[StringName] = [
	&"get_save_section_id",
	&"export_save_data",
	&"import_save_data",
	&"reset_save_data"
]

var _providers: Dictionary = {}
var _pending_sections: Dictionary = {}


func register_provider(provider: Object) -> PackedStringArray:
	var errors := validate_provider(provider)

	if not errors.is_empty():
		return errors

	var section_id := StringName(
		str(provider.call("get_save_section_id")).strip_edges()
	)

	if _providers.has(section_id) and _providers[section_id] != provider:
		errors.append(
			"Save section '%s' already has a registered provider."
			% section_id
		)
		return errors

	_providers[section_id] = provider
	provider_registered.emit(section_id)

	if _pending_sections.has(section_id):
		provider.call(
			"import_save_data",
			(_pending_sections[section_id] as Dictionary).duplicate(true)
		)
		_pending_sections.erase(section_id)

	return errors


func unregister_provider(provider: Object) -> void:
	if provider == null or not provider.has_method("get_save_section_id"):
		return

	var section_id := StringName(
		str(provider.call("get_save_section_id")).strip_edges()
	)

	if _providers.get(section_id) != provider:
		return

	var exported: Variant = provider.call("export_save_data")

	if exported is Dictionary:
		_pending_sections[section_id] = (
			exported as Dictionary
		).duplicate(true)

	_providers.erase(section_id)
	provider_unregistered.emit(section_id)


func validate_provider(provider: Object) -> PackedStringArray:
	var errors := PackedStringArray()

	if provider == null:
		errors.append("Save provider cannot be null.")
		return errors

	for method_name: StringName in REQUIRED_METHODS:
		if not provider.has_method(method_name):
			errors.append(
				"Save provider '%s' is missing %s()."
				% [provider, method_name]
			)

	if not errors.is_empty():
		return errors

	var section_id: String = str(
		provider.call("get_save_section_id")
	).strip_edges()

	if section_id.is_empty():
		errors.append("Save provider returned an empty section ID.")

	return errors


func has_provider(section_id: StringName) -> bool:
	return _providers.has(section_id)


func get_registered_section_ids() -> Array[StringName]:
	var result: Array[StringName] = []

	for raw_id: Variant in _providers.keys():
		result.append(StringName(str(raw_id)))

	result.sort()
	return result


func export_sections() -> Dictionary:
	var result: Dictionary = _pending_sections.duplicate(true)

	for section_id: StringName in get_registered_section_ids():
		var provider: Object = _providers[section_id]
		var exported: Variant = provider.call("export_save_data")

		if exported is not Dictionary:
			push_error(
				"Save provider '%s' returned a non-Dictionary value."
				% section_id
			)
			continue

		result[str(section_id)] = (exported as Dictionary).duplicate(true)

	return result


func prepare_providers_for_save() -> void:
	for section_id: StringName in get_registered_section_ids():
		var provider: Object = _providers[section_id]

		if provider.has_method("prepare_for_save"):
			provider.call("prepare_for_save")


func validate_save_readiness() -> PackedStringArray:
	var errors := PackedStringArray()

	for section_id: StringName in get_registered_section_ids():
		var provider: Object = _providers[section_id]

		if not provider.has_method("can_save_now"):
			continue

		var readiness: Variant = provider.call("can_save_now")

		if readiness is bool and not bool(readiness):
			errors.append(
				"Save section '%s' is not at a stable save boundary."
				% section_id
			)
		elif readiness is String and not str(readiness).is_empty():
			errors.append("[%s] %s" % [section_id, readiness])

	return errors


func validate_sections(sections: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	for raw_id: Variant in sections.keys():
		var section_id := StringName(str(raw_id).strip_edges())
		var section_data: Variant = sections[raw_id]

		if section_id.is_empty():
			errors.append("Save document contains an empty section ID.")
			continue

		if section_data is not Dictionary:
			errors.append(
				"Save section '%s' is not a Dictionary." % section_id
			)
			continue

		if not _providers.has(section_id):
			continue

		var provider: Object = _providers[section_id]

		if provider.has_method("validate_save_data"):
			var provider_errors: Variant = provider.call(
				"validate_save_data",
				section_data
			)

			if provider_errors is PackedStringArray:
				for provider_error: String in provider_errors:
					errors.append(
					"[%s] %s" % [section_id, provider_error]
				)

	return errors


func import_sections(
	sections: Dictionary,
	keep_unregistered_pending: bool = true
) -> PackedStringArray:
	var errors := validate_sections(sections)

	if not errors.is_empty():
		return errors

	reset_registered_providers()
	_pending_sections.clear()

	var ordered_section_ids: Array[StringName] = []

	for raw_id: Variant in sections.keys():
		ordered_section_ids.append(StringName(str(raw_id).strip_edges()))

	ordered_section_ids.sort_custom(_is_restore_section_before)

	for section_id: StringName in ordered_section_ids:
		var section_data := (
			sections.get(str(section_id), {}) as Dictionary
		).duplicate(true)

		if _providers.has(section_id):
			var provider: Object = _providers[section_id]
			provider.call("import_save_data", section_data)
		elif keep_unregistered_pending:
			_pending_sections[section_id] = section_data

	return errors


func reset_registered_providers() -> void:
	for section_id: StringName in get_registered_section_ids():
		var provider: Object = _providers[section_id]
		provider.call("reset_save_data")


func clear_pending_sections() -> void:
	_pending_sections.clear()


func get_pending_section_ids() -> Array[StringName]:
	var result: Array[StringName] = []

	for raw_id: Variant in _pending_sections.keys():
		result.append(StringName(str(raw_id)))

	result.sort()
	return result


func _is_restore_section_before(first: StringName, second: StringName) -> bool:
	var first_index: int = SaveConstants.RESTORE_SECTION_ORDER.find(first)
	var second_index: int = SaveConstants.RESTORE_SECTION_ORDER.find(second)
	first_index = first_index if first_index >= 0 else SaveConstants.RESTORE_SECTION_ORDER.size()
	second_index = second_index if second_index >= 0 else SaveConstants.RESTORE_SECTION_ORDER.size()

	if first_index != second_index:
		return first_index < second_index

	return str(first) < str(second)
