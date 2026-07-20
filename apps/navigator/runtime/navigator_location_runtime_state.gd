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


func can_select() -> bool:
	return (
		location != null
		and should_show
		and is_available_now
	)
