extends Resource
class_name ChatMessageData


enum SenderKind {
	NPC,
	OPERATOR,
	SYSTEM
}


@export_category("Identity")
@export var message_id: String = ""
@export var sender_kind: SenderKind = SenderKind.NPC
@export var sender_id: String = ""

@export_category("Content")
@export_multiline var text_bbcode: String = ""
@export var delivery_conditions: ConditionSetData
@export var unread_when_delivered: bool = false


func get_display_id() -> String:
	return message_id.strip_edges()


func get_sender_id(default_npc_id: String = "") -> String:
	var clean_id: String = sender_id.strip_edges()

	if not clean_id.is_empty():
		return clean_id

	if sender_kind == SenderKind.NPC:
		return default_npc_id.strip_edges()

	if sender_kind == SenderKind.OPERATOR:
		return "operator"

	return "system"


func can_deliver(context: Dictionary = {}) -> bool:
	return delivery_conditions == null \
		or delivery_conditions.is_met(context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("message_id cannot be empty.")

	if text_bbcode.strip_edges().is_empty():
		errors.append("text_bbcode cannot be empty.")

	if delivery_conditions != null:
		for error: String in delivery_conditions.validate_data():
			errors.append("Delivery condition: %s" % error)

	return errors
