extends GameEffectData
class_name GrantItemEffectData


@export var item_id: String = ""
@export_range(1, 999999, 1, "or_greater") var amount: int = 1


func _apply_effect(_context: GameEffectContext) -> bool:
	var clean_id: String = item_id.strip_edges()

	if ContentRegistry.get_item(clean_id) == null or amount <= 0:
		return false

	CampaignState.grant_item(clean_id, amount)
	return true


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_id: String = item_id.strip_edges()

	if clean_id.is_empty():
		errors.append("item_id cannot be empty.")
	elif ContentRegistry.get_item(clean_id) == null:
		errors.append("item_id '%s' is not registered." % clean_id)

	if amount <= 0:
		errors.append("amount must be greater than zero.")

	return errors
