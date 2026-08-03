extends Resource
class_name AppearanceData


@export_category("Body and Face")
@export var body_type_id: String = ""
@export var face_id: String = ""
@export var eye_id: String = ""

@export_category("Clothing Layers")
@export var outer_layer_id: String = ""
@export var middle_layer_id: String = ""
@export var lower_layer_id: String = ""

@export_category("Accessories")
@export var hat_id: String = ""
@export var facial_accessory_id: String = ""


func get_appearance_part_ids() -> PackedStringArray:
	var result := PackedStringArray()

	for part_id: String in [
		body_type_id,
		face_id,
		eye_id,
		outer_layer_id,
		middle_layer_id,
		lower_layer_id,
		hat_id,
		facial_accessory_id
	]:
		var clean_id: String = part_id.strip_edges()

		if not clean_id.is_empty():
			result.append(clean_id)

	return result


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if body_type_id.strip_edges().is_empty():
		errors.append("Body type is required.")

	if face_id.strip_edges().is_empty():
		errors.append("Face is required.")

	if eye_id.strip_edges().is_empty():
		errors.append("Eyes are required.")

	if outer_layer_id.strip_edges().is_empty():
		errors.append("Outer clothing layer is required.")

	if middle_layer_id.strip_edges().is_empty():
		errors.append("Middle clothing layer is required.")

	if lower_layer_id.strip_edges().is_empty():
		errors.append("Lower clothing layer is required.")

	return errors


func to_save_data() -> Dictionary:
	return {
		"body_type_id": body_type_id.strip_edges(),
		"face_id": face_id.strip_edges(),
		"eye_id": eye_id.strip_edges(),
		"outer_layer_id": outer_layer_id.strip_edges(),
		"middle_layer_id": middle_layer_id.strip_edges(),
		"lower_layer_id": lower_layer_id.strip_edges(),
		"hat_id": hat_id.strip_edges(),
		"facial_accessory_id": facial_accessory_id.strip_edges(),
		"appearance_part_ids": Array(get_appearance_part_ids())
	}


func load_save_data(data: Dictionary) -> void:
	body_type_id = str(data.get("body_type_id", "")).strip_edges()
	face_id = str(data.get("face_id", "")).strip_edges()
	eye_id = str(data.get("eye_id", "")).strip_edges()
	outer_layer_id = str(data.get("outer_layer_id", "")).strip_edges()
	middle_layer_id = str(data.get("middle_layer_id", "")).strip_edges()
	lower_layer_id = str(data.get("lower_layer_id", "")).strip_edges()
	hat_id = str(data.get("hat_id", "")).strip_edges()
	facial_accessory_id = str(
		data.get("facial_accessory_id", "")
	).strip_edges()

	if body_type_id.is_empty():
		_load_legacy_part_ids(data.get("appearance_part_ids", []))


func duplicate_state() -> AppearanceData:
	var result := AppearanceData.new()
	result.load_save_data(to_save_data())
	return result


func _load_legacy_part_ids(value: Variant) -> void:
	if value is not Array and value is not PackedStringArray:
		return

	var part_ids: Array[String] = []

	for raw_id: Variant in value:
		part_ids.append(str(raw_id).strip_edges())

	if part_ids.size() > 0:
		body_type_id = part_ids[0]
	if part_ids.size() > 1:
		face_id = part_ids[1]
	if part_ids.size() > 2:
		eye_id = part_ids[2]
	if part_ids.size() > 3:
		outer_layer_id = part_ids[3]
	if part_ids.size() > 4:
		middle_layer_id = part_ids[4]
	if part_ids.size() > 5:
		lower_layer_id = part_ids[5]
	if part_ids.size() > 6:
		hat_id = part_ids[6]
	if part_ids.size() > 7:
		facial_accessory_id = part_ids[7]
