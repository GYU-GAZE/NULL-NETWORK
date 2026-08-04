extends Control
class_name NavigatorApp


signal window_pixel_density_breakpoint_requested(
	requested_size: Vector2
)


enum NavigatorMode {
	WORLD_MAP,
	LOCAL_AREA,
	ENCOUNTER,
	DIALOGUE
}

enum PendingActivityKind {
	TRAVEL,
	EXAMINE,
	ENCOUNTER
}


const SESSION_STATE_VERSION: int = 5
const APP_ID: String = "navigator"


@export_category("Adaptive Presentation")
@export var encounter_pixel_density_breakpoint: Vector2 = (
	Vector2(530, 377)
)


@onready var world_map_view: NavigatorWorldMapView = (
	%WorldMapView
)
@onready var local_area_view: NavigatorLocalAreaView = (
	%LocalAreaView
)
@onready var encounter_container: Control = (
	%EncounterContainer
)
@onready var dialogue_container: Control = (
	%DialogueContainer
)
@onready var dialogue_player: DialoguePlayer = %DialoguePlayer
@onready var combat_app: CombatApp = %CombatApp


var _current_mode: NavigatorMode = NavigatorMode.WORLD_MAP
var _current_location_id: String = ""
var _is_app_active: bool = false
var _pending_exe_actor: LocalAreaExeActor
var _pending_incident_id: String = ""
var _pending_activity_requests: Dictionary = {}
var _active_combat_transaction_id: String = ""
var _active_combat_activity_id: String = ""
var _mode_before_dialogue: NavigatorMode = NavigatorMode.WORLD_MAP


func _ready() -> void:
	_connect_signals()

	if DialogueManager.is_dialogue_active():
		_set_mode(NavigatorMode.DIALOGUE)
	else:
		_set_mode(NavigatorMode.WORLD_MAP)

	var registration_errors := SaveManager.register_save_section(self)

	for error: String in registration_errors:
		push_error("Navigator save registration: %s" % error)


func _exit_tree() -> void:
	SaveManager.unregister_save_section(self)


func get_save_section_id() -> String:
	return str(SaveConstants.SECTION_NAVIGATOR_STATE)


func export_save_data() -> Dictionary:
	return get_app_session_state()


func import_save_data(data: Dictionary) -> void:
	restore_app_session_state(data)


func reset_save_data() -> void:
	_pending_activity_requests.clear()
	_pending_exe_actor = null
	_pending_incident_id = ""
	_active_combat_transaction_id = ""
	_active_combat_activity_id = ""
	_current_location_id = ""
	CampaignState.set_current_location("")

	if is_node_ready():
		local_area_view.close_area()
		_set_mode(NavigatorMode.WORLD_MAP)


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var version: int = int(data.get("version", -1))

	if version < 1 or version > SESSION_STATE_VERSION:
		errors.append("Unsupported Navigator save version.")

	var mode: int = int(data.get("mode", NavigatorMode.WORLD_MAP))

	if mode < NavigatorMode.WORLD_MAP or mode > NavigatorMode.DIALOGUE:
		errors.append("Navigator mode is outside the supported range.")

	return errors


func _connect_signals() -> void:
	if not world_map_view.enter_area_requested.is_connected(
		_on_world_map_enter_area_requested
	):
		world_map_view.enter_area_requested.connect(
			_on_world_map_enter_area_requested
		)

	if not local_area_view.back_requested.is_connected(
		_on_local_area_back_requested
	):
		local_area_view.back_requested.connect(
			_on_local_area_back_requested
		)

	if not local_area_view.interaction_requested.is_connected(
		_on_local_area_interaction_requested
	):
		local_area_view.interaction_requested.connect(
			_on_local_area_interaction_requested
		)

	if not combat_app.combat_finished.is_connected(
		_on_combat_finished
	):
		combat_app.combat_finished.connect(
			_on_combat_finished
		)

	if not GlobalSignals.app_focused.is_connected(
		_on_app_focused
	):
		GlobalSignals.app_focused.connect(
			_on_app_focused
		)

	if not GlobalSignals.workspace_activated.is_connected(
		_on_workspace_activated
	):
		GlobalSignals.workspace_activated.connect(
			_on_workspace_activated
		)

	if not GlobalSignals.app_closed.is_connected(
		_on_app_closed
	):
		GlobalSignals.app_closed.connect(_on_app_closed)

	if not ActivityManager.activity_started.is_connected(
		_on_activity_started
	):
		ActivityManager.activity_started.connect(
			_on_activity_started
		)

	if not ActivityManager.activity_rejected.is_connected(
		_on_activity_rejected
	):
		ActivityManager.activity_rejected.connect(
			_on_activity_rejected
		)

	if not ActivityManager.activity_cancelled.is_connected(
		_on_activity_cancelled
	):
		ActivityManager.activity_cancelled.connect(
			_on_activity_cancelled
		)

	if not DialogueManager.dialogue_started.is_connected(
		_on_dialogue_started
	):
		DialogueManager.dialogue_started.connect(_on_dialogue_started)

	if not DialogueManager.dialogue_resumed.is_connected(
		_on_dialogue_resumed
	):
		DialogueManager.dialogue_resumed.connect(_on_dialogue_resumed)

	if not DialogueManager.dialogue_completed.is_connected(
		_on_dialogue_completed
	):
		DialogueManager.dialogue_completed.connect(_on_dialogue_completed)

	if not LeadIncidentManager.incident_encounter_requested.is_connected(
		_on_incident_encounter_requested
	):
		LeadIncidentManager.incident_encounter_requested.connect(
			_on_incident_encounter_requested
		)


func _set_mode(mode: NavigatorMode) -> void:
	_current_mode = mode

	match _current_mode:
		NavigatorMode.WORLD_MAP:
			world_map_view.activate()
			local_area_view.deactivate()
			encounter_container.hide()
			dialogue_container.hide()

		NavigatorMode.LOCAL_AREA:
			world_map_view.deactivate()
			local_area_view.activate()
			local_area_view.set_interaction_enabled(
				_is_app_active
			)
			encounter_container.hide()
			dialogue_container.hide()

		NavigatorMode.ENCOUNTER:
			world_map_view.deactivate()
			local_area_view.deactivate()
			encounter_container.show()
			dialogue_container.hide()

		NavigatorMode.DIALOGUE:
			world_map_view.deactivate()
			local_area_view.deactivate()
			encounter_container.hide()
			dialogue_container.show()

	window_pixel_density_breakpoint_requested.emit(
		get_requested_window_pixel_density_breakpoint()
	)


func get_requested_window_pixel_density_breakpoint() -> Vector2:
	if _current_mode == NavigatorMode.ENCOUNTER:
		return KubuOSMetrics.snap_vector(Vector2(
			max(
				1.0,
				encounter_pixel_density_breakpoint.x
			),
			max(
				1.0,
				encounter_pixel_density_breakpoint.y
			)
		))

	return Vector2.ZERO


func show_world_map() -> void:
	_set_mode(NavigatorMode.WORLD_MAP)


func show_local_area() -> void:
	if local_area_view.get_current_area_instance() == null:
		return

	_set_mode(NavigatorMode.LOCAL_AREA)


func show_encounter() -> void:
	if not combat_app.is_encounter_active():
		return

	_set_mode(NavigatorMode.ENCOUNTER)


func show_dialogue() -> void:
	if DialogueManager.is_dialogue_active():
		_set_mode(NavigatorMode.DIALOGUE)


func get_app_session_state() -> Dictionary:
	var selected_location_id: String = ""
	var selected_location: MapLocation = (
		world_map_view.get_selected_location()
	)

	if selected_location != null:
		selected_location_id = (
			selected_location.get_display_id()
		)

	var current_local_area_id: String = ""
	var current_area_data: LocalAreaData = (
		local_area_view.get_current_area_data()
	)

	if current_area_data != null:
		current_local_area_id = (
			current_area_data.get_display_id()
		)

	var has_player_position: bool = (
		local_area_view.get_current_area_instance()
		!= null
	)

	var saved_mode: NavigatorMode = _current_mode
	var player_position := local_area_view.get_current_player_position()
	var pending_exe_id: String = ""

	if is_instance_valid(_pending_exe_actor):
		pending_exe_id = _pending_exe_actor.get_interaction_id()

	return {
		"version": SESSION_STATE_VERSION,
		"mode": int(saved_mode),
		"selected_location_id": selected_location_id,
		"current_location_id": _current_location_id,
		"current_local_area_id": current_local_area_id,
		"current_entry_id": (
			local_area_view.get_current_entry_id()
		),
		"has_player_position": has_player_position,
		"player_position": {
			"x": player_position.x,
			"y": player_position.y
		},
		"local_area_runtime_state": (
			local_area_view.get_current_runtime_state()
		),
		"pending_exe_interaction_id": pending_exe_id,
		"pending_incident_id": _pending_incident_id,
		"activity_transaction_id": _active_combat_transaction_id,
		"activity_id": _active_combat_activity_id
	}


func restore_app_session_state(
	state: Dictionary
) -> void:
	if state.is_empty():
		return

	var saved_version: int = int(
		state.get("version", 0)
	)

	if saved_version > SESSION_STATE_VERSION:
		push_warning(
			"NavigatorApp: session version %d is newer "
			% saved_version
			+ "than supported version %d."
			% SESSION_STATE_VERSION
		)
		return

	var selected_location_id: String = str(
		state.get("selected_location_id", "")
	).strip_edges()

	if not selected_location_id.is_empty():
		world_map_view.select_location_by_id(
			selected_location_id
		)

	var saved_location_id: String = str(
		state.get("current_location_id", "")
	).strip_edges()

	if saved_location_id.is_empty() and DialogueManager.is_dialogue_active():
		_set_mode(NavigatorMode.DIALOGUE)
		return

	if saved_location_id.is_empty():
		_set_mode(NavigatorMode.WORLD_MAP)
		return

	var saved_location: MapLocation = (
		world_map_view.get_location_by_id(
			saved_location_id
		)
	)

	if (
		saved_location == null
		or saved_location.local_area == null
	):
		push_warning(
			"NavigatorApp: saved location '%s' "
			% saved_location_id
			+ "is unavailable."
		)
		_set_mode(NavigatorMode.WORLD_MAP)
		return

	var saved_local_area_id: String = str(
		state.get("current_local_area_id", "")
	).strip_edges()

	if (
		not saved_local_area_id.is_empty()
		and saved_location.local_area.get_display_id()
		!= saved_local_area_id
	):
		push_warning(
			"NavigatorApp: saved local area '%s' "
			% saved_local_area_id
			+ "does not belong to location '%s'."
			% saved_location_id
		)
		_set_mode(NavigatorMode.WORLD_MAP)
		return

	var saved_position_value: Variant = state.get(
		"player_position",
		Vector2.ZERO
	)
	var has_saved_position: bool = bool(
		state.get("has_player_position", false)
	) and (
		saved_position_value is Vector2
		or saved_position_value is Dictionary
	)

	var saved_position := Vector2.ZERO

	if has_saved_position:
		if saved_position_value is Vector2:
			saved_position = saved_position_value
		else:
			saved_position = Vector2(
				float(saved_position_value.get("x", 0.0)),
				float(saved_position_value.get("y", 0.0))
			)

	var raw_runtime_state: Variant = state.get(
		"local_area_runtime_state",
		{}
	)
	var saved_runtime_state: Dictionary = {}

	if raw_runtime_state is Dictionary:
		saved_runtime_state = (
			raw_runtime_state as Dictionary
		)

	var opened_successfully: bool = (
		local_area_view.open_area(
			saved_location.local_area,
			str(
				state.get("current_entry_id", "")
			),
			saved_position,
			has_saved_position,
			saved_runtime_state,
			saved_location
		)
	)

	if not opened_successfully:
		_set_mode(NavigatorMode.WORLD_MAP)
		return

	_current_location_id = saved_location_id
	CampaignState.set_current_location(saved_location_id)

	var saved_mode: int = int(
		state.get(
			"mode",
			NavigatorMode.WORLD_MAP
		)
	)

	if saved_mode == NavigatorMode.DIALOGUE \
		and DialogueManager.is_dialogue_active():
		_set_mode(NavigatorMode.DIALOGUE)
	elif (
		saved_mode == NavigatorMode.ENCOUNTER
		and CombatManager.is_encounter_active()
	):
		var pending_exe_id: String = str(
			state.get("pending_exe_interaction_id", "")
		).strip_edges()
		_pending_exe_actor = (
			local_area_view.find_interactable_by_id(pending_exe_id)
			as LocalAreaExeActor
		)
		_pending_incident_id = str(
			state.get("pending_incident_id", "")
		).strip_edges()
		var activity_context := CombatManager.get_session_activity_context()
		_active_combat_transaction_id = str(activity_context.get(
			"activity_transaction_id",
			state.get("activity_transaction_id", "")
		)).strip_edges()
		_active_combat_activity_id = str(activity_context.get(
			"activity_id",
			state.get("activity_id", "")
		)).strip_edges()

		if combat_app.resume_saved_encounter():
			_set_mode(NavigatorMode.ENCOUNTER)
		else:
			_set_mode(NavigatorMode.LOCAL_AREA)
	elif saved_mode == NavigatorMode.LOCAL_AREA:
		_set_mode(NavigatorMode.LOCAL_AREA)
	else:
		_set_mode(NavigatorMode.WORLD_MAP)


func _on_world_map_enter_area_requested(
	location: MapLocation
) -> void:
	if location == null:
		push_warning(
			"NavigatorApp: local area requested without a location."
		)
		return

	var runtime_state := (
		NavigatorLocationStateResolver.resolve(location)
	)

	if not runtime_state.can_select():
		return

	var local_area: LocalAreaData = location.local_area

	if local_area == null:
		push_warning(
			"NavigatorApp: location '%s' has no local area."
			% location.location_name
		)
		return

	var requested_location_id: String = (
		location.get_display_id()
	)

	var is_current_area: bool = (
		requested_location_id == _current_location_id
		and local_area_view.is_area_loaded(local_area)
	)

	if is_current_area:
		_set_mode(NavigatorMode.LOCAL_AREA)
		return

	if location.travel_activity == null:
		push_error(
			"NavigatorApp: location '%s' has no travel activity."
			% location.location_name
		)
		return

	_request_activity(
		location.travel_activity,
		PendingActivityKind.TRAVEL,
		{"location": location}
	)


func _on_local_area_interaction_requested(
	target: LocalAreaInteractable
) -> void:
	if (
		target == null
		or target.interaction_data == null
	):
		return

	var data: LocalAreaInteractionData = (
		target.interaction_data
	)

	match data.kind:
		LocalAreaInteractionData.InteractionKind.EXAMINE:
			if data.activity == null:
				local_area_view.show_interaction_message(
					data.response_text
				)
				return

			_request_activity(
				data.activity,
				PendingActivityKind.EXAMINE,
				{"interaction_data": data}
			)

		LocalAreaInteractionData.InteractionKind.ENCOUNTER:
			var exe_actor := target as LocalAreaExeActor

			if exe_actor == null:
				push_error(
					"NavigatorApp: encounter interaction '%s' "
					% data.get_display_id()
					+ "must inherit LocalAreaExeActor."
				)
				return

			if data.activity == null:
				push_error(
					"NavigatorApp: voluntary encounter '%s' "
					% data.get_display_id()
					+ "has no ActivityDefinitionData."
				)
				return

			_request_exe_encounter(
				exe_actor,
				data.activity
			)

		LocalAreaInteractionData.InteractionKind.DIALOGUE:
			if data.dialogue == null:
				push_error(
					"NavigatorApp: dialogue interaction '%s' has no DialogueData."
					% data.get_display_id()
				)
				return

			DialogueManager.start_dialogue(data.dialogue.get_display_id())

		LocalAreaInteractionData.InteractionKind.CUSTOM:
			var incident_actor := target as LocalAreaIncidentActor

			if incident_actor == null:
				push_warning(
					"NavigatorApp: custom interaction '%s' has no handler."
					% data.get_display_id()
				)
				return

			LeadIncidentManager.request_incident(
				incident_actor.incident_id
			)

		_:
			push_warning(
				"NavigatorApp: interaction kind %d for '%s' "
				% [data.kind, data.get_display_id()]
				+ "has no handler yet."
			)


func _request_activity(
	definition: ActivityDefinitionData,
	kind: PendingActivityKind,
	payload: Dictionary,
	parent_transaction_id: String = ""
) -> String:
	var request_id: String = ActivityManager.request_activity(
		definition,
		APP_ID,
		parent_transaction_id
	)
	_pending_activity_requests[request_id] = {
		"kind": int(kind),
		"payload": payload
	}
	return request_id


func _request_exe_encounter(
	exe_actor: LocalAreaExeActor,
	activity: ActivityDefinitionData,
	parent_transaction_id: String = ""
) -> String:
	if exe_actor == null or exe_actor.encounter == null:
		push_error(
			"NavigatorApp: cannot request an encounter "
			+ "without a valid EXE and CombatEncounter."
		)
		return ""

	return _request_activity(
		activity,
		PendingActivityKind.ENCOUNTER,
		{"exe_actor": exe_actor},
		parent_transaction_id
	)


func start_included_exe_encounter(
	exe_actor: LocalAreaExeActor,
	activity: ActivityDefinitionData,
	parent_transaction_id: String
) -> String:
	return _request_exe_encounter(
		exe_actor,
		activity,
		parent_transaction_id
	)


func _enter_location(
	location: MapLocation
) -> bool:
	if location == null or location.local_area == null:
		return false

	var opened_successfully: bool = (
		local_area_view.open_area(
			location.local_area,
			location.local_area.default_entry_id,
			Vector2.ZERO,
			false,
			{},
			location
		)
	)

	if not opened_successfully:
		_set_mode(NavigatorMode.WORLD_MAP)
		return false

	_current_location_id = location.get_display_id()
	CampaignState.set_current_location(_current_location_id)
	_set_mode(NavigatorMode.LOCAL_AREA)
	return true


func _start_exe_encounter(
	exe_actor: LocalAreaExeActor,
	transaction_id: String,
	activity_id: String
) -> void:
	if exe_actor.encounter == null:
		push_error(
			"NavigatorApp: EXE '%s' has no encounter."
			% exe_actor.get_interaction_id()
		)
		return

	_pending_exe_actor = exe_actor
	_active_combat_transaction_id = transaction_id
	_active_combat_activity_id = activity_id
	_set_mode(NavigatorMode.ENCOUNTER)

	if combat_app.start_encounter(exe_actor.encounter):
		CombatManager.set_session_activity_context(
			transaction_id,
			activity_id
		)
		return

	_pending_exe_actor = null
	_active_combat_transaction_id = ""
	_active_combat_activity_id = ""
	ActivityManager.fail_activity(
		transaction_id,
		"Combat encounter failed to start.",
		activity_id
	)
	_set_mode(NavigatorMode.LOCAL_AREA)


func _start_incident_encounter(
	incident_id: String,
	encounter: CombatEncounter,
	transaction_id: String,
	activity_id: String
) -> void:
	if encounter == null:
		LeadIncidentManager.resolve_incident(
			incident_id,
			CombatResult.create(CombatResult.Outcome.CANCELLED)
		)
		return

	_pending_exe_actor = null
	_pending_incident_id = incident_id.strip_edges()
	_active_combat_transaction_id = transaction_id.strip_edges()
	_active_combat_activity_id = activity_id.strip_edges()
	_set_mode(NavigatorMode.ENCOUNTER)

	if combat_app.start_encounter(encounter):
		CombatManager.set_session_activity_context(
			_active_combat_transaction_id,
			_active_combat_activity_id
		)
		return

	var failed_incident_id: String = _pending_incident_id
	_pending_incident_id = ""
	_active_combat_transaction_id = ""
	_active_combat_activity_id = ""
	LeadIncidentManager.resolve_incident(
		failed_incident_id,
		CombatResult.create(CombatResult.Outcome.CANCELLED)
	)
	_set_mode(NavigatorMode.LOCAL_AREA)


func _on_activity_started(
	transaction_id: String,
	activity_id: String,
	source_id: String,
	request_id: String
) -> void:
	if source_id != APP_ID:
		return

	if not _pending_activity_requests.has(request_id):
		return

	var request: Dictionary = _pending_activity_requests[
		request_id
	]
	_pending_activity_requests.erase(request_id)

	var kind: int = int(
		request.get(
			"kind",
			PendingActivityKind.EXAMINE
		)
	)
	var payload: Dictionary = request.get("payload", {})

	match kind:
		PendingActivityKind.TRAVEL:
			var location := (
				payload.get("location") as MapLocation
			)

			if _enter_location(location):
				ActivityManager.complete_activity(
					transaction_id,
					activity_id
				)
			else:
				ActivityManager.fail_activity(
					transaction_id,
					"Destination failed to load.",
					activity_id
				)

		PendingActivityKind.EXAMINE:
			var data := (
				payload.get("interaction_data")
				as LocalAreaInteractionData
			)

			if data != null:
				local_area_view.show_interaction_message(
					data.response_text
				)

			ActivityManager.complete_activity(
				transaction_id,
				activity_id
			)

		PendingActivityKind.ENCOUNTER:
			var exe_actor := (
				payload.get("exe_actor")
				as LocalAreaExeActor
			)

			if not is_instance_valid(exe_actor):
				ActivityManager.fail_activity(
					transaction_id,
					"EXE became unavailable.",
					activity_id
				)
				return

			_start_exe_encounter(
				exe_actor,
				transaction_id,
				activity_id
			)


func _on_activity_rejected(
	request_id: String,
	_activity_id: String,
	source_id: String,
	reason: String
) -> void:
	if source_id != APP_ID:
		return

	_pending_activity_requests.erase(request_id)
	UniversalAlerts.show_alert(
		"ACTIVITY UNAVAILABLE",
		reason
	)


func _on_activity_cancelled(
	request_id: String,
	_activity_id: String,
	source_id: String,
	_reason: String
) -> void:
	if source_id != APP_ID:
		return

	_pending_activity_requests.erase(request_id)


func _on_combat_finished(
	result: CombatResult
) -> void:
	if not _pending_incident_id.is_empty():
		var incident_id: String = _pending_incident_id
		_pending_incident_id = ""
		_pending_exe_actor = null
		_set_mode(NavigatorMode.LOCAL_AREA)
		LeadIncidentManager.resolve_incident(incident_id, result)
		_active_combat_transaction_id = ""
		_active_combat_activity_id = ""
		local_area_view.refresh_population()
		return

	var resolved_actor: LocalAreaExeActor = (
		_pending_exe_actor
	)
	_pending_exe_actor = null

	if is_instance_valid(resolved_actor):
		resolved_actor.apply_combat_result(result)

	_set_mode(NavigatorMode.LOCAL_AREA)

	if not _active_combat_transaction_id.is_empty():
		ActivityManager.complete_activity(
			_active_combat_transaction_id,
			_active_combat_activity_id
		)

	_active_combat_transaction_id = ""
	_active_combat_activity_id = ""
	local_area_view.refresh_population()


func _on_incident_encounter_requested(
	incident_id: String,
	encounter: CombatEncounter,
	transaction_id: String,
	activity_id: String
) -> void:
	_start_incident_encounter(
		incident_id,
		encounter,
		transaction_id,
		activity_id
	)


func _on_local_area_back_requested() -> void:
	_set_mode(NavigatorMode.WORLD_MAP)


func _on_app_focused(app_id: String) -> void:
	_set_app_active(
		app_id.strip_edges() == APP_ID
	)


func _on_workspace_activated(
	workspace_id: String
) -> void:
	_set_app_active(
		workspace_id.strip_edges() == APP_ID
	)


func _on_app_closed(app_id: String) -> void:
	if app_id.strip_edges() != APP_ID:
		return

	ActivityManager.cancel_requests_for_source(
		APP_ID,
		"Navigator was closed before confirmation."
	)
	_pending_activity_requests.clear()


func _set_app_active(active: bool) -> void:
	_is_app_active = active

	if _current_mode != NavigatorMode.LOCAL_AREA:
		return

	local_area_view.set_interaction_enabled(
		_is_app_active
	)


func _on_dialogue_started(_dialogue_id: String, _node_id: String) -> void:
	if _current_mode != NavigatorMode.DIALOGUE:
		_mode_before_dialogue = _current_mode

	_set_mode(NavigatorMode.DIALOGUE)


func _on_dialogue_resumed(_dialogue_id: String, _node_id: String) -> void:
	_set_mode(NavigatorMode.DIALOGUE)


func _on_dialogue_completed(_dialogue_id: String) -> void:
	if _mode_before_dialogue == NavigatorMode.LOCAL_AREA \
		and local_area_view.get_current_area_instance() != null:
		_set_mode(NavigatorMode.LOCAL_AREA)
	else:
		_set_mode(NavigatorMode.WORLD_MAP)
