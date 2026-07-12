extends Control
class_name Desktop

@export_category("Time UI Animation (Juice)")
@export var time_pulse_scale: Vector2 = Vector2(1.05, 1.05)
@export var time_tween_duration: float = 0.3

@export_category("Responsive Desktop")
@export var compact_breakpoint: float = 760.0
@export var wide_period_font_size: int = 80
@export var compact_period_font_size: int = 48
@export var wide_date_font_size: int = 40
@export var compact_date_font_size: int = 28
@export var wide_status_font_size: int = 24
@export var compact_status_font_size: int = 19

@onready var clock_container: VBoxContainer = %ClockContainer
@onready var period_label: Label = %PeriodLabel
@onready var day_label: Label = %DayLabel
@onready var month_label: Label = %MonthLabel
@onready var days_passed_label: Label = %DaysPassedLabel

@onready var debug_time_button: Button = %DebugTimeButton
@onready var scale_auto_button: Button = %ScaleAutoButton
@onready var scale_1x_button: Button = %Scale1xButton
@onready var scale_2x_button: Button = %Scale2xButton
@onready var scale_status_label: Label = %ScaleStatusLabel


func _ready() -> void:
	add_to_group("desktop")

	debug_time_button.pressed.connect(_on_debug_time_pressed)
	_connect_display_scale_buttons()
	_refresh_display_scale_debug_ui()
	_apply_responsive_layout()

	if not resized.is_connected(_apply_responsive_layout):
		resized.connect(_apply_responsive_layout)

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	TimeManager._emit_time_signal()


func _on_debug_time_pressed() -> void:
	TimeManager.advance_action()


func _on_time_advanced(
	period: int,
	days_passed: int,
	cal_day: int,
	cal_month: String
) -> void:
	var period_name := TimeManager.get_period_name(period as TimeManager.TimePeriod)
	var current_block := TimeManager.current_action_block
	var total_blocks := TimeManager.ACTION_BLOCKS_PER_PERIOD
	var actions_left := TimeManager.get_actions_left_in_period()

	period_label.text = "%s %d/%d" % [
		period_name,
		current_block + 1,
		total_blocks
	]

	day_label.text = str(cal_day)
	month_label.text = cal_month

	days_passed_label.text = "Dia %d | Ações restantes: %d" % [
		days_passed,
		actions_left
	]

	_animate_time_change()


func _animate_time_change() -> void:
	clock_container.pivot_offset = clock_container.size / 2.0
	clock_container.scale = time_pulse_scale
	clock_container.modulate = Color(1.2, 1.2, 1.5, 1.0)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(
		clock_container,
		"scale",
		Vector2.ONE,
		time_tween_duration
	).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(
		clock_container,
		"modulate",
		Color.WHITE,
		time_tween_duration
	)


func _connect_display_scale_buttons() -> void:
	if not scale_auto_button.pressed.is_connected(_on_scale_auto_pressed):
		scale_auto_button.pressed.connect(_on_scale_auto_pressed)

	if not scale_1x_button.pressed.is_connected(_on_scale_1x_pressed):
		scale_1x_button.pressed.connect(_on_scale_1x_pressed)

	if not scale_2x_button.pressed.is_connected(_on_scale_2x_pressed):
		scale_2x_button.pressed.connect(_on_scale_2x_pressed)

	if not KubuDisplaySetting.display_geometry_changed.is_connected(_on_display_geometry_changed):
		KubuDisplaySetting.display_geometry_changed.connect(_on_display_geometry_changed)


func _on_scale_auto_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.AUTO)
	_refresh_display_scale_debug_ui()


func _on_scale_1x_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.SCALE_1X)
	_refresh_display_scale_debug_ui()


func _on_scale_2x_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.SCALE_2X)
	_refresh_display_scale_debug_ui()


func _on_display_geometry_changed(
	_scale: int,
	_physical_size: Vector2i,
	_logical_size: Vector2i,
	_display_mode: KubuDisplaySetting.DisplayMode
) -> void:
	_refresh_display_scale_debug_ui()
	_apply_responsive_layout()


func _refresh_display_scale_debug_ui() -> void:
	var mode: KubuDisplaySetting.ScaleMode = KubuDisplaySetting.current_scale_mode
	var scale: int = KubuDisplaySetting.get_current_scale()
	var physical_size: Vector2i = KubuDisplaySetting.get_current_physical_size()
	var logical_size: Vector2i = KubuDisplaySetting.get_current_logical_size()

	scale_auto_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.AUTO
	scale_1x_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.SCALE_1X
	scale_2x_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.SCALE_2X

	scale_status_label.text = "%dx | %dx%d -> %dx%d" % [
		scale,
		physical_size.x,
		physical_size.y,
		logical_size.x,
		logical_size.y
	]


func _apply_responsive_layout() -> void:
	var available_width: float = size.x

	if available_width <= 0.0:
		available_width = get_viewport_rect().size.x

	var is_compact: bool = available_width < compact_breakpoint
	period_label.add_theme_font_size_override(
		"font_size",
		compact_period_font_size if is_compact else wide_period_font_size
	)
	day_label.add_theme_font_size_override(
		"font_size",
		compact_date_font_size if is_compact else wide_date_font_size
	)
	month_label.add_theme_font_size_override(
		"font_size",
		compact_date_font_size if is_compact else wide_date_font_size
	)
	days_passed_label.add_theme_font_size_override(
		"font_size",
		compact_status_font_size if is_compact else wide_status_font_size
	)
