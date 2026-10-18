extends PanelContainer
class_name KubuSystemSettingsPanel

@onready var display_mode_select: OptionButton = %DisplayModeSelect
@onready var window_size_select: OptionButton = %WindowSizeSelect
@onready var apply_button: Button = %ApplyButton
@onready var logout_button: Button = %LogoutButton
@onready var status_label: Label = %StatusLabel
@onready var current_time_label: Label = %CurrentTimeLabel
@onready var advance_hour_button: Button = %AdvanceHourButton
@onready var next_day_button: Button = %NextDayButton
@onready var time_status_label: Label = %TimeStatusLabel


func _ready() -> void:
	apply_button.pressed.connect(_apply_display_config)
	logout_button.pressed.connect(GlobalSignals.request_logout.emit)
	_refresh_display_modes()
	_refresh_window_sizes()
	_refresh_status()
	advance_hour_button.pressed.connect(func() -> void: _advance_development_time(1))
	next_day_button.pressed.connect(func() -> void: _advance_development_time(24))
	TimeManager.development_time_state_changed.connect(_refresh_time_controls)
	GlobalSignals.time_advanced.connect(func(_period: int, _days: int, _day: int, _month: String) -> void: _refresh_time_controls())
	var refresh := Timer.new()
	refresh.wait_time = 0.25
	refresh.timeout.connect(_refresh_time_controls)
	add_child(refresh)
	refresh.start()
	_refresh_time_controls()

func _refresh_time_controls() -> void:
	current_time_label.text = "%02d %s %d // %s %s // BLOCK %d/12" % [TimeManager.current_calendar_day, TimeManager.MONTH_NAMES[TimeManager.current_month_index], TimeManager.current_year, TimeManager.get_current_period_name(), TimeManager.format_action_block_hour(TimeManager.current_period, TimeManager.current_action_block), TimeManager.current_action_block + 1]
	var denial := TimeManager.development_time_denial_reason()
	advance_hour_button.disabled = not denial.is_empty()
	next_day_button.disabled = not denial.is_empty()
	advance_hour_button.tooltip_text = denial
	next_day_button.tooltip_text = denial

func _advance_development_time(hours: int) -> void:
	time_status_label.text = "DEVELOPMENT: processing intermediate hours..."
	var result := await TimeManager.advance_development_hours(hours)
	time_status_label.text = "QA advanced %d hour(s). %s" % [int(result.advanced), str(result.reason)]
	_refresh_time_controls()


func _refresh_display_modes() -> void:
	display_mode_select.clear()
	display_mode_select.add_item("WINDOWED", KubuDisplaySettings.DisplayMode.WINDOWED)
	display_mode_select.add_item("BORDERLESS FULLSCREEN", KubuDisplaySettings.DisplayMode.BORDERLESS_FULLSCREEN)
	display_mode_select.add_item("EXCLUSIVE FULLSCREEN", KubuDisplaySettings.DisplayMode.EXCLUSIVE_FULLSCREEN)
	var current_mode: int = int(KubuDisplaySetting.get_current_display_mode())
	for index in range(display_mode_select.item_count):
		if display_mode_select.get_item_id(index) == current_mode:
			display_mode_select.select(index)
			break


func _refresh_window_sizes() -> void:
	window_size_select.clear()
	var sizes: Array[Vector2i] = [
		Vector2i(960, 540), Vector2i(1280, 720),
		Vector2i(1600, 900), Vector2i(1920, 1080),
	]
	var current_size := KubuDisplaySetting.get_current_physical_size()
	var selected_index := 0
	for index in range(sizes.size()):
		var option_size := sizes[index]
		window_size_select.add_item(
			"%d × %d  //  %d × %d LOGICAL" % [
				option_size.x, option_size.y,
				option_size.x / 2, option_size.y / 2,
			], index
		)
		window_size_select.set_item_metadata(index, option_size)
		if option_size == current_size:
			selected_index = index
	window_size_select.select(selected_index)


func _apply_display_config() -> void:
	if display_mode_select.selected < 0:
		return
	if window_size_select.selected >= 0:
		var selected_size: Variant = window_size_select.get_item_metadata(window_size_select.selected)
		if selected_size is Vector2i:
			KubuDisplaySetting.set_windowed_size(selected_size as Vector2i)
	var mode: int = display_mode_select.get_item_id(display_mode_select.selected)
	KubuDisplaySetting.set_display_mode(mode as KubuDisplaySettings.DisplayMode)
	_refresh_status()
	_play_applied_feedback()


func _refresh_status() -> void:
	status_label.text = "LOCKED INTEGER PIPELINE  //  2×  //  NEAREST FILTER"


func _play_applied_feedback() -> void:
	status_label.modulate = Color(0.45, 1.0, 0.78, 1.0)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(status_label, "modulate", Color.WHITE, 0.28)
