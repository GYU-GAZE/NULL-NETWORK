extends Node
class_name OperatorRegistrationHandoffRelay


var _page: OperatorCreationRevampedPage
var _handoff_active: bool = false
var _suppressing_visibility_signal: bool = false
var _page_signals_bound: bool = false


func _ready() -> void:
	_page = get_parent() as OperatorCreationRevampedPage
	if _page == null:
		push_error("OperatorRegistrationHandoffRelay requires OperatorCreationRevampedPage parent.")
		return

	# Child _ready() runs before the parent's _ready(), so the parent's @onready
	# Control references are not guaranteed to exist yet. Bind to the page only
	# after its formal ready boundary instead of relying on a frame delay.
	if _page.is_node_ready():
		_bind_page_signals()
	elif not _page.ready.is_connected(_bind_page_signals):
		_page.ready.connect(_bind_page_signals, CONNECT_ONE_SHOT)


func is_bound_to_page() -> bool:
	return (
		_page_signals_bound
		and is_instance_valid(_page)
		and is_instance_valid(_page.open_channel_button)
	)


func _bind_page_signals() -> void:
	if _page_signals_bound or not is_instance_valid(_page):
		return
	if not is_instance_valid(_page.open_channel_button):
		push_error("OperatorRegistrationHandoffRelay could not resolve OpenChannelButton after page ready.")
		return

	if not _page.onboarding_handoff_requested.is_connected(_on_handoff_requested):
		_page.onboarding_handoff_requested.connect(_on_handoff_requested)
	if not _page.open_channel_button.visibility_changed.is_connected(
		_on_open_channel_visibility_changed
	):
		_page.open_channel_button.visibility_changed.connect(
			_on_open_channel_visibility_changed
		)
	_page_signals_bound = true


func _on_handoff_requested(operator_id: String) -> void:
	_handoff_active = true
	if is_instance_valid(_page) and is_instance_valid(_page.open_channel_button):
		_page.open_channel_button.disabled = true
		_page.open_channel_button.hide()
	GlobalSignals.onboarding_handoff_requested.emit(operator_id)


func _on_open_channel_visibility_changed() -> void:
	if not _handoff_active or _suppressing_visibility_signal:
		return
	if (
		not is_instance_valid(_page)
		or not is_instance_valid(_page.open_channel_button)
		or not _page.open_channel_button.visible
	):
		return
	_suppressing_visibility_signal = true
	_page.open_channel_button.hide()
	_page.open_channel_button.disabled = true
	_suppressing_visibility_signal = false
