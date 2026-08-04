extends RefCounted
class_name NavigatorLocationStateResolver


const FLAG_PREFIX: String = "navigator.location"


static func resolve(
	location: MapLocation
) -> NavigatorLocationRuntimeState:
	var state := NavigatorLocationRuntimeState.new()
	state.location = location

	if location == null:
		return state

	if not location.show_on_world_map:
		return state

	state.activity_badge = LeadIncidentManager.get_navigator_badge(
		location.get_display_id()
	)

	if state.activity_badge == null:
		state.activity_badge = location.activity_badge

	state.is_progression_unlocked = (
		_is_progression_unlocked(location)
	)

	var period_available: bool = (
		_is_current_period_allowed(location)
	)

	state.is_available_now = (
		state.is_progression_unlocked
		and period_available
	)

	state.should_show = (
		state.is_progression_unlocked
		or location.show_when_locked
	)

	var location_id: String = location.get_display_id()
	state.is_discovered = (
		CampaignState.discovered_location_ids.has(location_id)
		or GameState.get_flag(
			get_discovered_flag(location),
			false
		)
	)

	state.is_announced = GameState.get_flag(
		get_announced_flag(location),
		false
	)

	var was_viewed: bool = GameState.get_flag(
		get_viewed_flag(location),
		false
	)

	state.is_new = (
		state.is_discovered
		and not was_viewed
	)

	state.needs_discovery_announcement = (
		state.is_discovered
		and not state.is_announced
	)

	if not state.is_progression_unlocked:
		state.availability_message = "LOCKED"
	elif not period_available:
		state.availability_message = (
			_get_period_message(location)
		)

	return state


static func discover(location: MapLocation) -> void:
	if location == null:
		return

	var location_id: String = location.get_display_id()

	if not location_id.is_empty():
		CampaignState.discover_location(location_id)

	var flag_name: String = get_discovered_flag(location)

	if not GameState.get_flag(flag_name, false):
		GameState.set_flag(flag_name, true)


static func mark_announced(location: MapLocation) -> void:
	if location == null:
		return

	var flag_name: String = get_announced_flag(location)

	if GameState.get_flag(flag_name, false):
		return

	GameState.set_flag(flag_name, true)


static func mark_viewed(location: MapLocation) -> void:
	if location == null:
		return

	discover(location)
	mark_announced(location)

	var viewed_flag: String = get_viewed_flag(location)

	if not GameState.get_flag(viewed_flag, false):
		GameState.set_flag(viewed_flag, true)


static func get_discovered_flag(
	location: MapLocation
) -> String:
	return "%s.%s.discovered" % [
		FLAG_PREFIX,
		location.get_display_id()
	]


static func get_announced_flag(
	location: MapLocation
) -> String:
	return "%s.%s.announced" % [
		FLAG_PREFIX,
		location.get_display_id()
	]


static func get_viewed_flag(
	location: MapLocation
) -> String:
	return "%s.%s.viewed" % [
		FLAG_PREFIX,
		location.get_display_id()
	]


static func _is_progression_unlocked(
	location: MapLocation
) -> bool:
	if CampaignState.discovered_location_ids.has(
		location.get_display_id()
	):
		return true

	if location.unlocked_by_default:
		return true

	var has_valid_flag: bool = false

	for required_flag in location.required_flags:
		var clean_flag: String = (
			required_flag.strip_edges()
		)

		if clean_flag.is_empty():
			continue

		has_valid_flag = true

		if not GameState.get_flag(clean_flag, false):
			return false

	return has_valid_flag


static func _is_current_period_allowed(
	location: MapLocation
) -> bool:
	if location.required_time_periods.is_empty():
		return true

	var current_period: String = (
		TimeManager
		.get_current_period_name()
		.to_upper()
	)

	for required_period in location.required_time_periods:
		var clean_period: String = (
			required_period
			.strip_edges()
			.to_upper()
		)

		if clean_period == current_period:
			return true

	return false


static func _get_period_message(
	location: MapLocation
) -> String:
	var periods := PackedStringArray()

	for required_period in location.required_time_periods:
		var clean_period: String = (
			required_period
			.strip_edges()
			.to_upper()
		)

		if clean_period.is_empty():
			continue

		if not periods.has(clean_period):
			periods.append(clean_period)

	if periods.is_empty():
		return ""

	return "AVAILABLE: %s" % " / ".join(periods)
