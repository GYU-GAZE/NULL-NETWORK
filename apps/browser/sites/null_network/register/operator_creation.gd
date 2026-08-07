extends PanelContainer
class_name OperatorCreationPage


signal registration_completed(operator_id: String)


const STARTER_SELECTION_URL: String = "null.net/select-starter"

@export_category("Locked Physical Server")
@export var server_id: String = "tokyo_japan"
@export var server_label: String = "TOKYO, JAPAN"

@export_category("Identity Options")
@export var gender_ids: PackedStringArray = PackedStringArray()
@export var gender_labels: PackedStringArray = PackedStringArray()
@export var pronoun_set_ids: PackedStringArray = PackedStringArray()
@export var pronoun_labels: PackedStringArray = PackedStringArray()
@export var avatar_ids: PackedStringArray = PackedStringArray()
@export var avatar_labels: PackedStringArray = PackedStringArray()

@export_category("Appearance Options")
@export var body_type_ids: PackedStringArray = PackedStringArray()
@export var face_ids: PackedStringArray = PackedStringArray()
@export var eye_ids: PackedStringArray = PackedStringArray()
@export var outer_layer_ids: PackedStringArray = PackedStringArray()
@export var middle_layer_ids: PackedStringArray = PackedStringArray()
@export var lower_layer_ids: PackedStringArray = PackedStringArray()
@export var hat_ids: PackedStringArray = PackedStringArray()
@export var facial_accessory_ids: PackedStringArray = PackedStringArray()

@onready var form: VBoxContainer = %Form
@onready var registered_panel: VBoxContainer = %RegisteredPanel
@onready var first_name_edit: LineEdit = %FirstNameEdit
@onready var last_name_edit: LineEdit = %LastNameEdit
@onready var nickname_edit: LineEdit = %NicknameEdit
@onready var username_edit: LineEdit = %UsernameEdit
@onready var server_option: OptionButton = %ServerOption
@onready var occupation_option: OptionButton = %OccupationOption
@onready var gender_option: OptionButton = %GenderOption
@onready var pronoun_option: OptionButton = %PronounOption
@onready var avatar_option: OptionButton = %AvatarOption
@onready var body_option: OptionButton = %BodyOption
@onready var face_option: OptionButton = %FaceOption
@onready var eye_option: OptionButton = %EyeOption
@onready var outer_option: OptionButton = %OuterOption
@onready var middle_option: OptionButton = %MiddleOption
@onready var lower_option: OptionButton = %LowerOption
@onready var hat_option: OptionButton = %HatOption
@onready var accessory_option: OptionButton = %AccessoryOption
@onready var valour_spin: SpinBox = %ValourSpin
@onready var logic_spin: SpinBox = %LogicSpin
@onready var sync_spin: SpinBox = %SyncSpin
@onready var self_spin: SpinBox = %SelfSpin
@onready var total_label: Label = %TotalLabel
@onready var occupation_summary: Label = %OccupationSummary
@onready var error_label: Label = %ErrorLabel
@onready var submit_button: Button = %SubmitButton


func _ready() -> void:
	_configure_options()
	_connect_inputs()

	if not registration_completed.is_connected(_on_registration_completed):
		registration_completed.connect(_on_registration_completed)

	_refresh_registration_state()
	_update_form_state()


func _configure_options() -> void:
	_configure_option(server_option, PackedStringArray([server_id]), PackedStringArray([server_label]))
	server_option.disabled = true
	_configure_option(gender_option, gender_ids, gender_labels)
	_configure_option(pronoun_option, pronoun_set_ids, pronoun_labels)
	pronoun_option.disabled = true
	_configure_option(avatar_option, avatar_ids, avatar_labels)
	_configure_option(body_option, body_type_ids)
	_configure_option(face_option, face_ids)
	_configure_option(eye_option, eye_ids)
	_configure_option(outer_option, outer_layer_ids)
	_configure_option(middle_option, middle_layer_ids)
	_configure_option(lower_option, lower_layer_ids)
	_configure_option(hat_option, hat_ids, PackedStringArray(), true)
	_configure_option(accessory_option, facial_accessory_ids, PackedStringArray(), true)
	_configure_occupations()
	_sync_pronouns_to_gender()


func _configure_option(
	option: OptionButton,
	ids: PackedStringArray,
	labels: PackedStringArray = PackedStringArray(),
	include_none: bool = false
) -> void:
	option.clear()

	if include_none:
		option.add_item("None")
		option.set_item_metadata(0, "")

	for index: int in range(ids.size()):
		var option_id: String = ids[index].strip_edges()

		if option_id.is_empty():
			continue

		var label: String = option_id.replace("_", " ").capitalize()

		if index < labels.size() and not labels[index].strip_edges().is_empty():
			label = labels[index].strip_edges()

		option.add_item(label)
		option.set_item_metadata(option.item_count - 1, option_id)


func _configure_occupations() -> void:
	occupation_option.clear()

	for occupation: OccupationData in ContentRegistry.get_occupations():
		occupation_option.add_item(occupation.get_display_name())
		occupation_option.set_item_metadata(
			occupation_option.item_count - 1,
			occupation.get_display_id()
		)


func _connect_inputs() -> void:
	for edit: LineEdit in [
		first_name_edit,
		last_name_edit,
		nickname_edit,
		username_edit
	]:
		edit.text_changed.connect(func(_value: String) -> void:
			_update_form_state()
		)

	for spin: SpinBox in [valour_spin, logic_spin, sync_spin, self_spin]:
		spin.value_changed.connect(func(_value: float) -> void:
			_update_form_state()
		)

	gender_option.item_selected.connect(func(_index: int) -> void:
		_sync_pronouns_to_gender()
		_update_form_state()
	)
	occupation_option.item_selected.connect(func(_index: int) -> void:
		_update_form_state()
	)
	submit_button.pressed.connect(_on_submit_pressed)


func _refresh_registration_state() -> void:
	var already_registered: bool = not CampaignState.operator.is_empty()
	form.visible = not already_registered
	registered_panel.visible = already_registered

	if already_registered:
		%RegisteredLabel.text = "REGISTERED AS %s" % (
			CampaignState.operator.profile.username
		)


func _sync_pronouns_to_gender() -> void:
	if pronoun_option.item_count == 0:
		return

	pronoun_option.select(
		clampi(gender_option.selected, 0, pronoun_option.item_count - 1)
	)


func _update_form_state() -> void:
	var total: int = _get_tendency_total()
	total_label.text = "%d / %d POINTS" % [
		total,
		OperatorService.INITIAL_TENDENCY_TOTAL
	]
	total_label.modulate = (
		Color(0.35, 1.0, 0.55)
		if total == OperatorService.INITIAL_TENDENCY_TOTAL
		else Color(1.0, 0.45, 0.4)
	)

	var occupation: OccupationData = ContentRegistry.get_occupation(
		_get_selected_id(occupation_option)
	)
	occupation_summary.text = (
		occupation.description
		if occupation != null
		else "No occupation is available."
	)
	submit_button.disabled = (
		total != OperatorService.INITIAL_TENDENCY_TOTAL
		or first_name_edit.text.strip_edges().is_empty()
		or last_name_edit.text.strip_edges().is_empty()
		or nickname_edit.text.strip_edges().is_empty()
		or username_edit.text.strip_edges().is_empty()
		or occupation == null
	)


func _on_submit_pressed() -> void:
	error_label.text = ""
	var profile := OperatorProfileData.new()
	profile.first_name = first_name_edit.text
	profile.last_name = last_name_edit.text
	profile.nickname = nickname_edit.text
	profile.username = username_edit.text
	profile.server_id = server_id
	profile.occupation_id = _get_selected_id(occupation_option)
	profile.gender = _get_selected_id(gender_option)
	profile.pronoun_set_id = _get_selected_id(pronoun_option)
	profile.avatar_id = _get_selected_id(avatar_option)

	var appearance := AppearanceData.new()
	appearance.body_type_id = _get_selected_id(body_option)
	appearance.face_id = _get_selected_id(face_option)
	appearance.eye_id = _get_selected_id(eye_option)
	appearance.outer_layer_id = _get_selected_id(outer_option)
	appearance.middle_layer_id = _get_selected_id(middle_option)
	appearance.lower_layer_id = _get_selected_id(lower_option)
	appearance.hat_id = _get_selected_id(hat_option)
	appearance.facial_accessory_id = _get_selected_id(accessory_option)

	var errors: PackedStringArray = OperatorService.register_operator(
		profile,
		appearance,
		_get_tendency_values()
	)

	if not errors.is_empty():
		error_label.text = "\n".join(errors)
		return

	_refresh_registration_state()
	registration_completed.emit(CampaignState.operator.operator_id)


func _on_registration_completed(_operator_id: String) -> void:
	if not CampaignState.has_campaign() \
		or CampaignState.operator.is_empty() \
		or not CampaignState.partner.is_empty() \
		or CampaignState.campaign_phase not in [
			CampaignState.CampaignPhase.PROLOGUE,
			CampaignState.CampaignPhase.OPERATOR_CREATION
		]:
		return

	call_deferred("_open_starter_selection")


func _open_starter_selection() -> void:
	GlobalSignals.request_browser_navigation.emit(
		STARTER_SELECTION_URL,
		"operator_registration",
		"starter_selection"
	)


func _get_tendency_values() -> Dictionary:
	return {
		"valour": int(valour_spin.value),
		"logic": int(logic_spin.value),
		"sync": int(sync_spin.value),
		"self": int(self_spin.value)
	}


func _get_tendency_total() -> int:
	var values: Dictionary = _get_tendency_values()
	return (
		int(values.get("valour", 0))
		+ int(values.get("logic", 0))
		+ int(values.get("sync", 0))
		+ int(values.get("self", 0))
	)


func _get_selected_id(option: OptionButton) -> String:
	if option.item_count == 0 or option.selected < 0:
		return ""

	return str(option.get_item_metadata(option.selected)).strip_edges()
