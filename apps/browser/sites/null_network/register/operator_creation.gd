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
const ASSESSMENT_ANSWER_BUTTON_SCENE: PackedScene = preload(
	"res://apps/browser/sites/null_network/register/assessment_answer_button.tscn"
)
const ASSESSMENT_ACCENTS: Array[Color] = [
	Color(0.12, 0.55, 1.0, 1.0),
	Color(0.52, 0.35, 1.0, 1.0),
	Color(0.04, 0.78, 0.86, 1.0),
	Color(1.0, 0.34, 0.55, 1.0)
]
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
@export var motion_profile: UiMotionProfileData = preload(
	"res://data/content/ui/motion/null_network_motion.tres"
)

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
@onready var portal_header: NullNetworkPortalHeader = %PortalHeader
@onready var assessment_progress_pips: HBoxContainer = %AssessmentProgressPips

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
@onready var question_prompt: RichTextLabel = %QuestionPrompt
@onready var answer_container: VBoxContainer = %AnswerContainer
@onready var assessment_section_title: Label = %AssessmentSectionTitle
@onready var assessment_question_count: Label = %AssessmentQuestionCount
@onready var assessment_section_body: Label = %AssessmentSectionBody

@onready var result_page: VBoxContainer = %ResultPage
@onready var result_loading: VBoxContainer = %ResultLoading
@onready var loading_label: Label = %LoadingLabel
@onready var result_status_lines: VBoxContainer = %ResultStatusLines
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
var _assessment_auto_advance_pending: bool = false
var _assessment_typewriter: TypewriterReveal
var _assessment_reveal_generation: int = 0
var _motion_player: UiMotionPlayer
var _page_transitioning: bool = false
var _has_presented_page: bool = false
var _result_sequence_generation: int = 0
var _assessment_answers_ready: bool = false
var _assessment_transitioning: bool = false

func _ready() -> void:
	_motion_player = UiMotionPlayer.new()
	_motion_player.name = "RegistrationMotionPlayer"
	_motion_player.profile = motion_profile
	add_child(_motion_player)
	_assessment_typewriter = TypewriterReveal.new()
	_assessment_typewriter.name = "AssessmentTypewriter"
	_assessment_typewriter.characters_per_second = 46.0
	add_child(_assessment_typewriter)
	_assessment_typewriter.reveal_completed.connect(
		_on_assessment_prompt_revealed
	)
	_validate_dependencies()
	_configure_account_page()
	_configure_appearance_page()
	_configure_manual_page()
	_connect_static_controls()
	_build_assessment_progress_pips()
	if not registration_completed.is_connected(_on_registration_completed):
		registration_completed.connect(_on_registration_completed)
	if not CampaignState.operator.is_empty() and not CampaignState.partner.is_empty():
		_show_page(FlowPage.COMPLETE, true, false)
	else:
		_show_page(FlowPage.ACCOUNT, true, false)

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
		button.custom_minimum_size = Vector2(28, 24)
		button.text = "%02d" % (index + 1)
		button.tooltip_text = avatar_labels[index] if index < avatar_labels.size() else avatar_id
		button.button_pressed = avatar_id == _selected_avatar_id
		button.pressed.connect(_on_avatar_selected.bind(avatar_id, index, button))
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
		button.pressed.connect(
			_on_appearance_category_selected.bind(category, button)
		)
		appearance_categories.add_child(button)

func _render_appearance_options(animate: bool = false) -> void:
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
			_on_appearance_option_selected.bind(
				_appearance_category,
				"",
				none_button
			)
		)
		if animate:
			none_button.modulate.a = 0.0
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
			_on_appearance_option_selected.bind(
				_appearance_category,
				option.option_id,
				button
			)
		)
		if animate:
			button.modulate.a = 0.0
		appearance_grid.add_child(button)
	if animate:
		call_deferred("_reveal_appearance_options")

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
		func(_index: int) -> void:
			_refresh_occupation_summary()
			_motion_player.flash_control(
				occupation_option,
				Color(1.08, 1.14, 1.2, 1.0),
				0.08
			)
	)
	for field: LineEdit in [first_name_edit, last_name_edit, nickname_edit, username_edit]:
		field.focus_entered.connect(_on_account_field_focused.bind(field))
	direction_front.pressed.connect(_set_overworld_direction.bind(0, direction_front))
	direction_right.pressed.connect(_set_overworld_direction.bind(1, direction_right))
	direction_back.pressed.connect(_set_overworld_direction.bind(2, direction_back))
	direction_left.pressed.connect(_set_overworld_direction.bind(3, direction_left))

func _show_page(page: int, scroll_to_top: bool = true, animated: bool = true) -> void:
	if _page_transitioning:
		return
	var old_page := _get_flow_page_control(_current_page)
	var next_page := _get_flow_page_control(page)
	var forward := page >= _current_page
	_current_page = page
	_assessment_auto_advance_pending = false
	_result_sequence_generation += 1
	if page != FlowPage.ASSESSMENT:
		_assessment_typewriter.cancel()
		_assessment_reveal_generation += 1
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
		if control != null and control != old_page:
			control.hide()
	if next_page == null:
		return
	if not animated or not _has_presented_page or old_page == next_page:
		if old_page != null and old_page != next_page:
			old_page.hide()
		next_page.show()
		next_page.modulate = Color.WHITE
		next_page.position = KubuOSMetrics.snap_vector(next_page.position)
		_has_presented_page = true
		_update_page_chrome()
		if scroll_to_top:
			call_deferred("_reset_scroll_to_top")
		return
	_page_transitioning = true
	_set_navigation_locked(true)
	if old_page != null:
		await _motion_player.exit_control(
			old_page,
			Vector2(-5 if forward else 5, -2),
			motion_profile.page_exit_duration
		)
	if old_page != null:
		old_page.hide()
	if scroll_to_top:
		await _reset_scroll_to_top()
	next_page.show()
	await _motion_player.enter_control(
		next_page,
		Vector2(5 if forward else -5, 2),
		motion_profile.page_enter_duration
	)
	_page_transitioning = false
	_update_page_chrome()
	_set_navigation_locked(false)


func _get_flow_page_control(page: int) -> Control:
	match page:
		FlowPage.ACCOUNT: return account_page
		FlowPage.APPEARANCE: return appearance_page
		FlowPage.METHOD: return method_page
		FlowPage.MANUAL: return manual_page
		FlowPage.ASSESSMENT: return assessment_page
		FlowPage.RESULT: return result_page
		FlowPage.COMPLETE: return registered_panel
	return null


func _set_navigation_locked(locked: bool) -> void:
	if locked:
		back_button.disabled = true
		next_button.disabled = true
	else:
		_update_page_chrome()
	participate_button.disabled = locked
	manual_allocation_button.disabled = locked

func _reset_scroll_to_top() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()
	master_scroll.scroll_vertical = 0
	await get_tree().process_frame
	master_scroll.scroll_vertical = 0

func _update_page_chrome() -> void:
	navigation_row.show()
	back_button.show()
	next_button.show()
	back_button.text = "‹  BACK"
	next_button.text = "NEXT  ›"
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
	_sync_portal_chrome()

func _sync_portal_chrome() -> void:
	var assessment_active: bool = _current_page == FlowPage.ASSESSMENT
	assessment_progress_pips.visible = assessment_active
	portal_header.set_assessment_mode(assessment_active)
	if assessment_active:
		_update_assessment_section_chrome()

func _on_next_pressed() -> void:
	if _page_transitioning:
		return
	_clear_error()
	match _current_page:
		FlowPage.ACCOUNT:
			var errors := _validate_account_page()
			if not errors.is_empty():
				_show_errors(errors)
				return
			await _motion_player.confirm_control(next_button)
			await _show_page(FlowPage.APPEARANCE)
		FlowPage.APPEARANCE:
			var errors := _collect_appearance().validate_data()
			if not errors.is_empty():
				_show_errors(errors)
				return
			await _motion_player.confirm_control(next_button)
			await _show_page(FlowPage.METHOD)
		FlowPage.ASSESSMENT:
			_advance_assessment_question()

func _on_back_pressed() -> void:
	if _page_transitioning or _assessment_transitioning:
		return
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
				await _hide_assessment_question(false)
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
			await _show_page(FlowPage.ASSESSMENT)
			_render_assessment_question(true)

func _on_participate_pressed() -> void:
	_clear_error()
	_question_index = (
		clampi(_question_index, 0, maxi(0, assessment_data.questions.size() - 1))
		if assessment_data != null
		else 0
	)
	await _show_page(FlowPage.ASSESSMENT)
	_render_assessment_question(true)

func _on_manual_allocation_pressed() -> void:
	_clear_error()
	_show_page(FlowPage.MANUAL)
	_refresh_manual_state()

func _build_assessment_progress_pips() -> void:
	_clear_container(assessment_progress_pips)
	for index: int in range(18):
		var pip := ColorRect.new()
		pip.name = "QuestionPip%02d" % (index + 1)
		pip.custom_minimum_size = Vector2(6, 6)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		assessment_progress_pips.add_child(pip)
	_update_assessment_progress_pips()

func _update_assessment_progress_pips() -> void:
	for index: int in range(assessment_progress_pips.get_child_count()):
		var pip := assessment_progress_pips.get_child(index) as ColorRect
		if pip == null:
			continue
		if index < _question_index:
			pip.color = Color(0.08, 0.38, 0.66, 1.0)
		elif index == _question_index:
			pip.color = Color(0.2, 0.76, 1.0, 1.0)
		else:
			pip.color = Color(0.08, 0.16, 0.24, 1.0)
		pip.modulate = Color.WHITE
	var current_pip := assessment_progress_pips.get_child(_question_index) as Control
	if current_pip != null and _current_page == FlowPage.ASSESSMENT:
		_motion_player.flash_control(current_pip, Color(1.28, 1.28, 1.28, 1.0), 0.08)

func _update_assessment_section_chrome() -> void:
	if assessment_data == null or assessment_data.questions.is_empty():
		return
	var safe_index: int = clampi(_question_index, 0, assessment_data.questions.size() - 1)
	var question := assessment_data.questions[safe_index] as CompatibilityQuestionData
	if question == null:
		return
	var category_index: int = int(question.category)
	var titles := PackedStringArray(["EVERYDAY", "CRITICAL", "DILEMMA"])
	var descriptions := PackedStringArray([
		"These questions are about normal, everyday situations.\n\nThere are no right or wrong answers. Choose the option that feels most natural to you.",
		"These questions place you under pressure.\n\nRespond with the action you would actually take when time, safety or certainty is limited.",
		"These questions ask what you protect when every available choice has a cost.\n\nChoose the answer you could live with afterward."
	])
	category_index = clampi(category_index, 0, titles.size() - 1)
	assessment_section_title.text = titles[category_index]
	assessment_question_count.text = "06 QUESTIONS"
	assessment_section_body.text = descriptions[category_index]
	portal_header.set_assessment_category(category_index)
	_update_assessment_progress_pips()

func _render_assessment_question(track_visit: bool) -> void:
	_assessment_reveal_generation += 1
	_assessment_auto_advance_pending = false
	_assessment_answers_ready = false
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
	_update_assessment_section_chrome()
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
		var button := ASSESSMENT_ANSWER_BUTTON_SCENE.instantiate() as AssessmentAnswerButton
		if button == null:
			continue
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_container.add_child(button)
		button.configure(
			visual_position + 1,
			answer.text,
			ASSESSMENT_ACCENTS[visual_position % ASSESSMENT_ACCENTS.size()]
		)
		button.set_selected(answer.answer_id == selected_id)
		button.disabled = true
		button.scale = Vector2.ONE
		button.modulate.a = 0.0
		button.pressed.connect(
			_on_assessment_answer_selected.bind(
				question.question_id,
				answer.answer_id,
				visual_position
			)
		)
	_refresh_assessment_next_state()
	question_prompt.show()
	question_prompt.modulate = Color.WHITE
	question_prompt.position = KubuOSMetrics.snap_vector(question_prompt.position)
	_assessment_typewriter.play(question_prompt, question.prompt)
	_update_page_chrome()
	master_scroll.set_deferred("scroll_vertical", 0)
	_assessment_transitioning = false


func _on_assessment_prompt_revealed() -> void:
	_assessment_reveal_generation += 1
	var generation := _assessment_reveal_generation
	for child: Node in answer_container.get_children():
		if generation != _assessment_reveal_generation:
			return
		var button := child as AssessmentAnswerButton
		if button == null:
			continue
		await _motion_player.enter_control(button, Vector2(0, 4), 0.13)
		if generation != _assessment_reveal_generation:
			return
		await get_tree().create_timer(motion_profile.stagger_delay).timeout
	if generation != _assessment_reveal_generation:
		return
	_assessment_answers_ready = true
	for child: Node in answer_container.get_children():
		var answer_button := child as AssessmentAnswerButton
		if answer_button != null:
			answer_button.disabled = false
	_refresh_assessment_next_state()

func _on_assessment_answer_selected(
	question_id: String,
	answer_id: String,
	visual_position: int
) -> void:
	if not _assessment_answers_ready or _assessment_auto_advance_pending or _assessment_transitioning:
		return
	var previous_answer := str(
		_assessment_session.final_answer_by_question.get(question_id, "")
	)
	var confirmed_existing_answer := previous_answer == answer_id
	_assessment_session.record_answer(question_id, answer_id, visual_position)
	_refresh_assessment_next_state()
	var selected_button: AssessmentAnswerButton
	for child: Node in answer_container.get_children():
		var button := child as AssessmentAnswerButton
		if button == null:
			continue
		button.modulate = Color.WHITE if button.button_pressed else Color(0.82, 0.86, 0.92, 1.0)
		if button.button_pressed:
			selected_button = button
	if selected_button != null:
		await _motion_player.confirm_control(selected_button)
	if confirmed_existing_answer and not _assessment_auto_advance_pending:
		_assessment_auto_advance_pending = true
		await get_tree().create_timer(0.09).timeout
		await _advance_assessment_after_confirmation(question_id, _question_index)

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
		"CALCULATE  ›"
		if _question_index == assessment_data.questions.size() - 1
		else "NEXT  ›"
	)

func _advance_assessment_question() -> void:
	if assessment_data == null or not _assessment_answers_ready or _assessment_transitioning:
		return
	if _question_index < assessment_data.questions.size() - 1:
		await _hide_assessment_question(true)
		_question_index += 1
		_render_assessment_question(true)
		return
	_calculate_and_show_result(true)


func _hide_assessment_question(forward: bool) -> void:
	_assessment_transitioning = true
	_assessment_answers_ready = false
	_assessment_reveal_generation += 1
	_assessment_typewriter.cancel()
	for child: Node in answer_container.get_children():
		var button := child as BaseButton
		if button != null:
			button.disabled = true
			_motion_player.exit_control(button, Vector2(-4 if forward else 4, 0), 0.08)
	await _motion_player.exit_control(
		question_prompt,
		Vector2(-4 if forward else 4, 0),
		0.09
	)

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
	result_loading.show()
	result_content.hide()
	loading_label.text = "CALCULATING COMPATIBILITY..."
	accept_result_button.disabled = true
	retake_assessment_button.disabled = true
	result_manual_button.disabled = true
	await _show_page(FlowPage.RESULT)
	if with_loading:
		await _play_result_loading()
	else:
		_show_result_content()

func _play_result_loading() -> void:
	_result_sequence_generation += 1
	var generation := _result_sequence_generation
	result_loading.show()
	result_content.hide()
	loading_label.text = "CALCULATING COMPATIBILITY..."
	accept_result_button.disabled = true
	retake_assessment_button.disabled = true
	result_manual_button.disabled = true
	for child: Node in result_status_lines.get_children():
		if child is Control:
			(child as Control).hide()
	await _motion_player.enter_control(loading_label, Vector2(0, 3), 0.13)
	for child: Node in result_status_lines.get_children():
		if generation != _result_sequence_generation or _current_page != FlowPage.RESULT:
			return
		var status_line := child as Control
		if status_line == null:
			continue
		await _motion_player.enter_control(status_line, Vector2(0, 3), 0.11)
		await get_tree().create_timer(0.055).timeout
	if generation != _result_sequence_generation or _current_page != FlowPage.RESULT:
		return
	await get_tree().create_timer(0.1).timeout
	loading_label.text = "MATCH FOUND"
	await _motion_player.flash_control(loading_label, Color(1.2, 1.3, 1.4, 1.0), 0.1)
	if generation != _result_sequence_generation or _current_page != FlowPage.RESULT:
		return
	_show_result_content(false)
	await _motion_player.enter_control(result_content, Vector2(0, 5), 0.16)
	await get_tree().create_timer(0.08).timeout
	_unlock_result_actions()

func _show_result_content(unlock_actions: bool = true) -> void:
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
	if unlock_actions:
		_unlock_result_actions()


func _unlock_result_actions() -> void:
	accept_result_button.disabled = _result_preview == null or not _result_preview.has_resolved_apk()
	retake_assessment_button.disabled = false
	result_manual_button.disabled = false

func _on_retake_assessment_pressed() -> void:
	_assessment_session.recalibration_count += 1
	_assessment_session.reset_answers()
	_assessment_result.clear()
	_question_index = 0
	await _show_page(FlowPage.ASSESSMENT)
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
	registered_label.modulate.a = 0.0
	open_channel_button.modulate.a = 0.0
	await _show_page(FlowPage.COMPLETE)
	await _play_registration_complete()


func _play_registration_complete() -> void:
	open_channel_button.disabled = true
	await _motion_player.enter_control(registered_label, Vector2(0, 4), 0.16)
	await _motion_player.flash_control(registered_panel, Color(1.08, 1.16, 1.22, 1.0), 0.12)
	await get_tree().create_timer(0.06).timeout
	await _motion_player.enter_control(open_channel_button, Vector2(0, 4), 0.14)
	open_channel_button.disabled = false

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
	_motion_player.flash_control(writing_style_options, Color(1.08, 1.14, 1.2, 1.0), 0.08)

func _on_kaomoji_selected(id: String) -> void:
	_selected_kaomoji = id
	_motion_player.flash_control(kaomoji_options, Color(1.08, 1.14, 1.2, 1.0), 0.08)

func _on_account_field_focused(field: LineEdit) -> void:
	_motion_player.flash_control(field, Color(1.06, 1.12, 1.18, 1.0), 0.08)


func _on_avatar_selected(
	avatar_id: String,
	index: int,
	source_button: Button
) -> void:
	await _motion_player.confirm_control(source_button)
	_selected_avatar_id = avatar_id
	avatar_preview_label.text = "A%02d" % (index + 1)
	_motion_player.flash_control(avatar_preview_label, Color(1.1, 1.16, 1.22, 1.0), 0.09)

func _refresh_avatar_preview() -> void:
	var index := avatar_ids.find(_selected_avatar_id)
	avatar_preview_label.text = "A%02d" % (index + 1) if index >= 0 else "--"

func _on_appearance_category_selected(
	category: int,
	source_button: Button
) -> void:
	await _motion_player.confirm_control(source_button)
	_appearance_category = category
	_render_appearance_categories()
	_render_appearance_options(true)


func _reveal_appearance_options() -> void:
	var controls: Array[Control] = []
	for child: Node in appearance_grid.get_children():
		if child is Control:
			controls.append(child as Control)
	await _motion_player.reveal_group_staggered(controls, Vector2.ZERO)


func _on_appearance_option_selected(
	category: int,
	option_id: String,
	source_button: Button
) -> void:
	await _motion_player.confirm_control(source_button)
	_appearance_selection[category] = option_id
	_render_appearance_options()
	_update_appearance_preview()
	_motion_player.flash_control(portrait_layers, Color(1.08, 1.12, 1.18, 1.0), 0.09)
	_motion_player.flash_control(overworld_layers, Color(1.08, 1.12, 1.18, 1.0), 0.09)


func _set_overworld_direction(
	direction: int,
	source_button: Button
) -> void:
	await _motion_player.confirm_control(source_button)
	_overworld_direction = posmod(direction, 4)
	_update_appearance_preview()
	overworld_layers.modulate.a = 0.0
	_motion_player.enter_control(overworld_layers, Vector2.ZERO, 0.1)

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
	error_label.visible = not errors.is_empty()
	if errors.is_empty():
		return
	_motion_player.enter_control(error_label, Vector2(0, -3), 0.13)
	for field: LineEdit in [first_name_edit, last_name_edit, nickname_edit, username_edit]:
		if field.text.strip_edges().is_empty():
			_motion_player.reject_control(field)
			break

func _clear_error() -> void:
	error_label.text = ""
	error_label.hide()

func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func get_current_flow_page() -> int:
	return _current_page


func is_page_transitioning() -> bool:
	return _page_transitioning


func are_assessment_answers_ready() -> bool:
	return _assessment_answers_ready

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
		await _show_page(FlowPage.ASSESSMENT)
		_render_assessment_question(false)
	else:
		await _show_page(restored_page)
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
