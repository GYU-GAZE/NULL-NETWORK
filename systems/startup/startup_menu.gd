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
const BOTTOM_BAR_HEIGHT: float = 56.0
const BOTTOM_BAR_REVEAL_SECONDS: float = 0.3

@export var presentation_data: StartupPresentationData

@onready var null_brand: Control = %NullBrand
@onready var null_logo_root: Control = %NullLogoRoot
@onready var null_logo_texture: TextureRect = %NullLogoTexture
@onready var null_logo_texture_ghost_a: TextureRect = %NullLogoTextureGhostA
@onready var null_logo_texture_ghost_b: TextureRect = %NullLogoTextureGhostB
@onready var null_logo_label: Label = %NullLogoLabel
@onready var null_logo_label_ghost_a: Label = %NullLogoLabelGhostA
@onready var null_logo_label_ghost_b: Label = %NullLogoLabelGhostB
@onready var pixel_field: Control = %PixelField
@onready var user_panel: PanelContainer = %UserPanel
@onready var profile_list: VBoxContainer = %ProfileList
@onready var mode_panel: PanelContainer = %ModePanel
@onready var safe_mode_button: Button = %SafeModeButton
@onready var commit_mode_button: Button = %CommitModeButton
@onready var mode_details: PanelContainer = %ModeDetails
@onready var mode_title: Label = %ModeTitle
@onready var mode_description: RichTextLabel = %ModeDescription
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton
@onready var bottom_bar_root: Control = %BottomBarRoot
@onready var exit_button: Button = %ExitButton
@onready var configs_button: Button = %ConfigsButton
@onready var error_label: Label = %ErrorLabel

var _profiles: Array[Dictionary] = []
var _selected_entry_id: String = ""
var _selected_mode: CampaignState.SaveMode = CampaignState.SaveMode.UNSET
var _rng := RandomNumberGenerator.new()
var _glitch_timer: float = 0.0
var _glitch_wait: float = 0.8
var _glitch_tween: Tween
var _input_enabled: bool = false
var _busy: bool = false


func _ready() -> void:
	_rng.seed = 0x4E554C4C
	safe_mode_button.pressed.connect(
		func() -> void: _select_mode(CampaignState.SaveMode.SAFE)
	)
	commit_mode_button.pressed.connect(
		func() -> void: _select_mode(CampaignState.SaveMode.COMMIT)
	)
	start_button.pressed.connect(_start_new_campaign)
	back_button.pressed.connect(_show_user_list)
	exit_button.pressed.connect(_exit_game)
	configs_button.pressed.connect(_open_configs)
	set_process(false)
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
	if presentation_data == null:
		push_error("StartupMenu requires StartupPresentationData.")
		_set_bottom_bar_resting()
		show()
		_input_enabled = true
		set_process(true)
		return

	show()
	_input_enabled = false
	set_process(false)
	_configure_null_logo()
	await get_tree().process_frame
	await _reveal_bottom_bar()
	await _materialize_null_logo()
	await _reveal_main_controls()
	_input_enabled = true
	set_process(true)
	_schedule_next_glitch()


func set_busy(value: bool) -> void:
	_busy = value
	safe_mode_button.disabled = value
	commit_mode_button.disabled = value
	start_button.disabled = value or _selected_mode == CampaignState.SaveMode.UNSET

	for child: Node in profile_list.get_children():
		if child is StartupUserEntry:
			(child as StartupUserEntry).set_interaction_enabled(not value)


func show_error(message: String) -> void:
	error_label.text = message.strip_edges()
	error_label.visible = not error_label.text.is_empty()


func _process(delta: float) -> void:
	if not _input_enabled or presentation_data == null:
		return

	_glitch_timer -= delta

	if _glitch_timer <= 0.0:
		_play_logo_glitch()
		_schedule_next_glitch()


func _rebuild_profile_list() -> void:
	for child: Node in profile_list.get_children():
		child.queue_free()

	_selected_entry_id = ""

	for profile: Dictionary in _profiles:
		_add_user_entry(profile, true)

	_add_user_entry({
		"campaign_id": NEW_USER_ENTRY_ID,
		"username": "New User",
		"description": "Create a new KubuOS user",
		"avatar_fallback": "+",
		"can_delete": false
	}, false)


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
	entry.set_interaction_enabled(not _busy)


func _on_profile_selected(entry_id: String) -> void:
	if not _input_enabled or _busy:
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
	var clean_id: String = entry_id.strip_edges()

	if clean_id.is_empty() or clean_id != _selected_entry_id:
		return

	if clean_id == NEW_USER_ENTRY_ID:
		_show_new_user_modes()
		return

	_load_profile(clean_id)


func _on_profile_delete_requested(entry_id: String) -> void:
	if not _input_enabled or _busy:
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
	if not _input_enabled or _busy:
		return

	show_error("")
	_clear_profile_selection()
	_selected_mode = CampaignState.SaveMode.UNSET
	user_panel.hide()
	mode_panel.show()
	mode_details.hide()
	safe_mode_button.disabled = false
	commit_mode_button.disabled = false
	start_button.disabled = true


func _show_user_list() -> void:
	if _busy:
		return

	_selected_mode = CampaignState.SaveMode.UNSET
	mode_panel.hide()
	mode_details.hide()
	user_panel.show()
	_clear_profile_selection()
	show_error("")


func _clear_profile_selection() -> void:
	_selected_entry_id = ""

	for child: Node in profile_list.get_children():
		if child is StartupUserEntry:
			(child as StartupUserEntry).set_selected(false)


func _select_mode(mode: CampaignState.SaveMode) -> void:
	if not _input_enabled or _busy:
		return

	if mode not in [CampaignState.SaveMode.SAFE, CampaignState.SaveMode.COMMIT]:
		return

	_selected_mode = mode
	var is_commit: bool = mode == CampaignState.SaveMode.COMMIT
	mode_title.text = "COMMIT MODE" if is_commit else "SAFE MODE"
	mode_description.text = (
		"One living record. Manual rollback and visible checkpoint history are disabled. "
		+ "Irreversible events overwrite the current record."
		if is_commit
		else
		"Historical checkpoints and manual saves remain available. You can return to an "
		+ "earlier record when you choose to do so."
	)
	start_button.disabled = false

	if not mode_details.visible:
		mode_details.show()
		mode_details.custom_minimum_size.y = 0.0
		mode_details.modulate.a = 0.0
		await get_tree().process_frame
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(mode_details, "custom_minimum_size:y", 154.0, 0.22)
		tween.parallel().tween_property(mode_details, "modulate:a", 1.0, 0.16)


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


func _configure_null_logo() -> void:
	var texture: Texture2D = presentation_data.null_network_logo_texture
	var has_texture: bool = texture != null

	for node: TextureRect in [
		null_logo_texture,
		null_logo_texture_ghost_a,
		null_logo_texture_ghost_b
	]:
		node.texture = texture
		node.visible = has_texture

	for node: Label in [
		null_logo_label,
		null_logo_label_ghost_a,
		null_logo_label_ghost_b
	]:
		node.text = presentation_data.null_network_fallback_text
		node.visible = not has_texture

	null_logo_label.add_theme_color_override(
		"font_color",
		presentation_data.null_logo_text_color
	)
	null_logo_label_ghost_a.add_theme_color_override(
		"font_color",
		presentation_data.null_logo_glitch_color_a
	)
	null_logo_label_ghost_b.add_theme_color_override(
		"font_color",
		presentation_data.null_logo_glitch_color_b
	)
	null_logo_texture_ghost_a.modulate = presentation_data.null_logo_glitch_color_a
	null_logo_texture_ghost_b.modulate = presentation_data.null_logo_glitch_color_b
	_reset_logo_glitch()


func _set_bottom_bar_hidden() -> void:
	bottom_bar_root.offset_top = 0.0
	bottom_bar_root.offset_bottom = BOTTOM_BAR_HEIGHT


func _set_bottom_bar_resting() -> void:
	bottom_bar_root.offset_top = -BOTTOM_BAR_HEIGHT
	bottom_bar_root.offset_bottom = 0.0


func _reveal_bottom_bar() -> void:
	_set_bottom_bar_hidden()
	bottom_bar_root.modulate.a = 0.82
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		bottom_bar_root,
		"offset_top",
		-BOTTOM_BAR_HEIGHT,
		BOTTOM_BAR_REVEAL_SECONDS
	)
	tween.parallel().tween_property(
		bottom_bar_root,
		"offset_bottom",
		0.0,
		BOTTOM_BAR_REVEAL_SECONDS
	)
	tween.parallel().tween_property(
		bottom_bar_root,
		"modulate:a",
		1.0,
		BOTTOM_BAR_REVEAL_SECONDS * 0.72
	)
	await tween.finished


func _materialize_null_logo() -> void:
	null_brand.show()
	null_logo_root.modulate.a = 0.0
	_clear_pixels()
	var duration: float = presentation_data.null_logo_build_seconds
	var particle_count: int = presentation_data.null_logo_particle_count
	var target_rect := Rect2(Vector2.ZERO, null_logo_root.size)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	for index in range(particle_count):
		var pixel := ColorRect.new()
		var pixel_size: float = _rng.randf_range(2.0, 5.0)
		pixel.size = Vector2(pixel_size, pixel_size)
		pixel.color = (
			presentation_data.null_logo_glitch_color_a
			if index % 2 == 0
			else presentation_data.null_logo_glitch_color_b
		)
		pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pixel.position = Vector2(
			_rng.randf_range(-90.0, target_rect.size.x + 90.0),
			_rng.randf_range(-55.0, target_rect.size.y + 55.0)
		)
		pixel_field.add_child(pixel)
		var target := Vector2(
			_rng.randf_range(12.0, maxf(13.0, target_rect.size.x - 12.0)),
			_rng.randf_range(10.0, maxf(11.0, target_rect.size.y - 10.0))
		)
		tween.parallel().tween_property(pixel, "position", target, duration)
		tween.parallel().tween_property(pixel, "modulate:a", 0.15, duration)

	tween.parallel().tween_property(null_logo_root, "modulate:a", 1.0, duration * 0.72)
	await tween.finished
	_clear_pixels()
	_play_logo_glitch()


func _reveal_main_controls() -> void:
	user_panel.show()
	mode_panel.hide()
	user_panel.pivot_offset = user_panel.size * 0.5
	user_panel.scale = Vector2(1.0, 0.02)
	user_panel.modulate.a = 0.38
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(user_panel, "scale:y", 1.0, 0.34)
	tween.parallel().tween_property(user_panel, "modulate:a", 1.0, 0.22)
	await tween.finished


func _play_logo_glitch() -> void:
	if _glitch_tween != null and _glitch_tween.is_valid():
		return

	var offset_a := Vector2(_rng.randi_range(-4, 4), _rng.randi_range(-1, 1))
	var offset_b := Vector2(_rng.randi_range(-4, 4), _rng.randi_range(-1, 1))
	null_logo_root.position.x = float(_rng.randi_range(-2, 2))
	null_logo_texture_ghost_a.position = offset_a
	null_logo_texture_ghost_b.position = offset_b
	null_logo_label_ghost_a.position = offset_a
	null_logo_label_ghost_b.position = offset_b
	null_logo_texture_ghost_a.modulate.a = 0.48
	null_logo_texture_ghost_b.modulate.a = 0.42
	null_logo_label_ghost_a.modulate.a = 0.7
	null_logo_label_ghost_b.modulate.a = 0.65
	_glitch_tween = create_tween()
	_glitch_tween.tween_interval(0.055)
	_glitch_tween.tween_callback(_reset_logo_glitch)


func _reset_logo_glitch() -> void:
	null_logo_root.position = Vector2.ZERO
	null_logo_texture_ghost_a.position = Vector2.ZERO
	null_logo_texture_ghost_b.position = Vector2.ZERO
	null_logo_label_ghost_a.position = Vector2.ZERO
	null_logo_label_ghost_b.position = Vector2.ZERO
	null_logo_texture_ghost_a.modulate.a = 0.0
	null_logo_texture_ghost_b.modulate.a = 0.0
	null_logo_label_ghost_a.modulate.a = 0.0
	null_logo_label_ghost_b.modulate.a = 0.0
	_glitch_tween = null


func _schedule_next_glitch() -> void:
	_glitch_timer = _rng.randf_range(0.65, 1.7)


func _clear_pixels() -> void:
	for child: Node in pixel_field.get_children():
		child.queue_free()


func _open_configs() -> void:
	if not _input_enabled or _busy:
		return

	GlobalSignals.request_open_system_settings.emit()


func _exit_game() -> void:
	if _input_enabled and not _busy:
		get_tree().quit()


func _reset_visual_state() -> void:
	hide()
	null_brand.hide()
	user_panel.hide()
	mode_panel.hide()
	mode_details.hide()
	show_error("")
	_set_bottom_bar_hidden()
	bottom_bar_root.modulate.a = 1.0
	_selected_entry_id = ""
	_selected_mode = CampaignState.SaveMode.UNSET
	_input_enabled = false
