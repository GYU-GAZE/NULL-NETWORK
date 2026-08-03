extends Resource
class_name InventoryStateData


var entries: Array[InventoryEntryData] = []

var item_counts: Dictionary:
	get:
		var result: Dictionary = {}

		for entry: InventoryEntryData in entries:
			if entry != null and entry.amount > 0:
				result[entry.item_id] = entry.amount

		return result


func reset() -> void:
	entries.clear()


func get_entry(item_id: String) -> InventoryEntryData:
	var clean_id: String = item_id.strip_edges()

	for entry: InventoryEntryData in entries:
		if entry != null and entry.item_id == clean_id:
			return entry

	return null


func get_item_count(item_id: String) -> int:
	var entry: InventoryEntryData = get_entry(item_id)
	return entry.amount if entry != null else 0


func set_item_count(item_id: String, amount: int) -> void:
	var clean_id: String = item_id.strip_edges()

	if clean_id.is_empty():
		return

	var entry: InventoryEntryData = get_entry(clean_id)

	if amount <= 0:
		if entry != null:
			entries.erase(entry)
		return

	if entry == null:
		entries.append(InventoryEntryData.create(clean_id, amount))
	else:
		entry.amount = amount


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
	var saved_entries: Array[Dictionary] = []

	for entry: InventoryEntryData in entries:
		if entry != null and not entry.item_id.is_empty() and entry.amount > 0:
			saved_entries.append(entry.to_save_data())

	return {"entries": saved_entries}


func load_save_data(data: Dictionary) -> void:
	reset()
	var saved_entries: Variant = data.get("entries", null)

	if data.has("entries") and saved_entries is Array:
		for raw_entry: Variant in saved_entries:
			if raw_entry is not Dictionary:
				continue

			var entry := InventoryEntryData.new()
			entry.load_save_data(raw_entry as Dictionary)

			if not entry.item_id.is_empty() and entry.amount > 0:
				set_item_count(entry.item_id, entry.amount)

		return

	var legacy_counts: Variant = data.get("item_counts", {})

	if legacy_counts is not Dictionary:
		return

	for raw_id: Variant in legacy_counts:
		var clean_id: String = str(raw_id).strip_edges()
		var amount: int = int(legacy_counts[raw_id])

		if not clean_id.is_empty() and amount > 0:
			set_item_count(clean_id, amount)
