extends Control
class_name Desktop


@export_category("Period Presentation")
@export var day_background_color: Color = Color(0.018, 0.047, 0.082, 1.0)
@export var night_background_color: Color = Color(0.006, 0.008, 0.014, 1.0)

@export_category("Time UI Animation (Juice)")
@export var time_pulse_scale: Vector2 = Vector2(1.05, 1.05)
@export var time_tween_duration: float = 0.3

@onready var background: ColorRect = %Background
@onready var clock_container: VBoxContainer = %ClockContainer
@onready var period_label: Label = %PeriodLabel
@onready var day_label: Label = %DayLabel
@onready var month_label: Label = %MonthLabel
@onready var days_passed_label: Label = %DaysPassedLabel
@onready var debug_time_button: Button = %DebugTimeButton


func _ready() -> void:
	add_to_group("desktop")

	debug_time_button.pressed.connect(_on_debug_time_pressed)
	GlobalSignals.time_advanced.connect(_on_time_advanced)

	# Force the first projection from the authoritative TimeManager state.
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

	background.color = (
		night_background_color
		if period == TimeManager.TimePeriod.NIGHT
		else day_background_color
	)
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
