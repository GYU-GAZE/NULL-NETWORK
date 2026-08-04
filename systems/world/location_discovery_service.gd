extends RefCounted
class_name LocationDiscoveryService


const LEGACY_FLAG_PREFIX: String = "navigator.location"


static func discover(location_id: String) -> bool:
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty() or ContentRegistry.get_location(clean_id) == null:
		return false

	var changed: bool = CampaignState.discover_location(clean_id)
	var legacy_flag: String = get_legacy_discovered_flag(clean_id)

	if not GameState.get_flag(legacy_flag, false):
		GameState.set_flag(legacy_flag, true)
		changed = true

	return changed or is_discovered(clean_id)


static func is_discovered(location_id: String) -> bool:
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty():
		return false

	return (
		CampaignState.discovered_location_ids.has(clean_id)
		or GameState.get_flag(
			get_legacy_discovered_flag(clean_id),
			false
		)
	)


static func get_legacy_discovered_flag(location_id: String) -> String:
	return "%s.%s.discovered" % [
		LEGACY_FLAG_PREFIX,
		location_id.strip_edges()
	]
