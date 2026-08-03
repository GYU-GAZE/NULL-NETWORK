extends RefCounted
class_name GameEffectContext


var source_id: String = ""
var target_id: String = ""
var location_id: String = ""
var activity_transaction_id: String = ""
var event_id: String = ""


static func create(
	new_source_id: String = "",
	new_target_id: String = "",
	new_location_id: String = "",
	new_activity_transaction_id: String = "",
	new_event_id: String = ""
) -> GameEffectContext:
	var context := GameEffectContext.new()
	context.source_id = new_source_id.strip_edges()
	context.target_id = new_target_id.strip_edges()
	context.location_id = new_location_id.strip_edges()
	context.activity_transaction_id = (
		new_activity_transaction_id.strip_edges()
	)
	context.event_id = new_event_id.strip_edges()
	return context


func to_condition_context() -> Dictionary:
	return {
		"source_id": source_id,
		"target_id": target_id,
		"location_id": location_id,
		"activity_transaction_id": activity_transaction_id,
		"event_id": event_id
	}
