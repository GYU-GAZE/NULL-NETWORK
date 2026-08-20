@tool
extends Resource
class_name TendencyCatalogData


@export var definitions: Array[TendencyDefinitionData] = []


func get_definition(tendency_id: String) -> TendencyDefinitionData:
	var clean_id := tendency_id.strip_edges().to_lower()
	for definition: TendencyDefinitionData in definitions:
		if definition != null and definition.tendency_id.strip_edges().to_lower() == clean_id:
			return definition
	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := PackedStringArray()
	for definition: TendencyDefinitionData in definitions:
		if definition == null:
			errors.append("Tendency catalog contains a null definition.")
			continue
		errors.append_array(definition.validate_data())
		var clean_id := definition.tendency_id.strip_edges().to_lower()
		if ids.has(clean_id):
			errors.append("Tendency catalog repeats '%s'." % clean_id)
		else:
			ids.append(clean_id)
	for required_id: String in ["valour", "logic", "sync", "self"]:
		if not ids.has(required_id):
			errors.append("Tendency catalog is missing '%s'." % required_id)
	return errors
