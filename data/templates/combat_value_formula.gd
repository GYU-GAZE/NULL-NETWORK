extends Resource
class_name CombatValueFormula


enum ReferenceActor {
	CASTER,
	TARGET,
	STATUS_HOLDER,
	EVENT_SOURCE,
	EVENT_TARGET,
	DUMMY_CREATOR
}


enum RoundMode {
	ROUND,
	FLOOR,
	CEIL
}


@export_category("Base")
@export var base_value: float = 0.0

@export_category("Primary Stat Scaling")
@export var stat_reference: ReferenceActor = ReferenceActor.CASTER
@export var stat: CombatConstants.Stat = CombatConstants.Stat.ATK
@export var stat_multiplier: float = 0.0
@export var use_effective_stat: bool = false

@export_category("Secondary Stat Scaling")
@export var secondary_stat_reference: ReferenceActor = ReferenceActor.CASTER
@export var secondary_stat: CombatConstants.Stat = CombatConstants.Stat.MATK
@export var secondary_stat_multiplier: float = 0.0
@export var secondary_use_effective_stat: bool = false

@export_category("Stack Scaling")
@export var stack_multiplier: float = 0.0

@export_category("Result")
@export var round_mode: RoundMode = RoundMode.ROUND
@export var use_minimum: bool = false
@export var minimum_value: float = 0.0
@export var use_maximum: bool = false
@export var maximum_value: float = 0.0


func describe() -> String:
	var pieces: Array[String] = []

	if not is_zero_approx(base_value):
		pieces.append(_format_number(base_value))

	_append_stat_piece(
		pieces,
		stat,
		stat_multiplier
	)
	_append_stat_piece(
		pieces,
		secondary_stat,
		secondary_stat_multiplier
	)

	if not is_zero_approx(stack_multiplier):
		pieces.append(
			"%sSTACKS × %s"
			% [
				"+" if stack_multiplier > 0.0 and not pieces.is_empty() else "",
				_format_number(stack_multiplier)
			]
		)

	if pieces.is_empty():
		return "0"

	return " ".join(pieces)


func _append_stat_piece(
	pieces: Array[String],
	stat_id: CombatConstants.Stat,
	multiplier: float
) -> void:
	if is_zero_approx(multiplier):
		return

	pieces.append(
		"%s%s × %s"
		% [
			"+" if multiplier > 0.0 and not pieces.is_empty() else "",
			CombatConstants.stat_label(stat_id),
			_format_percent(multiplier)
		]
	)


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))

	return "%.2f" % value


func _format_percent(value: float) -> String:
	return "%d%%" % int(roundf(value * 100.0))
