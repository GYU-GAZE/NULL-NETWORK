extends Resource
class_name CombatRewardData


@export var reward_id: String = ""
@export_range(0, 1000000, 1) var base_experience: int = 0
@export_range(1.0, 10.0, 0.05) var purge_experience_multiplier: float = 1.5
@export_range(0, 1000000, 1) var duplicate_module_experience: int = 0
@export var common_item_ids: PackedStringArray = PackedStringArray()
@export var common_item_amounts: Array[int] = []
@export var active_module_ids: PackedStringArray = PackedStringArray()
@export var purification_passive_module_ids: PackedStringArray = PackedStringArray()
@export var tame_apk_id: String = ""
@export var encyclopedia_entry_id: String = ""


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if reward_id.strip_edges().is_empty():
		errors.append("CombatRewardData has an empty reward_id.")

	if common_item_ids.size() != common_item_amounts.size():
		errors.append("Combat reward item IDs and amounts must have matching sizes.")

	for amount: int in common_item_amounts:
		if amount <= 0:
			errors.append("Combat reward item amounts must be positive.")

	return errors
