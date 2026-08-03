extends PanelContainer
class_name NewCampaignPanel


signal create_requested(
	campaign_id: String,
	display_name: String,
	save_mode: CampaignState.SaveMode
)
signal cancelled


@onready var name_edit: LineEdit = %NameEdit
@onready var id_edit: LineEdit = %IdEdit
@onready var safe_button: CheckButton = %SafeButton
@onready var commit_button: CheckButton = %CommitButton
@onready var commit_acknowledgement: CheckBox = %CommitAcknowledgement
@onready var mode_explanation: RichTextLabel = %ModeExplanation
@onready var error_label: Label = %ErrorLabel
@onready var create_button: Button = %CreateButton

var _id_was_edited: bool = false
var _updating_id: bool = false


func _ready() -> void:
	safe_button.toggled.connect(_on_safe_toggled)
	commit_button.toggled.connect(_on_commit_toggled)
	commit_acknowledgement.toggled.connect(_on_acknowledgement_toggled)
	name_edit.text_changed.connect(_on_name_changed)
	id_edit.text_changed.connect(_on_id_changed)
	create_button.pressed.connect(_on_create_pressed)
	%CancelButton.pressed.connect(_on_cancel_pressed)
	set_process_unhandled_key_input(true)
	_reset_form()


func open() -> void:
	_reset_form()
	show()
	name_edit.grab_focus()


func show_error(message: String) -> void:
	error_label.text = message.strip_edges()
	error_label.visible = not error_label.text.is_empty()


func _reset_form() -> void:
	name_edit.clear()
	id_edit.clear()
	_id_was_edited = false
	safe_button.set_pressed_no_signal(true)
	commit_button.set_pressed_no_signal(false)
	commit_acknowledgement.set_pressed_no_signal(false)
	commit_acknowledgement.hide()
	show_error("")
	_update_mode_explanation()
	_update_create_button()


func _selected_mode() -> CampaignState.SaveMode:
	return (
		CampaignState.SaveMode.COMMIT
		if commit_button.button_pressed
		else CampaignState.SaveMode.SAFE
	)


func _on_safe_toggled(pressed: bool) -> void:
	if pressed:
		commit_button.set_pressed_no_signal(false)
	elif not commit_button.button_pressed:
		safe_button.set_pressed_no_signal(true)

	commit_acknowledgement.hide()
	commit_acknowledgement.set_pressed_no_signal(false)
	_update_mode_explanation()
	_update_create_button()


func _on_commit_toggled(pressed: bool) -> void:
	if pressed:
		safe_button.set_pressed_no_signal(false)
	elif not safe_button.button_pressed:
		commit_button.set_pressed_no_signal(true)

	commit_acknowledgement.visible = commit_button.button_pressed
	commit_acknowledgement.set_pressed_no_signal(false)
	_update_mode_explanation()
	_update_create_button()


func _on_acknowledgement_toggled(_pressed: bool) -> void:
	_update_create_button()


func _on_name_changed(value: String) -> void:
	if not _id_was_edited:
		_updating_id = true
		id_edit.text = SaveConstants.sanitize_identifier(value)
		_updating_id = false
	_update_create_button()


func _on_id_changed(_value: String) -> void:
	if not _updating_id:
		_id_was_edited = true
	_update_create_button()


func _update_mode_explanation() -> void:
	if _selected_mode() == CampaignState.SaveMode.SAFE:
		mode_explanation.text = (
			"[b]SAFE MODE[/b]\nAutosaves, manual saves and historical "
			+ "checkpoints are available. Consequences remain real until "
			+ "you explicitly load an earlier checkpoint."
		)
	else:
		mode_explanation.text = (
			"[b][color=#ff7068]COMMIT MODE[/color][/b]\nOne living "
			+ "record. No manual saves and no visible rollback history. "
			+ "Irreversible events overwrite your current record."
		)


func _update_create_button() -> void:
	var has_id := not SaveConstants.sanitize_identifier(id_edit.text).is_empty()
	var commit_confirmed := (
		_selected_mode() != CampaignState.SaveMode.COMMIT
		or commit_acknowledgement.button_pressed
	)
	create_button.disabled = not has_id or not commit_confirmed


func _on_create_pressed() -> void:
	var campaign_id := SaveConstants.sanitize_identifier(id_edit.text)

	if campaign_id.is_empty():
		show_error("Enter a valid campaign ID.")
		return

	if (
		_selected_mode() == CampaignState.SaveMode.COMMIT
		and not commit_acknowledgement.button_pressed
	):
		show_error("Confirm the permanent COMMIT MODE rules first.")
		return

	create_requested.emit(
		campaign_id,
		name_edit.text.strip_edges(),
		_selected_mode()
	)


func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
