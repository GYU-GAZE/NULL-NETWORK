extends Button
class_name CalendarDayButton


signal day_selected(game_day: int)


var game_day: int = -1


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func setup(day: Dictionary) -> void:
	game_day = int(day.get("game_day", -1))
	text = "%s  %02d/%02d\n%s  ·  %d FREE" % [
		str(day.get("weekday_name", "---")),
		int(day.get("calendar_day", 1)),
		int(day.get("month", 1)),
		"TODAY" if bool(day.get("is_today", false)) else "DAY %d" % game_day,
		int(day.get("remaining_free_blocks", 0))
	]


func set_selected(selected: bool) -> void:
	button_pressed = selected


func _on_pressed() -> void:
	if game_day >= 0:
		day_selected.emit(game_day)
