extends Resource
class_name DialoguePortraitState


enum Side {
	LEFT,
	RIGHT
}

const SLOTS_PER_SIDE: int = 3

@export_category("Placement")
@export var side: Side = Side.LEFT
@export_range(0, SLOTS_PER_SIDE - 1, 1) var slot_index: int = 0

@export_category("Presentation")
@export var speaker_id: String = ""
@export var portrait: Texture2D
@export var visible: bool = true
@export var active: bool = true
@export var flip_h: bool = false


func get_slot_key() -> String:
	return "%d:%d" % [int(side), slot_index]


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if slot_index < 0 or slot_index >= SLOTS_PER_SIDE:
		errors.append("slot_index must be between 0 and 2.")

	if speaker_id.strip_edges().is_empty():
		errors.append("speaker_id cannot be empty.")

	if visible and portrait == null:
		errors.append("A visible portrait state requires a Texture2D.")

	return errors
