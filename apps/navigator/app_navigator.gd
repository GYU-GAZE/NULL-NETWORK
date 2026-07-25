extends Control
class_name NavigatorApp


enum NavigatorMode {
	WORLD_MAP,
	LOCAL_AREA,
	ENCOUNTER,
	DIALOGUE
}


@onready var world_map_view: NavigatorWorldMapView = (
	%WorldMapView
)
@onready var local_area_view: NavigatorLocalAreaView = (
	%LocalAreaView
)
@onready var encounter_container: Control = %EncounterContainer
@onready var dialogue_container: Control = %DialogueContainer


var _current_mode: NavigatorMode = NavigatorMode.WORLD_MAP


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


func _set_mode(mode: NavigatorMode) -> void:
	_current_mode = mode

	match _current_mode:
		NavigatorMode.WORLD_MAP:
			world_map_view.activate()
			local_area_view.hide()
			encounter_container.hide()
			dialogue_container.hide()

		NavigatorMode.LOCAL_AREA:
			world_map_view.deactivate()
			local_area_view.show()
			encounter_container.hide()
			dialogue_container.hide()

		NavigatorMode.ENCOUNTER:
			world_map_view.deactivate()
			local_area_view.hide()
			encounter_container.show()
			dialogue_container.hide()

		NavigatorMode.DIALOGUE:
			world_map_view.deactivate()
			local_area_view.hide()
			encounter_container.hide()
			dialogue_container.show()


func show_world_map() -> void:
	_set_mode(NavigatorMode.WORLD_MAP)


func show_local_area() -> void:
	_set_mode(NavigatorMode.LOCAL_AREA)


func show_encounter() -> void:
	_set_mode(NavigatorMode.ENCOUNTER)


func show_dialogue() -> void:
	_set_mode(NavigatorMode.DIALOGUE)


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

	_set_mode(NavigatorMode.LOCAL_AREA)

	var opened_successfully: bool = (
		local_area_view.open_area(local_area)
	)

	if not opened_successfully:
		_set_mode(NavigatorMode.WORLD_MAP)


func _on_local_area_back_requested() -> void:
	local_area_view.close_area()
	_set_mode(NavigatorMode.WORLD_MAP)
