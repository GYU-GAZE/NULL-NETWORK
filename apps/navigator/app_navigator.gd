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

@export_category("Map Pan")
@export_range(0.0, 64.0, 1.0)
var drag_threshold: float = 6.0

@onready var world_map_layer: Control = %WorldMapLayer
@onready var map_viewport: Control = %MapViewport
@onready var map_content: Control = %MapContent
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

var _map_pointer_pressed: bool = false
var _map_dragging: bool = false
var _map_press_position: Vector2 = Vector2.ZERO
var _map_last_pointer_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_connect_signals()
	_apply_world_data()
	_set_selected_location(null)
	_set_mode(NavigatorMode.WORLD_MAP)

	call_deferred("_initialize_world_map")


func _connect_signals() -> void:
	if not scan_button.pressed.is_connected(_on_scan_button_pressed):
		scan_button.pressed.connect(_on_scan_button_pressed)

	if not marker_layer.resized.is_connected(_on_marker_layer_resized):
		marker_layer.resized.connect(_on_marker_layer_resized)

	if not map_viewport.gui_input.is_connected(_on_map_viewport_gui_input):
		map_viewport.gui_input.connect(_on_map_viewport_gui_input)

	if not map_viewport.resized.is_connected(_on_map_viewport_resized):
		map_viewport.resized.connect(_on_map_viewport_resized)


func _initialize_world_map() -> void:
	_apply_map_geometry()

	if world_data != null:
		set_pan_normalized(world_data.initial_pan_normalized)
	else:
		_clamp_map_position()

	_refresh_marker_positions()


func _apply_world_data() -> void:
	if world_data == null:
		push_error("NavigatorApp: world_data is not assigned.")
		return

	map_background.texture = world_data.map_texture
	_apply_map_geometry()
	_rebuild_markers()

	if not world_data.initial_location_id.strip_edges().is_empty():
		_select_location_by_id(world_data.initial_location_id)


func _apply_map_geometry() -> void:
	if world_data == null:
		return

	var resolved_map_size: Vector2 = world_data.get_resolved_map_size()

	if resolved_map_size.x <= 0.0 or resolved_map_size.y <= 0.0:
		push_error(
		"NavigatorApp: world_data requires a valid map texture "
		+ "or map_logical_size."
	)
	return

	var clean_map_size: Vector2 = KubuOSMetrics.snap_vector(
	resolved_map_size
)

	map_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map_content.size = KubuOSMetrics.snap_vector(clean_map_size)

	map_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_background.position = Vector2.ZERO
	map_background.size = map_content.size

	marker_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	marker_layer.position = Vector2.ZERO
	marker_layer.size = map_content.size


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

		marker.position = KubuOSMetrics.snap_vector(target_position)


func _on_marker_layer_resized() -> void:
	_refresh_marker_positions()


func _on_map_viewport_resized() -> void:
	call_deferred("_refresh_after_viewport_resize")


func _refresh_after_viewport_resize() -> void:
	_apply_map_geometry()
	_clamp_map_position()
	_refresh_marker_positions()


func _on_map_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_map_mouse_button(event as InputEventMouseButton)
		return

	if event is InputEventMouseMotion:
		_handle_map_mouse_motion(event as InputEventMouseMotion)


func _handle_map_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_map_pointer_pressed = true
		_map_dragging = false
		_map_press_position = event.position
		_map_last_pointer_position = event.position
		map_viewport.accept_event()
		return

	_map_pointer_pressed = false
	_map_dragging = false
	map_viewport.accept_event()


func _handle_map_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _map_pointer_pressed:
		return

	if not _map_dragging:
		var drag_distance: float = (
			event.position - _map_press_position
		).length()

		if drag_distance < drag_threshold:
			return

		_map_dragging = true

	var movement_delta: Vector2 = (
		event.position - _map_last_pointer_position
	)

	_map_last_pointer_position = event.position

	map_content.position += movement_delta
	_clamp_map_position()

	map_viewport.accept_event()


func _clamp_map_position() -> void:
	var viewport_size: Vector2 = map_viewport.size
	var content_size: Vector2 = map_content.size
	var clean_position: Vector2 = map_content.position

	clean_position.x = _clamp_map_axis(
		clean_position.x,
		viewport_size.x,
		content_size.x
	)

	clean_position.y = _clamp_map_axis(
		clean_position.y,
		viewport_size.y,
		content_size.y
	)

	map_content.position = KubuOSMetrics.snap_vector(clean_position)


func _clamp_map_axis(
	current_position: float,
	viewport_length: float,
	content_length: float
) -> float:
	if content_length <= viewport_length:
		return (viewport_length - content_length) * 0.5

	var minimum_position: float = viewport_length - content_length

	return clampf(
		current_position,
		minimum_position,
		0.0
	)


func set_pan_normalized(normalized_pan: Vector2) -> void:
	var clean_pan := Vector2(
		clampf(normalized_pan.x, 0.0, 1.0),
		clampf(normalized_pan.y, 0.0, 1.0)
	)

	map_content.position = Vector2(
		_normalized_pan_to_axis_position(
			clean_pan.x,
			map_viewport.size.x,
			map_content.size.x
		),
		_normalized_pan_to_axis_position(
			clean_pan.y,
			map_viewport.size.y,
			map_content.size.y
		)
	)

	_clamp_map_position()


func get_pan_normalized() -> Vector2:
	return Vector2(
		_axis_position_to_normalized_pan(
			map_content.position.x,
			map_viewport.size.x,
			map_content.size.x
		),
		_axis_position_to_normalized_pan(
			map_content.position.y,
			map_viewport.size.y,
			map_content.size.y
		)
	)


func _normalized_pan_to_axis_position(
	normalized_value: float,
	viewport_length: float,
	content_length: float
) -> float:
	if content_length <= viewport_length:
		return (viewport_length - content_length) * 0.5

	var minimum_position: float = viewport_length - content_length

	return lerpf(
		0.0,
		minimum_position,
		normalized_value
	)


func _axis_position_to_normalized_pan(
	current_position: float,
	viewport_length: float,
	content_length: float
) -> float:
	if content_length <= viewport_length:
		return 0.5

	var minimum_position: float = viewport_length - content_length

	if is_zero_approx(minimum_position):
		return 0.5

	return clampf(
		current_position / minimum_position,
		0.0,
		1.0
	)


func center_map_on_location(location: MapLocation) -> void:
	if location == null:
		return

	var normalized_position := Vector2(
		clampf(location.world_map_position.x, 0.0, 1.0),
		clampf(location.world_map_position.y, 0.0, 1.0)
	)

	var map_position := Vector2(
		normalized_position.x * map_content.size.x,
		normalized_position.y * map_content.size.y
	)

	map_content.position = (
		map_viewport.size * 0.5
		- map_position
	)

	_clamp_map_position()


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
			world_map_layer.show()
			encounter_container.hide()
			dialogue_container.hide()

			if _selected_location != null:
				selection_panel.show()
			else:
				selection_panel.hide()

		NavigatorMode.ENCOUNTER:
			world_map_layer.hide()
			selection_panel.hide()
			encounter_container.show()
			dialogue_container.hide()

		NavigatorMode.DIALOGUE:
			world_map_layer.hide()
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
		push_warning(
			"NavigatorApp: scan requested without a selected location."
		)
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
