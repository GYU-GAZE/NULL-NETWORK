extends Control
class_name ActivityConfirmationDialog


@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var cost_label: Label = %CostLabel
@onready var available_time_label: Label = %AvailableTimeLabel
@onready var final_time_label: Label = %FinalTimeLabel
@onready var transition_label: Label = %TransitionLabel
@onready var warning_label: Label = %WarningLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton


var _queued_request_ids: Array[String] = []
var _payloads_by_request_id: Dictionary = {}
var _current_request_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_connect_signals()


func _connect_signals() -> void:
	if not GlobalSignals.activity_confirmation_requested.is_connected(
		_on_confirmation_requested
	):
		GlobalSignals.activity_confirmation_requested.connect(
			_on_confirmation_requested
		)

	if not GlobalSignals.activity_request_cancelled.is_connected(
		_on_request_cancelled
	):
		GlobalSignals.activity_request_cancelled.connect(
			_on_request_cancelled
		)

	if not confirm_button.pressed.is_connected(
		_on_confirm_pressed
	):
		confirm_button.pressed.connect(_on_confirm_pressed)

	if not cancel_button.pressed.is_connected(
		_on_cancel_pressed
	):
		cancel_button.pressed.connect(_on_cancel_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


func _on_confirmation_requested(
	request_id: String,
	definition: ActivityDefinitionData,
	preview: ActivityPreviewData,
	source_id: String
) -> void:
	var clean_request_id: String = request_id.strip_edges()

	if (
		clean_request_id.is_empty()
		or definition == null
		or preview == null
	):
		return

	_payloads_by_request_id[clean_request_id] = {
		"definition": definition,
		"preview": preview,
		"source_id": source_id.strip_edges()
	}

	if (
		clean_request_id != _current_request_id
		and not _queued_request_ids.has(clean_request_id)
	):
		_queued_request_ids.append(clean_request_id)

	_show_next_request()


func _on_request_cancelled(request_id: String) -> void:
	var clean_request_id: String = request_id.strip_edges()
	_payloads_by_request_id.erase(clean_request_id)
	_queued_request_ids.erase(clean_request_id)

	if clean_request_id != _current_request_id:
		return

	_current_request_id = ""
	hide()
	_show_next_request()


func _show_next_request() -> void:
	if not _current_request_id.is_empty():
		return

	while not _queued_request_ids.is_empty():
		var request_id: String = _queued_request_ids.pop_front()

		if not _payloads_by_request_id.has(request_id):
			continue

		_current_request_id = request_id
		_display_request(
			_payloads_by_request_id[request_id]
			as Dictionary
		)
		show()
		move_to_front()
		confirm_button.grab_focus()
		return

	hide()


func _display_request(payload: Dictionary) -> void:
	var definition := (
		payload.get("definition") as ActivityDefinitionData
	)
	var preview := (
		payload.get("preview") as ActivityPreviewData
	)

	if definition == null or preview == null:
		return

	title_label.text = definition.get_display_name()
	message_label.text = definition.get_confirmation_message()

	var block_word: String = (
		"block"
		if preview.charged_action_cost == 1
		else "blocks"
	)
	cost_label.text = "Time Cost: %d %s" % [
		preview.charged_action_cost,
		block_word
	]
	available_time_label.text = "Available Today: %d blocks" % (
		preview.available_blocks_in_day
	)
	final_time_label.text = "Ends: %s" % (
		preview.get_final_time_text()
	)

	if preview.crosses_day:
		transition_label.text = (
			"This activity ends on Day %d."
			% preview.final_day
		)
		transition_label.show()
	elif preview.crosses_period:
		transition_label.text = (
			"This activity crosses into %s."
			% preview.get_final_period_name()
		)
		transition_label.show()
	else:
		transition_label.text = ""
		transition_label.hide()

	if preview.expiration_warnings.is_empty():
		warning_label.text = ""
		warning_label.hide()
	else:
		warning_label.text = "\n".join(
			preview.expiration_warnings
		)
		warning_label.show()


func _on_confirm_pressed() -> void:
	_resolve_current_request(true)


func _on_cancel_pressed() -> void:
	_resolve_current_request(false)


func _resolve_current_request(confirmed: bool) -> void:
	if _current_request_id.is_empty():
		return

	var request_id: String = _current_request_id
	_current_request_id = ""
	_payloads_by_request_id.erase(request_id)
	hide()

	GlobalSignals.activity_confirmation_resolved.emit(
		request_id,
		confirmed
	)
	_show_next_request()
