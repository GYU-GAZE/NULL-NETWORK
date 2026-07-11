extends Control
class_name Desktop

@export_category("Time UI Animation (Juice)")
@export var time_pulse_scale: Vector2 = Vector2(1.05, 1.05)
@export var time_tween_duration: float = 0.3

@onready var clock_container: VBoxContainer = %ClockContainer
@onready var period_label: Label = %PeriodLabel
@onready var day_label: Label = %DayLabel
@onready var month_label: Label = %MonthLabel
@onready var days_passed_label: Label = %DaysPassedLabel

@onready var debug_time_button: Button = %DebugTimeButton
@onready var scale_auto_button: Button = %ScaleAutoButton
@onready var scale_1x_button: Button = %Scale1xButton
@onready var scale_2x_button: Button = %Scale2xButton
@onready var scale_3x_button: Button = %Scale3xButton
@onready var scale_4x_button: Button = %Scale4xButton
@onready var scale_status_label: Label = %ScaleStatusLabel

func _ready() -> void:
	add_to_group("desktop")

	debug_time_button.pressed.connect(_on_debug_time_pressed)

	_connect_display_scale_buttons()
	_refresh_display_scale_debug_ui()

	GlobalSignals.time_advanced.connect(_on_time_advanced)
	
	# Força a primeira atualização usando as variáveis diretamente do Autoload
	TimeManager._emit_time_signal()


func _on_debug_time_pressed() -> void:
	TimeManager.advance_action()

# Recebe os dados destrinchados do sinal global
func _on_time_advanced(period: int, days_passed: int, cal_day: int, cal_month: String) -> void:
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

# O Juice (Game Feel) aplicado no container inteiro
func _animate_time_change() -> void:
	clock_container.pivot_offset = clock_container.size / 2.0
	clock_container.scale = time_pulse_scale
	clock_container.modulate = Color(1.2, 1.2, 1.5, 1.0) # Leve brilho azulado
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(clock_container, "scale", Vector2.ONE, time_tween_duration).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(clock_container, "modulate", Color.WHITE, time_tween_duration)

func _connect_display_scale_buttons() -> void:
	if not scale_auto_button.pressed.is_connected(_on_scale_auto_pressed):
		scale_auto_button.pressed.connect(_on_scale_auto_pressed)

	if not scale_1x_button.pressed.is_connected(_on_scale_1x_pressed):
		scale_1x_button.pressed.connect(_on_scale_1x_pressed)

	if not scale_2x_button.pressed.is_connected(_on_scale_2x_pressed):
		scale_2x_button.pressed.connect(_on_scale_2x_pressed)

	if not scale_3x_button.pressed.is_connected(_on_scale_3x_pressed):
		scale_3x_button.pressed.connect(_on_scale_3x_pressed)

	if not scale_4x_button.pressed.is_connected(_on_scale_4x_pressed):
		scale_4x_button.pressed.connect(_on_scale_4x_pressed)

	if not KubuDisplaySetting.display_scale_changed.is_connected(_on_display_scale_changed):
		KubuDisplaySetting.display_scale_changed.connect(_on_display_scale_changed)


func _on_scale_auto_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.AUTO)
	_refresh_display_scale_debug_ui()


func _on_scale_1x_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.SCALE_1X)
	_refresh_display_scale_debug_ui()


func _on_scale_2x_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.SCALE_2X)
	_refresh_display_scale_debug_ui()


func _on_scale_3x_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.SCALE_3X)
	_refresh_display_scale_debug_ui()


func _on_scale_4x_pressed() -> void:
	KubuDisplaySetting.set_scale_mode(KubuDisplaySetting.ScaleMode.SCALE_4X)
	_refresh_display_scale_debug_ui()


func _on_display_scale_changed(_scale: int, _physical_size: Vector2i) -> void:
	_refresh_display_scale_debug_ui()


func _refresh_display_scale_debug_ui() -> void:
	var mode: KubuDisplaySetting.ScaleMode = KubuDisplaySetting.current_scale_mode
	var scale: int = KubuDisplaySetting.get_current_scale()
	var physical_size: Vector2i = KubuDisplaySetting.get_current_physical_size()

	scale_auto_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.AUTO
	scale_1x_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.SCALE_1X
	scale_2x_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.SCALE_2X
	scale_3x_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.SCALE_3X
	scale_4x_button.button_pressed = mode == KubuDisplaySetting.ScaleMode.SCALE_4X

	scale_status_label.text = "Scale: %dx | %dx%d" % [
		scale,
		physical_size.x,
		physical_size.y
	]
