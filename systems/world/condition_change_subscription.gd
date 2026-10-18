extends Node
class_name ConditionChangeSubscription

## A scoped signal subscription, not another condition evaluator/state store.
signal changed
var _flags: Array[String] = []
var _numbers: Array[String] = []
var _sections: Array[String] = []
var _time: bool = false
var _queued: bool = false


func _ready() -> void:
	GameState.flag_changed.connect(_on_flag)
	GameState.number_changed.connect(_on_number)
	CampaignState.campaign_changed.connect(_on_campaign)
	GlobalSignals.time_advanced.connect(_on_time)


func configure(conditions: Array[ConditionRuleData], flags: Array[String] = [], sections: Array[String] = [], observe_time: bool = false) -> void:
	_flags = flags.duplicate()
	_numbers.clear()
	_sections = sections.duplicate()
	_time = observe_time
	for condition: ConditionRuleData in conditions:
		if condition == null:
			continue
		var dependencies := condition.get_change_dependencies()
		for key: String in dependencies.get("flags", []):
			if key not in _flags:
				_flags.append(key)
		for key: String in dependencies.get("numbers", []):
			if key not in _numbers:
				_numbers.append(key)
		for section: String in dependencies.get("sections", []):
			if section not in _sections:
				_sections.append(section)
		_time = _time or bool(dependencies.get("time", false))


func _on_flag(key: String, _value: bool) -> void:
	if key in _flags:
		queue_change()


func _on_number(key: String, _value: int) -> void:
	if key in _numbers:
		queue_change()


func _on_campaign(section: StringName) -> void:
	if section == &"campaign" or String(section) in _sections:
		queue_change()


func _on_time(_period: int, _days: int, _day: int, _month: String) -> void:
	if _time:
		queue_change()


func queue_change() -> void:
	if not _queued:
		_queued = true
		call_deferred("_emit_change")


func _emit_change() -> void:
	_queued = false
	changed.emit()
