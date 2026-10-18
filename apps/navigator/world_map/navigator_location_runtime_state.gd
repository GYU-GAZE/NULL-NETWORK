extends RefCounted
class_name NavigatorLocationRuntimeState


var location: MapLocation

var should_show: bool = false
var is_progression_unlocked: bool = false
var is_available_now: bool = false

var is_discovered: bool = false
var is_announced: bool = false
var is_new: bool = false
var needs_discovery_announcement: bool = false

var availability_message: String = ""
var activity_badge: NavigatorMarkerBadge


func can_select() -> bool:
	return location != null and should_show


func can_enter() -> bool:
	return can_select() and is_available_now and ContentRegistry.get_location(location.get_display_id()) == location and location.local_area != null and location.local_area.is_valid() and location.travel_activity != null
