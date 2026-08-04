extends GameEffectData
class_name DiscoverLocationEffectData


@export var location_id: String = ""


func _apply_effect(_context: GameEffectContext) -> bool:
	return LocationDiscoveryService.discover(location_id)


func _validate_effect() -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty():
		errors.append("location_id cannot be empty.")
	elif ContentRegistry.catalog != null \
		and ContentRegistry.get_location(clean_id) == null:
		errors.append("location_id '%s' is not registered." % clean_id)

	return errors
