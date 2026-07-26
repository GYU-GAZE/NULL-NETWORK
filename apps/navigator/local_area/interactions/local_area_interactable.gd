extends Area2D
class_name LocalAreaInteractable


signal interaction_requested(interactable: LocalAreaInteractable)


@export var interaction_data: LocalAreaInteractionData
@export_range(-100, 100, 1)
var interaction_priority: int = 0
@export var available: bool = true


func can_interact() -> bool:
	return (
		available
		and interaction_data != null
		and not interaction_data.get_display_id().is_empty()
	)


func request_interaction() -> bool:
	if not can_interact():
		return false

	interaction_requested.emit(self)
	return true


func get_interaction_id() -> String:
	if interaction_data == null:
		return ""

	return interaction_data.get_display_id()


func get_interaction_priority() -> int:
	return interaction_priority


func set_available(value: bool) -> void:
	available = value
	monitoring = value
	monitorable = value


func get_persistent_state() -> Dictionary:
	return {
		"available": available
	}


func apply_persistent_state(state: Dictionary) -> void:
	set_available(bool(state.get("available", available)))
