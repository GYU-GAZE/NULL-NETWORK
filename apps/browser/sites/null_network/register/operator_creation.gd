extends PanelContainer
class_name OperatorCreationPage

signal registration_completed(operator_id: String)
signal browser_navigation_requested(url: String)

enum FlowPage {
	ACCOUNT,
	APPEARANCE,
	METHOD,
	MANUAL,
	ASSESSMENT,
	RESULT,
	COMPLETE
}

const NULL_CHANNEL_URL := "null.net/forums"
const STARTER_LEVEL := 3
const REQUIRED_APPEARANCE_CATEGORIES := [
	AppearanceOptionData.Category.BODY,
	AppearanceOptionData.Category.FACE,
	AppearanceOptionData.Category.EYES,
	AppearanceOptionData.Category.OUTER,
	AppearanceOptionData.Category.MIDDLE,
	AppearanceOptionData.Category.LOWER
]
const OPTIONAL_APPEARANCE_CATEGORIES := [
	AppearanceOptionData.Category.HAT,
	AppearanceOptionData.Category.FACIAL_ACCESSORY
]
const APPEARANCE_LAYER_ORDER := [
	AppearanceOptionData.Category.BODY,
	AppearanceOptionData.Category.LOWER,
	AppearanceOptionData.Category.MIDDLE,
	AppearanceOptionData.Category.OUTER,
	AppearanceOptionData.Category.FACE,
	AppearanceOptionData.Category.EYES,
	AppearanceOptionData.Category.HAT,
	AppearanceOptionData.Category.FACIAL_ACCESSORY
]

@export_category("Data")
@export var assessment_data: CompatibilityAssessmentData
@export var appearance_catalog: AppearanceCatalogData
@export var partner_preview_scene: PackedScene

@export_category("Locked Physical Server")
@export var server_id: String = "tokyo_japan"
@export var server_label: String = "TOKYO, JAPAN"

@export_category("Identity Options")
@export var avatar_ids: PackedStringArray = PackedStringArray([
	"avatar_01", "avatar_02", "avatar_03", "avatar_04", "avatar_05", "avatar_06"
])
@export var avatar_labels: PackedStringArray = PackedStringArray([
	"Avatar 01", "Avatar 02", "Avatar 03", "Avatar 04", "Avatar 05", "Avatar 06"
])
## Future avatar Resources can populate this without changing Assessment code.
## Key: avatar_id. Value: Variant Node id or an empty string.
@export var avatar_variant_hints: Dictionary = {}

@onready var master_scroll: ScrollContainer = %MasterScroll
@onready var page_counter: Label = %PageCounter
@onready var header_subtitle: Label = %HeaderSubtitle
@onready var progress_label: Label = %ProgressLabel
@onready var error_label: Label = %ErrorLabel
@onready var navigation_row: HBoxContainer = %NavigationRow
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton

@onready var account_page: VBoxContainer = %AccountPage
@onready var avatar_preview_label: Label = %AvatarPreviewLabel
@onready var avatar_grid: GridContainer = %AvatarGrid
@onready var username_edit: LineEdit = %UsernameEdit
@onready var server_option: OptionButton = %ServerOption
@onready var writing_style_options: HFlowContainer = %WritingStyleOptions
@onready var kaomoji_options: HFlowContainer = %KaomojiOptions
@onready var first_name_edit: LineEdit = %FirstNameEdit
@onready var last_name_edit: LineEdit = %LastNameEdit
@onready var nickname_edit: LineEdit = %NicknameEdit
@onready var gender_option: OptionButton = %GenderOption
@onready var occupation_option: OptionButton = %OccupationOption
@onready var occupation_summary: Label = %OccupationSummary

@onready var appearance_page: VBoxContainer = %AppearancePage
@onready var portrait_layers: Control = %PortraitLayers
@onready var portrait_placeholder: Label = %PortraitPlaceholder
@onready var overworld_layers: Control = %OverworldLayers
@onready var overworld_placeholder: Label = %OverworldPlaceholder
@onready var direction_left: Button = %DirectionLeft
@onready var direction_front: Button = %DirectionFront
@onready var direction_right: Button = %DirectionRight
@onready var direction_back: Button = %DirectionBack
@onready var appearance_categories: HFlowContainer = %AppearanceCategories
@onready var appearance_grid: GridContainer = %AppearanceGrid
@onready var selection_summary: Label = %SelectionSummary

@onready var method_page: VBoxContainer = %MethodPage
@onready var participate_button: Button = %ParticipateButton
@onready var manual_allocation_button: Button = %ManualAllocationButton

@onready var manual_page: VBoxContainer = %ManualPage
@onready var manual_valour_spin: SpinBox = %ManualValourSpin
@onready var manual_logic_spin: SpinBox = %ManualLogicSpin
@onready var manual_sync_spin: SpinBox = %ManualSyncSpin
@onready var manual_self_spin: SpinBox = %ManualSelfSpin
@onready var manual_total_label: Label = %ManualTotalLabel
@onready var manual_candidate_grid: HFlowContainer = %ManualCandidateGrid
@onready var manual_partner_preview_host: VBoxContainer = %ManualPartnerPreviewHost
@onready var manual_synchronize_button: Button = %ManualSynchronizeButton

@onready var assessment_page: VBoxContainer = %AssessmentPage
@onready var assessment_category: Label = %AssessmentCategory
@onready var assessment_counter: Label = %AssessmentCounter
@onready var question_prompt: Label = %QuestionPrompt
@onready var answer_container: VBoxContainer = %AnswerContainer

@onready var result_page: VBoxContainer = %ResultPage
@onready var result_loading: VBoxContainer = %ResultLoading
@onready var loading_label: Label = %LoadingLabel
@onready var loading_pulse: ProgressBar = %LoadingPulse
@onready var result_content: VBoxContainer = %ResultContent
@onready var result_tendencies: Label = %ResultTendencies
@onready var result_partner_preview_host: VBoxContainer = %ResultPartnerPreviewHost
@onready var accept_result_button: Button = %AcceptResultButton
@onready var retake_assessment_button: Button = %RetakeAssessmentButton
@onready var result_manual_button: Button = %ResultManualButton

@onready var registered_panel: VBoxContainer = %RegisteredPanel
@onready var registered_label: Label = %RegisteredLabel
@onready var open_channel_button: Button = %OpenChannelButton

var _current_page: int = FlowPage.ACCOUNT
var _selected_writing_style: String = "normal"
var _selected_kaomoji: String = "never"
var _selected_avatar_id: String = "avatar_01"
var _appearance_selection: Dictionary = {}
var _appearance_category: int = AppearanceOptionData.Category.BODY
var _overworld_direction: int = 0
var _portrait_layer_rects: Dictionary = {}
var _overworld_layer_rects: Dictionary = {}
var _assessment_session := CompatibilitySessionData.new()
var _question_index: int = 0
var _assessment_result: Dictionary = {}
var _manual_candidate_id: String = ""
var _manual_preview: PartnerPreviewPanel
var _result_preview: PartnerPreviewPanel
var _loading_tween: Tween
var _assessment_auto_advance_pending: bool = false

func _ready() -> void:
	_apply_compact_registration_layout()
	_validate_dependencies()
	_configure_account_page()
	_configure_appearance_page()
	_configure_manual_page()
	_connect_static_controls()
	if not registration_completed.is_connected(_on_registration_completed):
		registration_completed.connect(_on_registration_completed)
	if not CampaignState.operator.is_empty() and not CampaignState.partner.is_empty():
		_show_page(FlowPage.COMPLETE)
	else:
		_show_page(FlowPage.ACCOUNT)

func _apply_compact_registration_layout() -> void:
	var header_panel := find_child("HeaderPanel", true, false) as Control
	if header_panel != null:
		header_panel.hide()
	var progress_strip := find_child("ProgressStrip", true, false) as Control
	if progress_strip != null:
		progress_strip.hide()

	var page_margin := find_child("PageMargin", true, false) as MarginContainer
	if page_margin != null:
		page_margin.add_theme_constant_override("margin_left", 44)
		page_margin.add_theme_constant_override("margin_top", 28)
		page_margin.add_theme_constant_override("margin_right", 44)
		page_margin.add_theme_constant_override("margin_bottom", 30)

	var body_margin := find_child("BodyMargin", true, false) as MarginContainer
	if body_margin != null:
		body_margin.add_theme_constant_override("margin_left", 18)
		body_margin.add_theme_constant_override("margin_top", 14)
		body_margin.add_theme_constant_override("margin_right", 18)
		body_margin.add_theme_constant_override("margin_bottom", 14)

	var avatar_panel := find_child("AvatarPanel", true, false) as Control
	if avatar_panel != null:
		avatar_panel.custom_minimum_size.x = 190.0
	var avatar_preview_frame := find_child("AvatarPreviewFrame", true, false) as Control
	if avatar_preview_frame != null:
		avatar_preview_frame.custom_minimum_size.y = 112.0
	var account_columns := find_child("AccountColumns", true, false) as BoxContainer
	if account_columns != null:
		account_columns.add_theme_constant_override("separation", 10)
	var account_form := find_child("AccountForm", true, false) as BoxContainer
	if account_form != null:
		account_form.add_theme_constant_override("separation", 6)

	var preview_column := find_child("PreviewColumn", true, false) as Control
	if preview_column != null:
		preview_column.custom_minimum_size.x = 230.0
	var portrait_frame := find_child("PortraitFrame", true, false) as Control
	if portrait_frame != null:
		portrait_frame.custom_minimum_size.y = 164.0
	var overworld_frame := find_child("OverworldFrame", true, false) as Control
	if overworld_frame != null:
		overworld_frame.custom_minimum_size.y = 130.0
	if appearance_grid != null:
		appearance_grid.columns = 2

func _validate_dependencies() -> void:
	if assessment_data == null:
		push_error("OperatorCreationPage requires CompatibilityAssessmentData.")
	else:
		for validation_error: String in assessment_data.validate_data():
			push_error("Compatibility Assessment: %s" % validation_error)
	if appearance_catalog == null:
		push_error("OperatorCreationPage requires AppearanceCatalogData.")
	else:
		for validation_error: String in appearance_catalog.validate_data():
			push_error("Appearance Catalog: %s" % validation_error)
	if partner_preview_scene == null:
		push_error("OperatorCreationPage requires partner_preview_scene.")

func _configure_account_page() -> void:
	server_option.clear()
	server_option.add_item(server_label)
	server_option.set_item_metadata(0, server_id)
	server_option.disabled = true

	gender_option.clear()
	_add_option(gender_option, "Male", "male")
	_add_option(gender_option, "Female", "female")
	_add_option(gender_option, "Other", "other")
	_configure_occupations()

	_render_dropdown_choice(
		writing_style_options,
		[
			{"id": "normal", "label": "Normal", "tooltip": "Standard capitalization and punctuation."},
			{"id": "cute", "label": "Cute", "tooltip": "A more expressive presentation for authored digital messages."},
			{"id": "lazy", "label": "Lazy", "tooltip": "Relaxed capitalization and lighter punctuation."},
			{"id": "formal", "label": "Formal", "tooltip": "Structured capitalization, punctuation and sentence presentation."}
		],
		_selected_writing_style,
		_on_writing_style_selected
	)
	_render_dropdown_choice(
		kaomoji_options,
		[
			{"id": "frequent", "label": "Often", "tooltip": "Authored Operator messages may use kaomojis frequently."},
			{"id": "occasional", "label": "Sometimes", "tooltip": "Authored Operator messages may use kaomojis occasionally."},
			{"id": "never", "label": "No.", "tooltip": "Authored Operator messages will not add kaomojis."}
		],
		_selected_kaomoji,
		_on_kaomoji_selected
	)
	_render_avatar_grid()
	_refresh_occupation_summary()

func _configure_occupations() -> void:
	occupation_option.clear()
	for occupation_value in ContentRegistry.get_occupations():
		var occupation := occupation_value as OccupationData
		if occupation == null:
			continue
		occupation_option.add_item(occupation.get_display_name())
		occupation_option.set_item_metadata(
			occupation_option.item_count - 1,
			occupation.get_display_id()
		)

func _render_avatar_grid() -> void:
	_clear_container(avatar_grid)
	var group := ButtonGroup.new()
	for index in range(avatar_ids.size()):
		var avatar_id := avatar_ids[index].strip_edges()
		if avatar_id.is_empty():
			continue
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(48, 38)
		button.text = "%02d" % (index + 1)
		button.tooltip_text = avatar_labels[index] if index < avatar_labels.size() else avatar_id
		button.button_pressed = avatar_id == _selected_avatar_id
		button.pressed.connect(_on_avatar_selected.bind(avatar_id, index))
		avatar_grid.add_child(button)
	_refresh_avatar_preview()

func _render_dropdown_choice(
	container: Container,
	choices: Array,
	selected_id: String,
	callback: Callable
) -> void:
	_clear_container(container)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.custom_minimum_size = Vector2(250, 0)
	var selected_index := 0
	for raw_choice: Variant in choices:
		if raw_choice is not Dictionary:
			continue
		var choice: Dictionary = raw_choice
		var id := str(choice.get("id", ""))
		var item_index := option.item_count
		option.add_item(str(choice.get("label", id)))
		option.set_item_metadata(item_index, id)
		option.set_item_tooltip(item_index, str(choice.get("tooltip", "")))
		if id == selected_id:
			selected_index = item_index
	if option.item_count > 0:
		option.select(clampi(selected_index, 0, option.item_count - 1))
	option.item_selected.connect(
		func(index: int) -> void:
			if index < 0 or index >= option.item_count:
				return
			callback.call(str(option.get_item_metadata(index)))
	)
	container.add_child(option)

func _configure_appearance_page() -> void:
	_build_preview_layers()
	_initialize_appearance_selection()
	_render_appearance_categories()
	_render_appearance_options()
	_update_appearance_preview()

func _build_preview_layers() -> void:
	_clear_texture_layers(portrait_layers, _portrait_layer_rects)
	_clear_texture_layers(overworld_layers, _overworld_layer_rects)
	for category_value in APPEARANCE_LAYER_ORDER:
		var category := int(category_value)
		_portrait_layer_rects[category] = _create_layer_rect(portrait_layers)
		_overworld_layer_rects[category] = _create_layer_rect(overworld_layers)

func _clear_texture_layers(parent: Control, target: Dictionary) -> void:
	target.clear()
	for child: Node in parent.get_children():
		if child is TextureRect:
			parent.remove_child(child)
			child.queue_free()

func _create_layer_rect(parent: Control) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect

func _initialize_appearance_selection() -> void:
	if appearance_catalog == null:
		return
	for category_value in REQUIRED_APPEARANCE_CATEGORIES:
		var category := int(category_value)
		if _appearance_selection.has(category):
			continue
		var options := appearance_catalog.get_options(category)
		_appearance_selection[category] = options[0].option_id if not options.is_empty() else ""
	for category_value in OPTIONAL_APPEARANCE_CATEGORIES:
		var category := int(category_value)
		if not _appearance_selection.has(category):
			_appearance_selection[category] = ""

func _render_appearance_categories() -> void:
	_clear_container(appearance_categories)
	var group := ButtonGroup.new()
	for category_value in AppearanceOptionData.Category.values():
		var category := int(category_value)
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.text = _appearance_category_label(category)
		button.button_pressed = category == _appearance_category
		button.pressed.connect(_on_appearance_category_selected.bind(category))
		appearance_categories.add_child(button)

func _render_appearance_options() -> void:
	_clear_container(appearance_grid)
	if appearance_catalog == null:
		return
	var group := ButtonGroup.new()
	var selected_id := str(_appearance_selection.get(_appearance_category, ""))
	if _appearance_category in OPTIONAL_APPEARANCE_CATEGORIES:
		var none_button := Button.new()
		none_button.toggle_mode = true
		none_button.button_group = group
		none_button.custom_minimum_size = Vector2(132, 60)
		none_button.text = "NONE"
		none_button.button_pressed = selected_id.is_empty()
		none_button.pressed.connect(
			_on_appearance_option_selected.bind(_appearance_category, "")
		)
		appearance_grid.add_child(none_button)
	for option_value in appearance_catalog.get_options(_appearance_category):
		var option := option_value as AppearanceOptionData
		if option == null:
			continue
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(132, 60)
		button.text = option.display_name
		button.icon = option.thumbnail
		button.button_pressed = option.option_id == selected_id
		button.pressed.connect(
			_on_appearance_option_selected.bind(_appearance_category, option.option_id)
		)
		appearance_grid.add_child(button)

func _configure_manual_page() -> void:
	for spin_value in [manual_valour_spin, manual_logic_spin, manual_sync_spin, manual_self_spin]:
		var spin := spin_value as SpinBox
		if spin != null and not spin.value_changed.is_connected(_on_manual_tendency_changed):
			spin.value_changed.connect(_on_manual_tendency_changed)
	_render_manual_candidates()
	_refresh_manual_state()

func _render_manual_candidates() -> void:
	_clear_container(manual_candidate_grid)
	if assessment_data == null:
		return
	var group := ButtonGroup.new()
	for candidate_id: String in assessment_data.manual_candidate_ids:
		var candidate := assessment_data.get_candidate(candidate_id)
		if candidate == null:
			continue
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(170, 58)
		button.text = candidate.display_name
		var apk := ContentRegistry.get_apk(candidate.apk_id)
		if apk != null:
			button.icon = _get_apk_preview_texture(apk)
		button.button_pressed = candidate_id == _manual_candidate_id
		button.pressed.connect(_on_manual_candidate_selected.bind(candidate_id))
		manual_candidate_grid.add_child(button)
	_refresh_manual_preview()

func _connect_static_controls() -> void:
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)
	participate_button.pressed.connect(_on_participate_pressed)
	manual_allocation_button.pressed.connect(_on_manual_allocation_pressed)
	manual_synchronize_button.pressed.connect(_on_manual_synchronize_pressed)
	accept_result_button.pressed.connect(_on_accept_result_pressed)
	retake_assessment_button.pressed.connect(_on_retake_assessment_pressed)
	result_manual_button.pressed.connect(_on_manual_allocation_pressed)
	open_channel_button.pressed.connect(
		func() -> void: browser_navigation_requested.emit(NULL_CHANNEL_URL)
	)
	occupation_option.item_selected.connect(
		func(_index: int) -> void: _refresh_occupation_summary()
	)
	direction_front.pressed.connect(_set_overworld_direction.bind(0))
	direction_right.pressed.connect(_set_overworld_direction.bind(1))
	direction_back.pressed.connect(_set_overworld_direction.bind(2))
	direction_left.pressed.connect(_set_overworld_direction.bind(3))

func _show_page(page: int, scroll_to_top: bool = true) -> void:
	_current_page = page
	_assessment_auto_advance_pending = false
	for control_value in [
		account_page,
		appearance_page,
		method_page,
		manual_page,
		assessment_page,
		result_page,
		registered_panel
	]:
		var control := control_value as Control
		if control != null:
			control.hide()
	match page:
		FlowPage.ACCOUNT: account_page.show()
		FlowPage.APPEARANCE: appearance_page.show()
		FlowPage.METHOD: method_page.show()
		FlowPage.MANUAL: manual_page.show()
		FlowPage.ASSESSMENT: assessment_page.show()
		FlowPage.RESULT: result_page.show()
		FlowPage.COMPLETE: registered_panel.show()
	_update_page_chrome()
	if scroll_to_top:
		master_scroll.set_deferred("scroll_vertical", 0)

func _update_page_chrome() -> void:
	navigation_row.show()
	back_button.show()
	next_button.show()
	next_button.text = "NEXT"
	match _current_page:
		FlowPage.ACCOUNT:
			page_counter.text = "01 / 03"
			header_subtitle.text = "ACCOUNT PROFILE"
			progress_label.text = "ACCOUNT  •  APPEARANCE  •  COMPATIBILITY"
			back_button.disabled = true
			next_button.disabled = false
		FlowPage.APPEARANCE:
			page_counter.text = "02 / 03"
			header_subtitle.text = "VISUAL IDENTITY"
			progress_label.text = "ACCOUNT  •  APPEARANCE  •  COMPATIBILITY"
			back_button.disabled = false
			next_button.disabled = false
		FlowPage.METHOD:
			page_counter.text = "03 / 03"
			header_subtitle.text = "COMPATIBILITY METHOD"
			progress_label.text = "PROFILE COMPLETE // SELECT SYNCHRONIZATION METHOD"
			back_button.disabled = false
			next_button.hide()
		FlowPage.MANUAL:
			page_counter.text = "MANUAL"
			header_subtitle.text = "MANUAL SYNCHRONIZATION"
			progress_label.text = "15 TENDENCY POINTS // STANDARD COMPATIBILITY ROSTER"
			back_button.disabled = false
			next_button.hide()
		FlowPage.ASSESSMENT:
			page_counter.text = "%02d / 18" % (_question_index + 1)
			header_subtitle.text = "COMPATIBILITY ASSESSMENT"
			progress_label.text = "DECLARED RESPONSE // CALIBRATION // COMPATIBILITY"
			back_button.disabled = false
			_refresh_assessment_next_state()
		FlowPage.RESULT:
			page_counter.text = "RESULT"
			header_subtitle.text = "COMPATIBILITY MATCH"
			progress_label.text = "ASSESSMENT COMPLETE // SYNCHRONIZATION PENDING"
			back_button.disabled = false
			next_button.hide()
		FlowPage.COMPLETE:
			page_counter.text = "DONE"
			header_subtitle.text = "ACCOUNT ACTIVE"
			progress_label.text = "OPERATOR REGISTERED // PARTNER SYNCHRONIZED"
			navigation_row.hide()

func _on_next_pressed() -> void:
	_clear_error()
	match _current_page:
		FlowPage.ACCOUNT:
			var errors := _validate_account_page()
			if not errors.is_empty():
				_show_errors(errors)
				return
			_show_page(FlowPage.APPEARANCE)
		FlowPage.APPEARANCE:
			var errors := _collect_appearance().validate_data()
			if not errors.is_empty():
				_show_errors(errors)
				return
			_show_page(FlowPage.METHOD)
		FlowPage.ASSESSMENT:
			_advance_assessment_question()

func _on_back_pressed() -> void:
	_clear_error()
	match _current_page:
		FlowPage.APPEARANCE:
			_show_page(FlowPage.ACCOUNT)
		FlowPage.METHOD:
			_show_page(FlowPage.APPEARANCE)
		FlowPage.MANUAL:
			_show_page(FlowPage.METHOD)
		FlowPage.ASSESSMENT:
			if _question_index > 0:
				_question_index -= 1
				_render_assessment_question(true)
			else:
				_show_page(FlowPage.METHOD)
		FlowPage.RESULT:
			_question_index = (
				maxi(0, assessment_data.questions.size() - 1)
				if assessment_data != null
				else 0
			)
			_show_page(FlowPage.ASSESSMENT)
			_render_assessment_question(true)

func _on_participate_pressed() -> void:
	_clear_error()
	_question_index = (
		clampi(_question_index, 0, maxi(0, assessment_data.questions.size() - 1))
		if assessment_data != null
		else 0
	)
	_show_page(FlowPage.ASSESSMENT)
	_render_assessment_question(true)

func _on_manual_allocation_pressed() -> void:
	_clear_error()
	_show_page(FlowPage.MANUAL)
	_refresh_manual_state()

func _render_assessment_question(track_visit: bool) -> void:
	_assessment_auto_advance_pending = false
	_clear_container(answer_container)
	if assessment_data == null or assessment_data.questions.is_empty():
		_show_errors(PackedStringArray(["Compatibility Assessment data is unavailable."]))
		return
	_question_index = clampi(_question_index, 0, assessment_data.questions.size() - 1)
	var question := assessment_data.questions[_question_index] as CompatibilityQuestionData
	if question == null:
		_show_errors(PackedStringArray(["The current Assessment question is invalid."]))
		return
	if track_visit:
		_assessment_session.note_question_visit(question.question_id)
	assessment_counter.text = "%02d / %02d" % [
		_question_index + 1,
		assessment_data.questions.size()
	]
	assessment_category.text = CompatibilityQuestionData.Category.keys()[question.category].replace("_", " ")
	question_prompt.text = question.prompt
	var order := CompatibilityAssessmentService.get_or_create_visual_order(
		question,
		_assessment_session
	)
	var group := ButtonGroup.new()
	var selected_id := str(
		_assessment_session.final_answer_by_question.get(question.question_id, "")
	)
	for visual_position in range(order.size()):
		var answer := question.get_answer(order[visual_position])
		if answer == null:
			continue
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 52)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = answer.text
		button.button_pressed = answer.answer_id == selected_id
		button.pressed.connect(
			_on_assessment_answer_selected.bind(
				question.question_id,
				answer.answer_id,
				visual_position
			)
		)
		answer_container.add_child(button)
	_refresh_assessment_next_state()
	_update_page_chrome()
	master_scroll.set_deferred("scroll_vertical", 0)

func _on_assessment_answer_selected(
	question_id: String,
	answer_id: String,
	visual_position: int
) -> void:
	var previous_answer := str(
		_assessment_session.final_answer_by_question.get(question_id, "")
	)
	var confirmed_existing_answer := previous_answer == answer_id
	_assessment_session.record_answer(question_id, answer_id, visual_position)
	_refresh_assessment_next_state()
	if confirmed_existing_answer and not _assessment_auto_advance_pending:
		_assessment_auto_advance_pending = true
		call_deferred(
			"_advance_assessment_after_confirmation",
			question_id,
			_question_index
		)

func _advance_assessment_after_confirmation(
	question_id: String,
	expected_question_index: int
) -> void:
	_assessment_auto_advance_pending = false
	if (
		_current_page != FlowPage.ASSESSMENT
		or assessment_data == null
		or expected_question_index != _question_index
		or _question_index < 0
		or _question_index >= assessment_data.questions.size()
	):
		return
	var question := assessment_data.questions[_question_index] as CompatibilityQuestionData
	if question == null or question.question_id != question_id:
		return
	_advance_assessment_question()

func _refresh_assessment_next_state() -> void:
	if (
		_current_page != FlowPage.ASSESSMENT
		or assessment_data == null
		or assessment_data.questions.is_empty()
	):
		return
	var question := assessment_data.questions[_question_index] as CompatibilityQuestionData
	next_button.disabled = (
		question == null
		or not _assessment_session.final_answer_by_question.has(question.question_id)
	)
	next_button.text = (
		"CALCULATE"
		if _question_index == assessment_data.questions.size() - 1
		else "NEXT"
	)

func _advance_assessment_question() -> void:
	if assessment_data == null:
		return
	if _question_index < assessment_data.questions.size() - 1:
		_question_index += 1
		_render_assessment_question(true)
		return
	_calculate_and_show_result(true)

func _calculate_and_show_result(with_loading: bool) -> void:
	if assessment_data == null:
		return
	_assessment_result = CompatibilityAssessmentService.evaluate(
		assessment_data,
		_assessment_session,
		_selected_writing_style,
		_selected_kaomoji,
		str(avatar_variant_hints.get(_selected_avatar_id, ""))
	)
	var errors_value: Variant = _assessment_result.get("errors", PackedStringArray())
	if errors_value is PackedStringArray:
		var errors: PackedStringArray = errors_value
		if not errors.is_empty():
			_show_errors(errors)
			return
	_show_page(FlowPage.RESULT)
	if with_loading:
		await _play_result_loading()
	else:
		_show_result_content()

func _play_result_loading() -> void:
	result_loading.show()
	result_content.hide()
	loading_pulse.value = 5.0
	loading_label.text = "CALCULATING COMPATIBILITY..."
	if _loading_tween != null and _loading_tween.is_valid():
		_loading_tween.kill()
	_loading_tween = create_tween()
	_loading_tween.set_trans(Tween.TRANS_CUBIC)
	_loading_tween.set_ease(Tween.EASE_IN_OUT)
	_loading_tween.tween_property(loading_pulse, "value", 100.0, 0.78)
	await _loading_tween.finished
	if _current_page == FlowPage.RESULT:
		_show_result_content()

func _show_result_content() -> void:
	result_loading.hide()
	result_content.show()
	var tendencies := _dictionary_value(_assessment_result.get("tendencies", {}))
	result_tendencies.text = "VALOUR %d   LOGIC %d   SYNC %d   SELF %d" % [
		int(tendencies.get("valour", 0)),
		int(tendencies.get("logic", 0)),
		int(tendencies.get("sync", 0)),
		int(tendencies.get("self", 0))
	]
	var candidate: CompatibilityCandidateData = null
	if assessment_data != null:
		candidate = assessment_data.get_candidate(
			str(_assessment_result.get("candidate_id", ""))
		)
	var variant_info := _dictionary_value(
		_assessment_result.get("variant_placeholder", {})
	)
	var variant_id := str(variant_info.get("selected_variant_id", ""))
	_result_preview = _replace_partner_preview(
		result_partner_preview_host,
		candidate,
		variant_id
	)
	accept_result_button.disabled = (
		_result_preview == null
		or not _result_preview.has_resolved_apk()
	)

func _on_retake_assessment_pressed() -> void:
	_assessment_session.recalibration_count += 1
	_assessment_session.reset_answers()
	_assessment_result.clear()
	_question_index = 0
	_show_page(FlowPage.ASSESSMENT)
	_render_assessment_question(true)

func _on_accept_result_pressed() -> void:
	if assessment_data == null or _assessment_result.is_empty():
		return
	var candidate := assessment_data.get_candidate(
		str(_assessment_result.get("candidate_id", ""))
	)
	var tendencies := _dictionary_value(_assessment_result.get("tendencies", {}))
	_finalize_registration(candidate, tendencies, "assessment")

func _on_manual_synchronize_pressed() -> void:
	if assessment_data == null:
		return
	var candidate := assessment_data.get_candidate(_manual_candidate_id)
	_finalize_registration(candidate, _get_manual_tendencies(), "manual")

func _finalize_registration(
	candidate: CompatibilityCandidateData,
	tendencies: Dictionary,
	mode: String
) -> void:
	_clear_error()
	if candidate == null:
		_show_errors(PackedStringArray([
			"Select a compatible APK before synchronization."
		]))
		return
	var apk := ContentRegistry.get_apk(candidate.apk_id)
	if apk == null or not apk.validate_data().is_empty():
		_show_errors(PackedStringArray([
			"%s is part of the Compatibility roster, but its APKData content is not registered in this build yet."
			% candidate.display_name
		]))
		return
	var profile := _collect_profile()
	var appearance := _collect_appearance()
	if CampaignState.operator.is_empty():
		var validation_errors := OperatorService.validate_registration(
			profile,
			appearance,
			tendencies
		)
		if not validation_errors.is_empty():
			_show_errors(validation_errors)
			return
		var registration_errors := OperatorService.register_operator(
			profile,
			appearance,
			tendencies
		)
		if not registration_errors.is_empty():
			_show_errors(registration_errors)
			return
	if not CampaignState.partner.is_empty():
		_show_errors(PackedStringArray([
			"This Operator already has a synchronized partner."
		]))
		return
	var starter_errors := APKProgressionService.select_starter(candidate.apk_id)
	if not starter_errors.is_empty():
		_show_errors(starter_errors)
		return
	CampaignState.operator.onboarding_metadata = _build_onboarding_metadata(
		mode,
		candidate,
		tendencies
	)
	SaveManager.request_checkpoint(&"onboarding.synchronized", true)
	registration_completed.emit(CampaignState.operator.operator_id)
	_show_page(FlowPage.COMPLETE)

func _build_onboarding_metadata(
	mode: String,
	candidate: CompatibilityCandidateData,
	tendencies: Dictionary
) -> Dictionary:
	var metadata := {
		"mode": mode,
		"candidate_id": candidate.candidate_id,
		"apk_id": candidate.apk_id,
		"starter_level": STARTER_LEVEL,
		"initial_tendencies": tendencies.duplicate(true),
		"writing_style_id": _selected_writing_style,
		"kaomoji_preference_id": _selected_kaomoji,
		"avatar_id": _selected_avatar_id,
		"avatar_variant_hint": str(
			avatar_variant_hints.get(_selected_avatar_id, "")
		)
	}
	if mode == "assessment":
		metadata["assessment_session"] = _assessment_session.to_save_data()
		metadata["axis_values"] = _dictionary_value(
			_assessment_result.get("axis_values", {})
		).duplicate(true)
		metadata["axis_confidence"] = _dictionary_value(
			_assessment_result.get("axis_confidence", {})
		).duplicate(true)
		metadata["rush_detected"] = bool(
			_assessment_result.get("rush_detected", false)
		)
		metadata["variant_placeholder"] = _dictionary_value(
			_assessment_result.get("variant_placeholder", {})
		).duplicate(true)
	return metadata

func _on_registration_completed(_operator_id: String) -> void:
	# Starter synchronization is part of this transaction. The old
	# null.net/select-starter redirect remains only for legacy content.
	pass

func _validate_account_page() -> PackedStringArray:
	var errors := PackedStringArray()
	if first_name_edit.text.strip_edges().is_empty():
		errors.append("First name is required.")
	if last_name_edit.text.strip_edges().is_empty():
		errors.append("Second name is required.")
	if nickname_edit.text.strip_edges().is_empty():
		errors.append("Nickname is required.")
	if username_edit.text.strip_edges().is_empty():
		errors.append("Username is required.")
	if _selected_avatar_id.is_empty():
		errors.append("Forum avatar is required.")
	if _get_selected_id(occupation_option).is_empty():
		errors.append("Occupation is required.")
	return errors

func _collect_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = first_name_edit.text
	profile.last_name = last_name_edit.text
	profile.nickname = nickname_edit.text
	profile.username = username_edit.text
	profile.server_id = server_id
	profile.occupation_id = _get_selected_id(occupation_option)
	profile.gender = _get_selected_id(gender_option)
	profile.resolve_pronoun_set_from_gender()
	profile.avatar_id = _selected_avatar_id
	profile.writing_style_id = _selected_writing_style
	profile.kaomoji_preference_id = _selected_kaomoji
	return profile

func _collect_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = str(
		_appearance_selection.get(AppearanceOptionData.Category.BODY, "")
	)
	appearance.face_id = str(
		_appearance_selection.get(AppearanceOptionData.Category.FACE, "")
	)
	appearance.eye_id = str(
		_appearance_selection.get(AppearanceOptionData.Category.EYES, "")
	)
	appearance.outer_layer_id = str(
		_appearance_selection.get(AppearanceOptionData.Category.OUTER, "")
	)
	appearance.middle_layer_id = str(
		_appearance_selection.get(AppearanceOptionData.Category.MIDDLE, "")
	)
	appearance.lower_layer_id = str(
		_appearance_selection.get(AppearanceOptionData.Category.LOWER, "")
	)
	appearance.hat_id = str(
		_appearance_selection.get(AppearanceOptionData.Category.HAT, "")
	)
	appearance.facial_accessory_id = str(
		_appearance_selection.get(
			AppearanceOptionData.Category.FACIAL_ACCESSORY,
			""
		)
	)
	return appearance

func _get_manual_tendencies() -> Dictionary:
	return {
		"valour": int(manual_valour_spin.value),
		"logic": int(manual_logic_spin.value),
		"sync": int(manual_sync_spin.value),
		"self": int(manual_self_spin.value)
	}

func _get_tendency_total(values: Dictionary) -> int:
	return (
		int(values.get("valour", 0))
		+ int(values.get("logic", 0))
		+ int(values.get("sync", 0))
		+ int(values.get("self", 0))
	)

func _on_manual_tendency_changed(_value: float) -> void:
	_refresh_manual_state()

func _refresh_manual_state() -> void:
	var total := _get_tendency_total(_get_manual_tendencies())
	manual_total_label.text = "%d / %d POINTS" % [
		total,
		OperatorService.INITIAL_TENDENCY_TOTAL
	]
	manual_total_label.modulate = (
		Color(0.12, 0.52, 0.43)
		if total == OperatorService.INITIAL_TENDENCY_TOTAL
		else Color(0.76, 0.22, 0.25)
	)
	manual_synchronize_button.disabled = (
		total != OperatorService.INITIAL_TENDENCY_TOTAL
		or _manual_preview == null
		or not _manual_preview.has_resolved_apk()
	)

func _on_manual_candidate_selected(candidate_id: String) -> void:
	_manual_candidate_id = candidate_id
	_refresh_manual_preview()
	_refresh_manual_state()

func _refresh_manual_preview() -> void:
	var candidate: CompatibilityCandidateData = null
	if assessment_data != null:
		candidate = assessment_data.get_candidate(_manual_candidate_id)
	_manual_preview = _replace_partner_preview(
		manual_partner_preview_host,
		candidate,
		""
	)

func _replace_partner_preview(
	host: Container,
	candidate: CompatibilityCandidateData,
	variant_id: String
) -> PartnerPreviewPanel:
	_clear_container(host)
	if partner_preview_scene == null:
		return null
	var preview := partner_preview_scene.instantiate() as PartnerPreviewPanel
	if preview == null:
		return null
	host.add_child(preview)
	preview.setup(candidate, STARTER_LEVEL, variant_id)
	return preview

func _on_writing_style_selected(id: String) -> void:
	_selected_writing_style = id

func _on_kaomoji_selected(id: String) -> void:
	_selected_kaomoji = id

func _on_avatar_selected(avatar_id: String, index: int) -> void:
	_selected_avatar_id = avatar_id
	avatar_preview_label.text = "A%02d" % (index + 1)

func _refresh_avatar_preview() -> void:
	var index := avatar_ids.find(_selected_avatar_id)
	avatar_preview_label.text = "A%02d" % (index + 1) if index >= 0 else "--"

func _on_appearance_category_selected(category: int) -> void:
	_appearance_category = category
	_render_appearance_categories()
	_render_appearance_options()

func _on_appearance_option_selected(category: int, option_id: String) -> void:
	_appearance_selection[category] = option_id
	_render_appearance_options()
	_update_appearance_preview()

func _set_overworld_direction(direction: int) -> void:
	_overworld_direction = posmod(direction, 4)
	_update_appearance_preview()

func _update_appearance_preview() -> void:
	var has_portrait_texture := false
	var has_overworld_texture := false
	if appearance_catalog != null:
		for category_value in AppearanceOptionData.Category.values():
			var category := int(category_value)
			var option := appearance_catalog.get_option(
				str(_appearance_selection.get(category, ""))
			)
			var portrait_rect := _portrait_layer_rects.get(category) as TextureRect
			var overworld_rect := _overworld_layer_rects.get(category) as TextureRect
			if portrait_rect != null:
				portrait_rect.texture = (
					option.portrait_layer if option != null else null
				)
				has_portrait_texture = (
					has_portrait_texture or portrait_rect.texture != null
				)
			if overworld_rect != null:
				overworld_rect.texture = (
					option.get_overworld_texture(_overworld_direction)
					if option != null
					else null
				)
				has_overworld_texture = (
					has_overworld_texture or overworld_rect.texture != null
				)
	portrait_placeholder.visible = not has_portrait_texture
	overworld_placeholder.visible = not has_overworld_texture
	overworld_placeholder.text = "OVERWORLD PREVIEW\n%s\nASSET LAYERS READY" % [
		"FRONT", "RIGHT", "BACK", "LEFT"
	][_overworld_direction]
	selection_summary.text = _appearance_summary()

func _appearance_summary() -> String:
	var pieces := PackedStringArray()
	for category_value in AppearanceOptionData.Category.values():
		var category := int(category_value)
		var option_id := str(_appearance_selection.get(category, ""))
		var label := "None"
		if appearance_catalog != null:
			var option := appearance_catalog.get_option(option_id)
			if option != null:
				label = option.display_name
		pieces.append(
			"%s: %s" % [_appearance_category_label(category), label]
		)
	return "  •  ".join(pieces)

func _appearance_category_label(category: int) -> String:
	match category:
		AppearanceOptionData.Category.BODY: return "Body"
		AppearanceOptionData.Category.FACE: return "Face"
		AppearanceOptionData.Category.EYES: return "Eyes"
		AppearanceOptionData.Category.OUTER: return "Outer"
		AppearanceOptionData.Category.MIDDLE: return "Middle"
		AppearanceOptionData.Category.LOWER: return "Lower"
		AppearanceOptionData.Category.HAT: return "Hat"
		AppearanceOptionData.Category.FACIAL_ACCESSORY: return "Face Accessory"
	return "Appearance"

func _refresh_occupation_summary() -> void:
	var occupation := ContentRegistry.get_occupation(
		_get_selected_id(occupation_option)
	)
	occupation_summary.text = (
		occupation.description
		if occupation != null
		else "No occupation is available."
	)

func _get_selected_id(option: OptionButton) -> String:
	if option == null or option.item_count == 0 or option.selected < 0:
		return ""
	return str(option.get_item_metadata(option.selected)).strip_edges()

func _add_option(option: OptionButton, label: String, value: String) -> void:
	option.add_item(label)
	option.set_item_metadata(option.item_count - 1, value)

func _get_apk_preview_texture(apk: APKData) -> Texture2D:
	if apk == null:
		return null
	if not apk.portraits.is_empty() and apk.portraits[0] != null:
		return apk.portraits[0]
	return apk.combat_icon

func _show_errors(errors: PackedStringArray) -> void:
	error_label.text = "\n".join(errors)

func _clear_error() -> void:
	error_label.text = ""

func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()

func get_browser_state() -> Dictionary:
	return {
		"flow_page": _current_page,
		"scroll_y": master_scroll.scroll_vertical,
		"profile": _collect_profile().to_save_data(),
		"appearance": _collect_appearance().to_save_data(),
		"writing_style": _selected_writing_style,
		"kaomoji": _selected_kaomoji,
		"avatar_id": _selected_avatar_id,
		"appearance_category": _appearance_category,
		"overworld_direction": _overworld_direction,
		"manual_tendencies": _get_manual_tendencies(),
		"manual_candidate_id": _manual_candidate_id,
		"question_index": _question_index,
		"assessment_session": _assessment_session.to_save_data()
	}

func restore_browser_state(state: Dictionary) -> void:
	if (
		state.is_empty()
		or (
			not CampaignState.operator.is_empty()
			and not CampaignState.partner.is_empty()
		)
	):
		return

	var profile := OperatorProfileData.new()
	var profile_value: Variant = state.get("profile", {})
	if profile_value is Dictionary:
		profile.load_save_data(profile_value)
		first_name_edit.text = profile.first_name
		last_name_edit.text = profile.last_name
		nickname_edit.text = profile.nickname
		username_edit.text = profile.username
		_selected_writing_style = profile.writing_style_id
		_selected_kaomoji = profile.kaomoji_preference_id
		if not profile.avatar_id.is_empty():
			_selected_avatar_id = profile.avatar_id

	_selected_writing_style = str(
		state.get("writing_style", _selected_writing_style)
	)
	_selected_kaomoji = str(state.get("kaomoji", _selected_kaomoji))
	_selected_avatar_id = str(state.get("avatar_id", _selected_avatar_id))

	# Rebuild dynamic choice controls after restoring their model values, then
	# restore the OptionButton selections that rebuilding resets.
	_configure_account_page()
	_select_option_by_metadata(gender_option, profile.gender)
	_select_option_by_metadata(occupation_option, profile.occupation_id)
	_refresh_occupation_summary()

	var appearance_value: Variant = state.get("appearance", {})
	if appearance_value is Dictionary:
		var appearance := AppearanceData.new()
		appearance.load_save_data(appearance_value)
		_restore_appearance_selection(appearance)
	_appearance_category = clampi(
		int(state.get("appearance_category", _appearance_category)),
		AppearanceOptionData.Category.BODY,
		AppearanceOptionData.Category.FACIAL_ACCESSORY
	)
	_overworld_direction = posmod(
		int(state.get("overworld_direction", 0)),
		4
	)

	_manual_candidate_id = str(state.get("manual_candidate_id", ""))
	var manual_values := _dictionary_value(state.get("manual_tendencies", {}))
	manual_valour_spin.value = int(manual_values.get("valour", 4))
	manual_logic_spin.value = int(manual_values.get("logic", 4))
	manual_sync_spin.value = int(manual_values.get("sync", 4))
	manual_self_spin.value = int(manual_values.get("self", 3))

	var assessment_value: Variant = state.get("assessment_session", {})
	if assessment_value is Dictionary:
		_assessment_session.load_save_data(assessment_value)
	_question_index = int(state.get("question_index", 0))

	_render_appearance_categories()
	_render_appearance_options()
	_update_appearance_preview()
	_render_manual_candidates()

	var restored_page := clampi(
		int(state.get("flow_page", FlowPage.ACCOUNT)),
		FlowPage.ACCOUNT,
		FlowPage.RESULT
	)
	if (
		restored_page == FlowPage.RESULT
		and assessment_data != null
		and _assessment_session.is_complete(assessment_data.questions.size())
	):
		_calculate_and_show_result(false)
	elif restored_page == FlowPage.ASSESSMENT:
		_show_page(FlowPage.ASSESSMENT)
		_render_assessment_question(false)
	else:
		_show_page(restored_page)
	master_scroll.set_deferred(
		"scroll_vertical",
		maxi(0, int(state.get("scroll_y", 0)))
	)

func _restore_appearance_selection(appearance: AppearanceData) -> void:
	_appearance_selection[AppearanceOptionData.Category.BODY] = appearance.body_type_id
	_appearance_selection[AppearanceOptionData.Category.FACE] = appearance.face_id
	_appearance_selection[AppearanceOptionData.Category.EYES] = appearance.eye_id
	_appearance_selection[AppearanceOptionData.Category.OUTER] = appearance.outer_layer_id
	_appearance_selection[AppearanceOptionData.Category.MIDDLE] = appearance.middle_layer_id
	_appearance_selection[AppearanceOptionData.Category.LOWER] = appearance.lower_layer_id
	_appearance_selection[AppearanceOptionData.Category.HAT] = appearance.hat_id
	_appearance_selection[AppearanceOptionData.Category.FACIAL_ACCESSORY] = appearance.facial_accessory_id

func _select_option_by_metadata(option: OptionButton, value: String) -> void:
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == value:
			option.select(index)
			return

func _dictionary_value(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
