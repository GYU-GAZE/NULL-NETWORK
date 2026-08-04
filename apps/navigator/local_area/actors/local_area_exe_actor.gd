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
var population_actor_id: String = ""


func configure_population_actor(
	new_actor_id: String,
	spawn_entry: SpawnEntry
) -> bool:
	if spawn_entry == null or spawn_entry.encounter == null:
		return false

	population_actor_id = new_actor_id.strip_edges()
	encounter = spawn_entry.encounter
	persistence_scope = PersistenceScope.WORLD_POPULATION

	var data := LocalAreaInteractionData.new()
	data.interaction_id = population_actor_id
	data.display_name = (
		spawn_entry.display_name.strip_edges()
		if not spawn_entry.display_name.strip_edges().is_empty()
		else spawn_entry.get_display_id()
	)
	data.kind = LocalAreaInteractionData.InteractionKind.ENCOUNTER
	data.prompt_verb = "FIGHT"
	data.activity = spawn_entry.activity
	interaction_data = data
	return not population_actor_id.is_empty()


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
	var changed: bool = _resolved != value
	_resolved = value
	visible = not _resolved
	set_available(not _resolved)

	if is_instance_valid(body_collision):
		body_collision.set_deferred(
			"disabled",
			_resolved
		)

	if changed:
		notify_persistent_state_changed()
