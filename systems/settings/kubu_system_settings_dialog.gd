extends PanelContainer
class_name KubuSystemSettingsPanel

@onready var display_mode_select: OptionButton = %DisplayModeSelect
@onready var window_size_select: OptionButton = %WindowSizeSelect
@onready var apply_button: Button = %ApplyButton
@onready var logout_button: Button = %LogoutButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	apply_button.pressed.connect(_apply_display_config)
	logout_button.pressed.connect(GlobalSignals.request_logout.emit)
	_refresh_display_modes()
	_refresh_window_sizes()
	_refresh_status()


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
	status_label.pivot_offset = status_label.size * 0.5
	status_label.scale = Vector2(1.04, 1.0)
	status_label.modulate = Color(0.45, 1.0, 0.78, 1.0)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(status_label, "scale", Vector2.ONE, 0.18)
	tween.tween_property(status_label, "modulate", Color.WHITE, 0.28)
