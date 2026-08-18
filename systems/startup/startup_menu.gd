extends Control
class_name StartupMenu


signal campaign_load_requested(campaign_id: String, checkpoint_file_id: String)
signal campaign_create_requested(
	campaign_id: String,
	display_name: String,
	save_mode: CampaignState.SaveMode
)
signal campaign_delete_requested(campaign_id: String)


const STARTUP_USER_ENTRY_SCENE: PackedScene = preload(
	"res://systems/startup/startup_user_entry.tscn"
)
const NEW_USER_ENTRY_ID: String = "__new_user__"
const BOTTOM_BAR_HEIGHT: float = 40.0
const BOTTOM_BAR_REVEAL_SECONDS: float = 0.18
const SAFE_MODE_DESCRIPTION: String = (
	"Historical checkpoints and manual saves remain available. You can return to an "
	+ "earlier record when you choose to do so."
)
const COMMIT_MODE_DESCRIPTION: String = (
	"One living record. Manual rollback and visible checkpoint history are disabled. "
	+ "Irreversible events overwrite the current record."
)

@export var presentation_data: StartupPresentationData

@onready var motion_player: UiMotionPlayer = %MotionPlayer
@onready var account_surface: PanelContainer = %AccountSurface
@onready var user_panel: PanelContainer = %UserPanel
@onready var profile_list: VBoxContainer = %ProfileList
@onready var mode_panel: PanelContainer = %ModePanel
@onready var mode_scroll: ScrollContainer = %ModeScroll
@onready var new_user_title: Label = %NewUserTitle
@onready var mode_hint: Label = %ModeHint
@onready var safe_mode_option: StartupModeOption = %SafeModeOption
@onready var commit_mode_option: StartupModeOption = %CommitModeOption
@onready var back_button: Button = %BackButton
@onready var bottom_bar_root: Control = %BottomBarRoot
@onready var exit_button: Button = %ExitButton
@onready var configs_button: Button = %ConfigsButton
@onready var error_label: Label = %ErrorLabel

var _profiles: Array[Dictionary] = []
var _selected_entry_id: String = ""
var _selected_mode: CampaignState.SaveMode = CampaignState.SaveMode.UNSET
var _input_enabled: bool = false
var _busy: bool = false
var _surface_transitioning: bool = false


func _ready() -> void:
	safe_mode_option.configure(
		CampaignState.SaveMode.SAFE,
		"SAFE MODE",
		SAFE_MODE_DESCRIPTION
	)
	commit_mode_option.configure(
		CampaignState.SaveMode.COMMIT,
		"COMMIT MODE",
		COMMIT_MODE_DESCRIPTION
	)

	for option: StartupModeOption in _get_mode_options():
		option.toggle_requested.connect(_on_mode_toggle_requested)
		option.start_requested.connect(_on_mode_start_requested)

	back_button.pressed.connect(_show_user_list)
	exit_button.pressed.connect(_exit_game)
	configs_button.pressed.connect(_open_configs)
	_reset_visual_state()


func refresh_profiles() -> int:
	_profiles = CampaignPreviewRepository.list_profiles(SaveManager.storage_root)
	_rebuild_profile_list()

	if _profiles.is_empty():
		return TimeManager.TimePeriod.DAY

	return int(
		_profiles[0].get("current_period", TimeManager.TimePeriod.DAY)
	)


func reveal() -> void:
	_prepare_user_surface()
	show()
	_input_enabled = false
	await get_tree().process_frame
	await _reveal_main_controls()
	await get_tree().create_timer(0.04).timeout
	await _reveal_bottom_bar()
	_input_enabled = true


func set_busy(value: bool) -> void:
	_busy = value
	back_button.disabled = value or _surface_transitioning
	_set_mode_options_enabled(not value and not _surface_transitioning)
	_set_user_entries_enabled(not value and not _surface_transitioning)


func show_error(message: String) -> void:
	error_label.text = message.strip_edges()
	error_label.visible = not error_label.text.is_empty()


func _rebuild_profile_list() -> void:
	for child: Node in profile_list.get_children():
		child.queue_free()

	_selected_entry_id = ""

	for profile: Dictionary in _profiles:
		_add_user_entry(_prepare_saved_profile_for_entry(profile), true)

	_add_user_entry({
		"campaign_id": NEW_USER_ENTRY_ID,
		"username": "New User",
		"description": "Create a new KubuOS user",
		"avatar_fallback": "+",
		"can_delete": false
	}, false)


func _prepare_saved_profile_for_entry(profile: Dictionary) -> Dictionary:
	var result: Dictionary = profile.duplicate(true)
	var occupation_id: String = str(
		profile.get("occupation_id", "")
	).strip_edges()
	var occupation_label: String = ""

	if not occupation_id.is_empty():
		var occupation: OccupationData = ContentRegistry.get_occupation(occupation_id)

		if occupation != null:
			occupation_label = occupation.get_display_name().strip_edges()
		else:
			# Old or content-mismatched saves still expose their persisted ID rather
			# than silently losing the occupation field on the login surface.
			occupation_label = occupation_id.replace("_", " ").capitalize()

	var mode_value: int = int(
		profile.get("save_mode", CampaignState.SaveMode.UNSET)
	)
	var mode_label: String = "UNSET"

	if mode_value == CampaignState.SaveMode.SAFE:
		mode_label = "SAFE"
	elif mode_value == CampaignState.SaveMode.COMMIT:
		mode_label = "COMMIT"

	var description_parts: Array[String] = []

	if not occupation_label.is_empty():
		description_parts.append(occupation_label)

	description_parts.append("%s MODE" % mode_label)
	description_parts.append("Day %d" % maxi(1, int(profile.get("days_passed", 1))))
	result["description"] = " · ".join(description_parts)
	return result


func _add_user_entry(profile: Dictionary, show_separator: bool) -> void:
	var entry := STARTUP_USER_ENTRY_SCENE.instantiate() as StartupUserEntry

	if entry == null:
		push_error("StartupMenu could not instantiate StartupUserEntry.")
		return

	profile_list.add_child(entry)
	entry.configure(profile)
	entry.set_separator_visible(show_separator)
	entry.selected.connect(_on_profile_selected)
	entry.activated.connect(_on_profile_activated)
	entry.delete_requested.connect(_on_profile_delete_requested)
	entry.set_interaction_enabled(not _busy and not _surface_transitioning)


func _on_profile_selected(entry_id: String) -> void:
	if not _input_enabled or _busy or _surface_transitioning:
		return

	var clean_id: String = entry_id.strip_edges()

	if clean_id.is_empty():
		return

	_selected_entry_id = clean_id
	show_error("")

	for child: Node in profile_list.get_children():
		if child is StartupUserEntry:
			var entry := child as StartupUserEntry
			entry.set_selected(entry.campaign_id == clean_id)


func _on_profile_activated(entry_id: String) -> void:
	if _surface_transitioning:
		return

	var clean_id: String = entry_id.strip_edges()

	if clean_id.is_empty() or clean_id != _selected_entry_id:
		return

	if clean_id == NEW_USER_ENTRY_ID:
		_show_new_user_modes()
		return

	_load_profile(clean_id)


func _on_profile_delete_requested(entry_id: String) -> void:
	if not _input_enabled or _busy or _surface_transitioning:
		return

	var clean_id: String = entry_id.strip_edges()

	if (
		clean_id.is_empty()
		or clean_id == NEW_USER_ENTRY_ID
		or clean_id != _selected_entry_id
	):
		return

	show_error("")
	campaign_delete_requested.emit(clean_id)


func _load_profile(campaign_id: String) -> void:
	if not _input_enabled or _busy or campaign_id.strip_edges().is_empty():
		return

	show_error("")
	campaign_load_requested.emit(campaign_id.strip_edges(), "")


func _show_new_user_modes() -> void:
	if not _input_enabled or _busy or _surface_transitioning:
		return

	_surface_transitioning = true
	_set_user_entries_enabled(false)
	_set_mode_options_enabled(false)
	show_error("")
	_clear_profile_selection()
	_selected_mode = CampaignState.SaveMode.UNSET
	back_button.disabled = true

	for option: StartupModeOption in _get_mode_options():
		option.reset_immediately()

	var staged_controls: Array[Control] = [
		back_button,
		new_user_title,
		mode_hint,
		safe_mode_option,
		commit_mode_option,
	]
	for control: Control in staged_controls:
		control.modulate.a = 0.0

	mode_scroll.scroll_vertical = 0
	await motion_player.transition_between(user_panel, mode_panel, true)
	await motion_player.reveal_group_staggered(staged_controls, Vector2(0, 4))

	_surface_transitioning = false
	_set_mode_options_enabled(true)
	back_button.disabled = false


func _show_user_list() -> void:
	if _busy or _surface_transitioning:
		return

	_surface_transitioning = true
	_set_mode_options_enabled(false)
	back_button.disabled = true

	_selected_mode = CampaignState.SaveMode.UNSET
	for option: StartupModeOption in _get_mode_options():
		option.reset_immediately()

	_clear_profile_selection()
	show_error("")
	await motion_player.transition_between(mode_panel, user_panel, false)

	_surface_transitioning = false
	_set_user_entries_enabled(true)


func _clear_profile_selection() -> void:
	_selected_entry_id = ""

	for child: Node in profile_list.get_children():
		if child is StartupUserEntry:
			(child as StartupUserEntry).set_selected(false)


func _set_user_entries_enabled(value: bool) -> void:
	for child: Node in profile_list.get_children():
		if child is StartupUserEntry:
			(child as StartupUserEntry).set_interaction_enabled(value)


func _get_mode_options() -> Array[StartupModeOption]:
	var result: Array[StartupModeOption] = [
		safe_mode_option,
		commit_mode_option
	]
	return result


func _set_mode_options_enabled(value: bool) -> void:
	for option: StartupModeOption in _get_mode_options():
		option.set_interaction_enabled(value)


func _on_mode_toggle_requested(mode_value: int) -> void:
	if not _input_enabled or _busy or _surface_transitioning:
		return

	var target: StartupModeOption
	var other: StartupModeOption
	var target_mode: CampaignState.SaveMode

	match mode_value:
		CampaignState.SaveMode.SAFE:
			target = safe_mode_option
			other = commit_mode_option
			target_mode = CampaignState.SaveMode.SAFE
		CampaignState.SaveMode.COMMIT:
			target = commit_mode_option
			other = safe_mode_option
			target_mode = CampaignState.SaveMode.COMMIT
		_:
			return

	_surface_transitioning = true
	_set_mode_options_enabled(false)
	back_button.disabled = true

	if target.is_expanded():
		await target.set_expanded(false)
		_selected_mode = CampaignState.SaveMode.UNSET
	else:
		if other.is_expanded():
			await other.set_expanded(false)

		_selected_mode = target_mode
		await target.set_expanded(true)

	await get_tree().process_frame
	mode_scroll.ensure_control_visible(target)

	_surface_transitioning = false
	_set_mode_options_enabled(true)
	back_button.disabled = false


func _on_mode_start_requested(mode_value: int) -> void:
	if not _input_enabled or _busy or _surface_transitioning:
		return

	if mode_value != int(_selected_mode):
		return

	_start_new_campaign()


func _start_new_campaign() -> void:
	if not _input_enabled or _busy or _selected_mode == CampaignState.SaveMode.UNSET:
		return

	var campaign_id: String = _generate_campaign_id()
	campaign_create_requested.emit(campaign_id, "New User", _selected_mode)


func _generate_campaign_id() -> String:
	var timestamp: int = int(Time.get_unix_time_from_system())
	var suffix: int = int(Time.get_ticks_usec() % 1000000)
	var candidate: String = "user_%d_%06d" % [timestamp, suffix]

	while SaveManager.campaign_exists(candidate):
		suffix += 1
		candidate = "user_%d_%06d" % [timestamp, suffix]

	return SaveConstants.sanitize_identifier(candidate)


func _set_bottom_bar_hidden() -> void:
	bottom_bar_root.offset_top = 0.0
	bottom_bar_root.offset_bottom = BOTTOM_BAR_HEIGHT


func _set_bottom_bar_resting() -> void:
	bottom_bar_root.offset_top = -BOTTOM_BAR_HEIGHT
	bottom_bar_root.offset_bottom = 0.0


func _reveal_bottom_bar() -> void:
	_set_bottom_bar_resting()
	await motion_player.enter_control(
		bottom_bar_root,
		Vector2(0, BOTTOM_BAR_HEIGHT),
		BOTTOM_BAR_REVEAL_SECONDS
	)


func _reveal_main_controls() -> void:
	account_surface.hide()
	user_panel.hide()
	motion_player.enter_control(account_surface, Vector2(0, 8), 0.18)
	await get_tree().create_timer(0.04).timeout
	await motion_player.enter_control(user_panel, Vector2(6, 0), 0.16)


func _open_configs() -> void:
	if not _input_enabled or _busy:
		return

	GlobalSignals.request_open_system_settings.emit()


func _exit_game() -> void:
	if _input_enabled and not _busy:
		get_tree().quit()


func _reset_visual_state() -> void:
	hide()
	user_panel.hide()
	mode_panel.hide()
	for option: StartupModeOption in _get_mode_options():
		option.reset_immediately()

	account_surface.scale = Vector2.ONE
	account_surface.modulate.a = 1.0
	show_error("")
	_set_bottom_bar_hidden()
	bottom_bar_root.modulate.a = 1.0
	_selected_entry_id = ""
	_selected_mode = CampaignState.SaveMode.UNSET
	_input_enabled = false
	_surface_transitioning = false


func _prepare_user_surface() -> void:
	mode_panel.hide()
	mode_panel.modulate.a = 1.0
	user_panel.show()
	user_panel.modulate.a = 1.0
	account_surface.show()
	account_surface.modulate.a = 1.0
	for option: StartupModeOption in _get_mode_options():
		option.reset_immediately()
	_clear_profile_selection()
	_selected_mode = CampaignState.SaveMode.UNSET
	mode_scroll.scroll_vertical = 0
	show_error("")
	_set_bottom_bar_hidden()
