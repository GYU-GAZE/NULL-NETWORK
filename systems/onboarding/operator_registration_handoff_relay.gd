extends Node
class_name OperatorRegistrationHandoffRelay


var _page: OperatorCreationRevampedPage
var _handoff_active: bool = false
var _suppressing_visibility_signal: bool = false


func _ready() -> void:
	_page = get_parent() as OperatorCreationRevampedPage
	if _page == null:
		push_error("OperatorRegistrationHandoffRelay requires OperatorCreationRevampedPage parent.")
		return
	if not _page.onboarding_handoff_requested.is_connected(_on_handoff_requested):
		_page.onboarding_handoff_requested.connect(_on_handoff_requested)
	if not _page.open_channel_button.visibility_changed.is_connected(_on_open_channel_visibility_changed):
		_page.open_channel_button.visibility_changed.connect(_on_open_channel_visibility_changed)


func _on_handoff_requested(operator_id: String) -> void:
	_handoff_active = true
	_page.open_channel_button.disabled = true
	_page.open_channel_button.hide()
	GlobalSignals.onboarding_handoff_requested.emit(operator_id)


func _on_open_channel_visibility_changed() -> void:
	if not _handoff_active or _suppressing_visibility_signal:
		return
	if not is_instance_valid(_page) or not _page.open_channel_button.visible:
		return
	_suppressing_visibility_signal = true
	_page.open_channel_button.hide()
	_page.open_channel_button.disabled = true
	_suppressing_visibility_signal = false
