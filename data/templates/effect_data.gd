extends Resource
class_name EffectData

enum EffectType {
	SET_FLAG,
	TOGGLE_FLAG,
	ADVANCE_TIME
}

@export var effect_type: EffectType = EffectType.SET_FLAG

@export_category("Flag Effect")
@export var target_flag: String = ""
@export var flag_value: bool = true

@export_category("Time Effect")
@export var action_amount: int = 1


func apply() -> void:
	match effect_type:
		EffectType.SET_FLAG:
			_apply_set_flag()

		EffectType.TOGGLE_FLAG:
			_apply_toggle_flag()

		EffectType.ADVANCE_TIME:
			_apply_advance_time()


func _apply_set_flag() -> void:
	if target_flag.is_empty():
		push_warning("EffectData SET_FLAG sem target_flag.")
		return

	GameState.set_flag(target_flag, flag_value)


func _apply_toggle_flag() -> void:
	if target_flag.is_empty():
		push_warning("EffectData TOGGLE_FLAG sem target_flag.")
		return

	GameState.toggle_flag(target_flag)


func _apply_advance_time() -> void:
	if action_amount <= 0:
		push_warning("EffectData ADVANCE_TIME com action_amount inválido.")
		return

	TimeManager.advance_action(action_amount)