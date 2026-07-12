extends Control
class_name NavigatorApp

enum NavigatorMode {
	WORLD_MAP,
	ENCOUNTER,
	DIALOGUE
}

@export_category("Content")
@export var world_data: NavigatorWorldData
@export var marker_scene: PackedScene

@onready var map_background: TextureRect = %MapBackground
@onready var marker_layer: Control = %MarkerLayer

@onready var selection_panel: PanelContainer = %SelectionPanel
@onready var location_name_label: Label = %LocationNameLabel
@onready var location_subtitle_label: Label = %LocationSubtitleLabel
@onready var location_description_label: Label = %LocationDescriptionLabel
@onready var scan_button: Button = %ScanButton

@onready var encounter_container: Control = %EncounterContainer
@onready var dialogue_container: Control = %DialogueContainer
@onready var transition_layer: Control = %TransitionLayer

var _current_mode: NavigatorMode = NavigatorMode.WORLD_MAP
var _selected_location: MapLocation
var _markers_by_location_id: Dictionary = {}


func _ready() -> void:
	_connect_signals()
	_apply_world_data()
	_set_selected_location(null)
	_set_mode(NavigatorMode.WORLD_MAP)
	call_deferred("_refresh_marker_positions")


func _connect_signals() -> void:
	if not scan_button.pressed.is_connected(_on_scan_button_pressed):
		scan_button.pressed.connect(_on_scan_button_pressed)

	if not marker_layer.resized.is_connected(_on_marker_layer_resized):
		marker_layer.resized.connect(_on_marker_layer_resized)


func _apply_world_data() -> void:
	if world_data == null:
		push_error("NavigatorApp: world_data is not assigned.")
		return

	map_background.texture = world_data.map_texture
	_rebuild_markers()

	if not world_data.initial_location_id.strip_edges().is_empty():
		_select_location_by_id(world_data.initial_location_id)


func _rebuild_markers() -> void:
	_clear_markers()

	if marker_scene == null:
		push_error("NavigatorApp: marker_scene is not assigned.")
		return

	if world_data == null:
		return

	for location in world_data.locations:
		if not _should_show_location(location):
			continue

		var marker := marker_scene.instantiate() as NavigatorLocationMarker

		if marker == null:
			push_error(
				"NavigatorApp: marker_scene must instantiate NavigatorLocationMarker."
			)
			return

		marker_layer.add_child(marker)
		marker.setup(location)
		marker.marker_selected.connect(_on_marker_selected)

		_markers_by_location_id[location.get_display_id()] = marker

	call_deferred("_refresh_marker_positions")


func _clear_markers() -> void:
	_markers_by_location_id.clear()

	for child in marker_layer.get_children():
		marker_layer.remove_child(child)
		child.queue_free()


func _should_show_location(location: MapLocation) -> bool:
	if location == null:
		return false

	if not location.show_on_world_map:
		return false

	if not location.unlocked_by_default:
		return false

	return true


func _refresh_marker_positions() -> void:
	if world_data == null:
		return

	var layer_size: Vector2 = marker_layer.size

	for location in world_data.locations:
		if location == null:
			continue

		var location_id: String = location.get_display_id()

		if not _markers_by_location_id.has(location_id):
			continue

		var marker := _markers_by_location_id[location_id] as Control

		if marker == null:
			continue

		var normalized_position := Vector2(
			clampf(location.world_map_position.x, 0.0, 1.0),
			clampf(location.world_map_position.y, 0.0, 1.0)
		)

		var marker_size: Vector2 = marker.size

		if marker_size == Vector2.ZERO:
			marker_size = marker.get_combined_minimum_size()

		var target_position := Vector2(
			normalized_position.x * layer_size.x,
			normalized_position.y * layer_size.y
		) - (marker_size * 0.5)

		marker.position = Vector2(
			round(target_position.x),
			round(target_position.y)
		)


func _on_marker_layer_resized() -> void:
	_refresh_marker_positions()


func _on_marker_selected(location: MapLocation) -> void:
	_set_selected_location(location)


func _set_selected_location(location: MapLocation) -> void:
	_selected_location = location

	for location_id in _markers_by_location_id.keys():
		var marker := _markers_by_location_id[location_id] as NavigatorLocationMarker

		if marker == null:
			continue

		if location == null:
			marker.set_selected(false)
			continue

		marker.set_selected(
			location_id == location.get_display_id()
		)

	if location == null:
		selection_panel.hide()
		location_name_label.text = ""
		location_subtitle_label.text = ""
		location_description_label.text = ""
		scan_button.disabled = true
		return

	selection_panel.show()
	location_name_label.text = location.location_name
	location_subtitle_label.text = location.location_subtitle
	location_subtitle_label.visible = not location.location_subtitle.strip_edges().is_empty()
	location_description_label.text = location.location_description
	scan_button.disabled = location.spawn_table == null


func _select_location_by_id(location_id: String) -> void:
	if world_data == null:
		return

	for location in world_data.locations:
		if location == null:
			continue

		if location.get_display_id() == location_id:
			_set_selected_location(location)
			return


func _set_mode(mode: NavigatorMode) -> void:
	_current_mode = mode

	match _current_mode:
		NavigatorMode.WORLD_MAP:
			map_background.show()
			marker_layer.show()
			encounter_container.hide()
			dialogue_container.hide()

			if _selected_location != null:
				selection_panel.show()
			else:
				selection_panel.hide()

		NavigatorMode.ENCOUNTER:
			map_background.show()
			marker_layer.hide()
			selection_panel.hide()
			encounter_container.show()
			dialogue_container.hide()

		NavigatorMode.DIALOGUE:
			map_background.show()
			marker_layer.hide()
			selection_panel.hide()
			encounter_container.hide()
			dialogue_container.show()


func show_world_map() -> void:
	_set_mode(NavigatorMode.WORLD_MAP)


func show_encounter() -> void:
	_set_mode(NavigatorMode.ENCOUNTER)


func show_dialogue() -> void:
	_set_mode(NavigatorMode.DIALOGUE)


func _on_scan_button_pressed() -> void:
	if _selected_location == null:
		push_warning("NavigatorApp: scan requested without a selected location.")
		return

	if _selected_location.spawn_table == null:
		push_warning(
			"NavigatorApp: location '%s' has no SpawnTable."
			% _selected_location.location_name
		)
		return

	var encounter: CombatEncounter = (
		_selected_location.spawn_table.roll_encounter()
	)

	if encounter == null:
		print("NavigatorApp: no encounter was rolled.")
		return

	GlobalSignals.request_combat.emit(encounter)
