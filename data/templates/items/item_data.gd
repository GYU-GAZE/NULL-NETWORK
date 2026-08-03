extends Resource
class_name ItemData


enum ItemType {
	CONSUMABLE,
	MATERIAL,
	KEY_ITEM
}

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export_range(1, 9999, 1) var max_stack: int = 99
@export var tradable: bool = true
@export var icon: Texture2D


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if item_id.strip_edges().is_empty():
		errors.append("ItemData has an empty item_id.")

	if display_name.strip_edges().is_empty():
		errors.append("Item '%s' has no display name." % item_id)

	if item_type == ItemType.KEY_ITEM and max_stack != 1:
		errors.append("Key item '%s' must have max_stack 1." % item_id)

	return errors
