extends Node
class_name SiteActionBinding

signal availability_changed(available: bool)
signal action_executed(result: Dictionary)

enum FailedConditionBehavior { DO_NOTHING, DISABLE_BUTTON, HIDE_BUTTON }

@export var action_data: SiteActionData
@export var failed_condition_behavior: FailedConditionBehavior = FailedConditionBehavior.DO_NOTHING
@export var connect_input: bool = true
var available: bool = false
var refresh_count: int = 0
var _dependencies: Dictionary = {}
var _target: Control
var _authored_visible: bool = true
var _authored_disabled: bool = false


func _ready() -> void:
	_target = get_parent() as Control
	if _target == null or action_data == null:
		return
	_authored_visible = _target.visible
	_authored_disabled = (_target as BaseButton).disabled if _target is BaseButton else false
	if action_data.conditions != null:
		_dependencies = action_data.conditions.get_change_dependencies()
	GameState.flag_changed.connect(_on_flag_changed)
	GameState.number_changed.connect(_on_number_changed)
	CampaignState.campaign_changed.connect(_on_campaign_changed)
	if bool(_dependencies.get("time", false)):
		GlobalSignals.time_advanced.connect(_on_time_changed)
	if connect_input:
		if _target is BaseButton:
			(_target as BaseButton).pressed.connect(trigger)
		else:
			_target.focus_mode = Control.FOCUS_ALL
			_target.mouse_filter = Control.MOUSE_FILTER_STOP
			_target.gui_input.connect(_on_gui_input)
	refresh()


func trigger() -> Dictionary:
	var result := SiteActionRunner.execute(action_data, _target)
	action_executed.emit(result)
	return result


func refresh() -> void:
	if not is_instance_valid(_target) or action_data == null:
		return
	refresh_count += 1
	available = action_data.is_available(SiteActionRunner.create_context(_target, action_data))
	if _target is BaseButton and failed_condition_behavior == FailedConditionBehavior.DISABLE_BUTTON:
		(_target as BaseButton).disabled = _authored_disabled or not available
	if failed_condition_behavior == FailedConditionBehavior.HIDE_BUTTON:
		_target.visible = _authored_visible and available
	availability_changed.emit(available)


func _on_flag_changed(key: String, _value: bool) -> void:
	if key in _dependencies.get("flags", []):
		refresh()


func _on_number_changed(key: String, _value: int) -> void:
	if key in _dependencies.get("numbers", []):
		refresh()


func _on_campaign_changed(section: StringName) -> void:
	if section == &"campaign" or String(section) in _dependencies.get("sections", []):
		refresh()


func _on_time_changed(_period: int, _days: int, _day: int, _month: String) -> void:
	refresh()


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		if not available and failed_condition_behavior != FailedConditionBehavior.DO_NOTHING:
			return
		trigger()
		_target.accept_event()
