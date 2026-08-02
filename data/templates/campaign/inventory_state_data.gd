extends Resource
class_name InventoryStateData


var item_counts: Dictionary = {}


func reset() -> void:
	item_counts.clear()


func get_item_count(item_id: String) -> int:
	var clean_id: String = item_id.strip_edges()

	if clean_id.is_empty():
		return 0

	return int(item_counts.get(clean_id, 0))


func set_item_count(item_id: String, amount: int) -> void:
	var clean_id: String = item_id.strip_edges()

	if clean_id.is_empty():
		return

	if amount <= 0:
		item_counts.erase(clean_id)
		return

	item_counts[clean_id] = amount


func add_item(item_id: String, amount: int = 1) -> int:
	if amount == 0:
		return get_item_count(item_id)

	var new_amount: int = get_item_count(item_id) + amount
	set_item_count(item_id, new_amount)
	return get_item_count(item_id)


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var current_amount: int = get_item_count(item_id)

	if current_amount < amount:
		return false

	set_item_count(item_id, current_amount - amount)
	return true


func to_save_data() -> Dictionary:
	return {
		"item_counts": item_counts.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	var saved_counts: Variant = data.get("item_counts", {})

	if saved_counts is not Dictionary:
		return

	for raw_id: Variant in saved_counts:
		var clean_id: String = str(raw_id).strip_edges()
		var amount: int = int(saved_counts[raw_id])

		if not clean_id.is_empty() and amount > 0:
			item_counts[clean_id] = amount
