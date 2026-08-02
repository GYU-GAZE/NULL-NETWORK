extends LocalAreaInteractable
class_name LocalAreaExeActor


@export_category("Encounter")
@export var encounter: CombatEncounter

@export_category("Resolution Policy")
@export var remove_on_victory: bool = true
@export var remove_on_defeat: bool = false
@export var remove_on_escape: bool = false

@onready var body_collision: CollisionShape2D = (
	%BodyCollision
)


var _resolved: bool = false


func can_interact() -> bool:
	return (
		not _resolved
		and encounter != null
		and super.can_interact()
	)


func apply_combat_result(result: CombatResult) -> void:
	if result == null:
		return

	var should_remove: bool = false

	match result.outcome:
		CombatResult.Outcome.VICTORY:
			should_remove = remove_on_victory
		CombatResult.Outcome.DEFEAT:
			should_remove = remove_on_defeat
		CombatResult.Outcome.ESCAPED:
			should_remove = remove_on_escape

	if should_remove:
		_set_resolved(true)


func get_persistent_state() -> Dictionary:
	var state: Dictionary = super.get_persistent_state()
	state["resolved"] = _resolved
	return state


func apply_persistent_state(state: Dictionary) -> void:
	super.apply_persistent_state(state)
	_set_resolved(bool(state.get("resolved", false)))


func _set_resolved(value: bool) -> void:
	_resolved = value
	visible = not _resolved
	set_available(not _resolved)

	if is_instance_valid(body_collision):
		body_collision.set_deferred(
			"disabled",
			_resolved
		)
