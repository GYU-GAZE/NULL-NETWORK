extends Resource
class_name InventoryEntryData


var item_id: String = ""
var amount: int = 0


static func create(new_item_id: String, new_amount: int) -> InventoryEntryData:
	var entry := InventoryEntryData.new()
	entry.item_id = new_item_id.strip_edges()
	entry.amount = maxi(0, new_amount)
	return entry


func to_save_data() -> Dictionary:
	return {"item_id": item_id, "amount": amount}


func load_save_data(data: Dictionary) -> void:
	item_id = str(data.get("item_id", "")).strip_edges()
	amount = maxi(0, int(data.get("amount", 0)))
