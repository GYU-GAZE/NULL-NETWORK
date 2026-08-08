extends CanvasLayer
class_name KubuSystemSettingsDialog


@onready var root: Control = %Root
@onready var panel: PanelContainer = %Panel
@onready var display_mode_select: OptionButton = %DisplayModeSelect
@onready var apply_button: Button = %ApplyButton
@onready var close_button: Button = %CloseButton

var _input_enabled: bool = false


func _ready() -> void:
	if not GlobalSignals.request_open_system_settings.is_connected(open):
		GlobalSignals.request_open_system_settings.connect(open)

	apply_button.pressed.connect(_apply_display_config)
	close_button.pressed.connect(close)
	root.hide()


func open() -> void:
	_refresh_display_modes()
	root.show()
	_input_enabled = false
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.96, 0.96)
	panel.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.16)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.12)
	await tween.finished
	_input_enabled = true


func close() -> void:
	if not root.visible:
		return

	_input_enabled = false
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "scale", Vector2(0.98, 0.98), 0.1)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.08)
	await tween.finished
	root.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible or not _input_enabled:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _refresh_display_modes() -> void:
	display_mode_select.clear()
	display_mode_select.add_item("Windowed", KubuDisplaySettings.DisplayMode.WINDOWED)
	display_mode_select.add_item(
		"Borderless Fullscreen",
		KubuDisplaySettings.DisplayMode.BORDERLESS_FULLSCREEN
	)
	display_mode_select.add_item(
		"Exclusive Fullscreen",
		KubuDisplaySettings.DisplayMode.EXCLUSIVE_FULLSCREEN
	)

	var current_mode: int = int(KubuDisplaySetting.get_current_display_mode())
	for index in range(display_mode_select.item_count):
		if display_mode_select.get_item_id(index) == current_mode:
			display_mode_select.select(index)
			break


func _apply_display_config() -> void:
	if display_mode_select.selected < 0:
		return

	var mode: int = display_mode_select.get_item_id(display_mode_select.selected)
	KubuDisplaySetting.set_display_mode(mode as KubuDisplaySettings.DisplayMode)
