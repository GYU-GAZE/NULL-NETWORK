extends LocalAreaInteractable
class_name LocalAreaExeActor

@export var environmental_apk: APKData
@export var encounter: CombatEncounter
@export var remove_on_victory: bool = true
@export var remove_on_defeat: bool = false
@export var remove_on_escape: bool = false
@onready var motor: FieldEXEMotor = %Motor
@onready var body_collision: CollisionShape2D = %BodyCollision
@onready var contact_sensor: Area2D = %ContactSensor
@onready var presentation: FieldEXEPresentation = %Presentation
var population_actor_id: String = ""
var population_unit_id: String = ""
var spawn_entry: SpawnEntry
var behavior_profile: FieldBehaviorProfileData
var encounter_profile: FieldEncounterProfileData
var effective_behavior: int = FieldBehaviorProfileData.Behavior.PASSIVE
var speed_multiplier: float = 1.0
var behavior_enabled: bool = true
var aggro_enabled: bool = false
var field_context: Dictionary = {}
var field_area: NavigatorLocalAreaScene
var call_locked: bool = false
var hp_fraction: float = 1.0
var stability_fraction: float = 1.0
var _resolved: bool = false
var _contact_queued: bool = false
var _pending_motor_data: Dictionary = {}
var _subscription: ConditionChangeSubscription

func _ready() -> void:
	motor.global_position = global_position

func configure_population_actor(new_actor_id: String, entry: SpawnEntry) -> bool:
	if entry == null or (entry.encounter == null and entry.environmental_apk == null):
		return false
	population_actor_id = new_actor_id.strip_edges()
	population_unit_id = population_actor_id
	spawn_entry = entry
	encounter = entry.encounter
	environmental_apk = entry.environmental_apk
	behavior_profile = entry.get_field_behavior()
	encounter_profile = entry.get_field_encounter()
	persistence_scope = PersistenceScope.WORLD_POPULATION
	var data := LocalAreaInteractionData.new()
	data.interaction_id = population_actor_id
	data.display_name = entry.display_name if not entry.display_name.is_empty() else entry.get_display_id()
	data.kind = LocalAreaInteractionData.InteractionKind.ENCOUNTER if encounter != null or encounter_profile != null else LocalAreaInteractionData.InteractionKind.EXAMINE
	data.prompt_verb = "FIGHT" if data.kind == LocalAreaInteractionData.InteractionKind.ENCOUNTER else "OBSERVE"
	data.response_text = entry.environmental_description
	data.activity = encounter_profile.voluntary_activity if encounter_profile != null else entry.activity
	interaction_data = data
	return not population_actor_id.is_empty()

func bind_field(area: NavigatorLocalAreaScene, seed_value: int) -> void:
	if environmental_apk == null or behavior_profile == null or not is_node_ready():
		return
	field_area = area
	presentation.configure(environmental_apk.field_presentation)
	motor.bind(area, seed_value)
	motor.restore(_pending_motor_data)
	_pending_motor_data.clear()
	_subscription = ConditionChangeSubscription.new()
	add_child(_subscription)
	var conditions: Array[ConditionRuleData] = [behavior_profile.active_conditions, behavior_profile.aggro_conditions]
	for modifier: FieldBehaviorModifierData in behavior_profile.modifiers:
		if modifier != null:
			conditions.append(modifier.conditions)
	_subscription.configure(conditions, [], ["partner", "world_infestation"], true)
	_subscription.changed.connect(refresh_field_context)
	refresh_field_context()

func refresh_field_context() -> void:
	if field_area == null or behavior_profile == null:
		return
	field_context = FieldContextBuilder.build(field_area.map_location)
	field_context["variant_node_id"] = spawn_entry.variant_node_id
	var stats := APKProgressionService.get_current_stats()
	field_context["player_hp_fraction"] = float(CampaignState.partner.current_hp) / maxf(1, float(stats.get("max_hp", 1)))
	effective_behavior = int(behavior_profile.behavior)
	speed_multiplier = 1.0
	behavior_enabled = behavior_profile.active_conditions == null or behavior_profile.active_conditions.is_met(field_context)
	aggro_enabled = behavior_profile.aggro_conditions == null or behavior_profile.aggro_conditions.is_met(field_context)
	for modifier: FieldBehaviorModifierData in behavior_profile.modifiers:
		if modifier != null and (modifier.conditions == null or modifier.conditions.is_met(field_context)):
			if modifier.behavior_override >= 0:
				effective_behavior = modifier.behavior_override
			speed_multiplier *= modifier.speed_multiplier

func can_interact() -> bool:
	return not _resolved and not call_locked and (encounter != null or environmental_apk != null) and super.can_interact()

func can_move_in_field() -> bool:
	return not _resolved and available and not call_locked

func request_field_contact() -> void:
	if _contact_queued or not can_interact() or field_area == null or encounter_profile == null:
		return
	if encounter_profile.aggro_policy == FieldEncounterProfileData.AggroPolicy.DISABLED:
		return
	_contact_queued = true
	_emit_contact.call_deferred()

func _emit_contact() -> void:
	if field_area != null and field_area.is_field_active() and can_interact():
		field_area.field_contact_requested.emit(self)
	else:
		_contact_queued = false

func set_call_locked(value: bool, signal_label: String = "") -> void:
	call_locked = value
	_contact_queued = value
	presentation.signal_text = signal_label
	if value:
		motor.velocity = Vector2.ZERO
		motor.state = FieldEXEMotor.State.COMBAT_CALL
	presentation.queue_redraw()

func release_call(grace: bool = false) -> void:
	set_call_locked(false)
	if grace and behavior_profile != null:
		motor.disengage()

func apply_unit_result(record: Dictionary, outcome: CombatResult.Outcome) -> void:
	if not record.is_empty():
		hp_fraction = clampf(float(record.get("hp", 1)) / maxf(1, float(record.get("max_hp", 1))), 0, 1)
		stability_fraction = clampf(float(record.get("stability", 100)) / maxf(1, float(record.get("max_stability", 100))), 0, 1)
		if bool(record.get("defeated", false)) or bool(record.get("tamed", false)) or bool(record.get("purged", false)) or hp_fraction <= 0:
			_set_resolved(true)
	release_call(outcome in [CombatResult.Outcome.ESCAPED, CombatResult.Outcome.CANCELLED])
	notify_persistent_state_changed()

func apply_combat_result(result: CombatResult) -> void:
	if result == null:
		return
	var should_remove := (result.outcome == CombatResult.Outcome.VICTORY and remove_on_victory) or (result.outcome == CombatResult.Outcome.DEFEAT and remove_on_defeat) or (result.outcome == CombatResult.Outcome.ESCAPED and remove_on_escape)
	if should_remove:
		_set_resolved(true)

func get_persistent_state() -> Dictionary:
	var state := super.get_persistent_state()
	state.merge({"resolved": _resolved, "population_unit_id": population_unit_id, "hp_fraction": hp_fraction, "stability_fraction": stability_fraction}, true)
	if is_instance_valid(motor) and field_area != null:
		state["field_motion"] = motor.to_data()
	return state

func apply_persistent_state(state: Dictionary) -> void:
	super.apply_persistent_state(state)
	population_unit_id = str(state.get("population_unit_id", population_actor_id))
	hp_fraction = clampf(float(state.get("hp_fraction", 1)), 0, 1)
	stability_fraction = clampf(float(state.get("stability_fraction", 1)), 0, 1)
	_pending_motor_data = state.get("field_motion", {}).duplicate(true)
	if field_area != null:
		motor.restore(_pending_motor_data)
		_pending_motor_data.clear()
	_set_resolved(bool(state.get("resolved", false)))

func _set_resolved(value: bool) -> void:
	var changed := _resolved != value
	_resolved = value
	visible = not _resolved
	set_available(not _resolved)
	if is_instance_valid(body_collision):
		body_collision.set_deferred("disabled", _resolved)
	if _resolved and is_instance_valid(motor):
		motor.state = FieldEXEMotor.State.DISABLED
	if changed:
		notify_persistent_state_changed()
