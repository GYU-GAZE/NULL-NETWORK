extends Control
class_name NavigatorApp


enum NavigatorMode {
	WORLD_MAP,
	LOCAL_AREA,
	ENCOUNTER,
	DIALOGUE
}


const SESSION_STATE_VERSION: int = 1
const APP_ID: String = "navigator"


@onready var world_map_view: NavigatorWorldMapView = (
	%WorldMapView
)
@onready var local_area_view: NavigatorLocalAreaView = (
	%LocalAreaView
)
@onready var encounter_container: Control = %EncounterContainer
@onready var dialogue_container: Control = %DialogueContainer


var _current_mode: NavigatorMode = NavigatorMode.WORLD_MAP
var _current_location_id: String = ""
var _is_app_active: bool = false


func _ready() -> void:
	_connect_signals()
	_set_mode(NavigatorMode.WORLD_MAP)


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


func show_world_map() -> void:
	_set_mode(NavigatorMode.WORLD_MAP)


func show_local_area() -> void:
	if local_area_view.get_current_area_instance() == null:
		return

	_set_mode(NavigatorMode.LOCAL_AREA)


func show_encounter() -> void:
	_set_mode(NavigatorMode.ENCOUNTER)


func show_dialogue() -> void:
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

	return {
		"version": SESSION_STATE_VERSION,
		"mode": int(_current_mode),
		"selected_location_id": selected_location_id,
		"current_location_id": _current_location_id,
		"current_local_area_id": current_local_area_id,
		"current_entry_id": (
			local_area_view.get_current_entry_id()
		),
		"has_player_position": has_player_position,
		"player_position": (
			local_area_view.get_current_player_position()
		)
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
	) and saved_position_value is Vector2

	var saved_position := Vector2.ZERO

	if has_saved_position:
		saved_position = saved_position_value

	var opened_successfully: bool = (
		local_area_view.open_area(
			saved_location.local_area,
			str(
				state.get("current_entry_id", "")
			),
			saved_position,
			has_saved_position
		)
	)

	if not opened_successfully:
		_set_mode(NavigatorMode.WORLD_MAP)
		return

	_current_location_id = saved_location_id

	var saved_mode: int = int(
		state.get(
			"mode",
			NavigatorMode.WORLD_MAP
		)
	)

	if saved_mode == NavigatorMode.LOCAL_AREA:
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

	var opened_successfully: bool = (
		local_area_view.open_area(
			local_area,
			local_area.default_entry_id
		)
	)

	if not opened_successfully:
		_set_mode(NavigatorMode.WORLD_MAP)
		return

	_current_location_id = requested_location_id
	_set_mode(NavigatorMode.LOCAL_AREA)

	if location.travel_action_cost > 0:
		TimeManager.advance_action(
			location.travel_action_cost
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


func _set_app_active(active: bool) -> void:
	_is_app_active = active

	if _current_mode != NavigatorMode.LOCAL_AREA:
		return

	local_area_view.set_interaction_enabled(
		_is_app_active
	)
