extends Node
class_name OperatorRegistrationHandoffRelay


func _ready() -> void:
	var page := get_parent() as OperatorCreationRevampedPage
	if page == null:
		push_error("OperatorRegistrationHandoffRelay requires OperatorCreationRevampedPage parent.")
		return
	if not page.onboarding_handoff_requested.is_connected(_on_handoff_requested):
		page.onboarding_handoff_requested.connect(_on_handoff_requested)


func _on_handoff_requested(operator_id: String) -> void:
	GlobalSignals.onboarding_handoff_requested.emit(operator_id)
