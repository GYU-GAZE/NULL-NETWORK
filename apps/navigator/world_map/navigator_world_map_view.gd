extends Control
class_name NavigatorWorldMapView


signal location_selected(location: MapLocation)
signal enter_area_requested(location: MapLocation)


@export_category("Content")
@export var world_data: NavigatorWorldData
@export var marker_scene: PackedScene

@export_category("Map Pan")
@export_range(0.0, 64.0, 1.0)
var drag_threshold: float = 6.0

@export_category("Location Discovery")

@export_range(0.05, 2.0, 0.05)
var discovery_pan_duration: float = 0.45

@export_range(0.0, 2.0, 0.05)
var discovery_hold_duration: float = 0.30

@onready var map_viewport: Control = %MapViewport
@onready var map_content: Control = %MapContent
@onready var map_background: TextureRect = %MapBackground
@onready var marker_layer: Control = %MarkerLayer
@onready var selection_panel: PanelContainer = %SelectionPanel
@onready var location_name_label: Label = %LocationNameLabel
@onready var location_subtitle_label: Label = %LocationSubtitleLabel
@onready var location_description_label: Label = %LocationDescriptionLabel
@onready var enter_area_button: Button = (
	%EnterAreaButton
)

@onready var transition_layer: Control = %TransitionLayer
@onready var discovery_audio: AudioStreamPlayer = (
	%DiscoveryAudio
)

var _selected_location: MapLocation
var _markers_by_location_id: Dictionary = {}

var _map_pointer_pressed: bool = false
var _map_dragging: bool = false
var _map_press_position: Vector2 = Vector2.ZERO
var _map_last_pointer_position: Vector2 = Vector2.ZERO
var _current_pan_normalized: Vector2 = Vector2(0.5, 0.5)
var _location_state_refresh_queued: bool = false

var _discovery_queue: Array[String] = []
var _queued_discovery_ids: Dictionary = {}

var _discovery_sequence_running: bool = false
var _active_discovery_id: String = ""

var _location_state_refresh_pending_after_discovery: bool = false

var _map_pan_tween: Tween


func _ready() -> void:
	_connect_signals()
	_apply_world_data()
	_set_selected_location(null)

	call_deferred("_initialize_world_map")


func _connect_signals() -> void:
	if not marker_layer.resized.is_connected(_on_marker_layer_resized):
		marker_layer.resized.connect(_on_marker_layer_resized)

	if not map_viewport.gui_input.is_connected(_on_map_viewport_gui_input):
		map_viewport.gui_input.connect(_on_map_viewport_gui_input)

	if not map_viewport.resized.is_connected(_on_map_viewport_resized):
		map_viewport.resized.connect(_on_map_viewport_resized)
	
	if not GameState.game_state_changed.is_connected(
		_on_game_state_changed
	):
		GameState.game_state_changed.connect(
			_on_game_state_changed
		)

	if not LeadIncidentManager.lead_state_changed.is_connected(
		_on_lead_state_changed
	):
		LeadIncidentManager.lead_state_changed.connect(
			_on_lead_state_changed
		)

	if not GlobalSignals.time_advanced.is_connected(
		_on_navigator_time_advanced
	):
		GlobalSignals.time_advanced.connect(
			_on_navigator_time_advanced
		)
		
	if not enter_area_button.pressed.is_connected(
		_on_enter_area_button_pressed
	):
		enter_area_button.pressed.connect(
			_on_enter_area_button_pressed
		)


func _initialize_world_map() -> void:
	_apply_map_geometry()

	if world_data != null:
		_current_pan_normalized = Vector2(
			clampf(
				world_data.initial_pan_normalized.x,
				0.0,
				1.0
			),
			clampf(
				world_data.initial_pan_normalized.y,
				0.0,
				1.0
			)
		)

	set_pan_normalized(_current_pan_normalized)
	_refresh_marker_positions()


func _apply_world_data() -> void:
	if world_data == null:
		push_error("NavigatorWorldMapView: world_data is not assigned.")
		return

	map_background.texture = world_data.map_texture
	_apply_map_geometry()
	_rebuild_markers()

	if not world_data.initial_location_id.strip_edges().is_empty():
		_select_location_by_id(world_data.initial_location_id)


func _apply_map_geometry() -> void:
	if world_data == null:
		return

	var resolved_map_size: Vector2 = (
		world_data.get_resolved_map_size()
	)

	if (
		resolved_map_size.x <= 0.0
		or resolved_map_size.y <= 0.0
	):
		push_error(
			"NavigatorWorldMapView: world_data requires a valid map texture "
			+ "or map_logical_size."
		)
		return

	var clean_map_size: Vector2 = (
		KubuOSMetrics.snap_vector(resolved_map_size)
	)

	map_content.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)
	map_content.position = (
		KubuOSMetrics.snap_vector(map_content.position)
	)
	map_content.size = clean_map_size

	map_background.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)
	map_background.position = Vector2.ZERO
	map_background.size = clean_map_size

	marker_layer.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)
	marker_layer.position = Vector2.ZERO
	marker_layer.size = clean_map_size


func _rebuild_markers() -> void:
	_clear_markers()

	if marker_scene == null:
		push_error(
			"NavigatorWorldMapView: marker_scene is not assigned."
		)
		return

	if world_data == null:
		return

	for location in world_data.locations:
		if location == null:
			continue

		var runtime_state := (
			NavigatorLocationStateResolver.resolve(
				location
			)
		)

		if (
			runtime_state.is_progression_unlocked
			and not runtime_state.is_discovered
		):
			NavigatorLocationStateResolver.discover(
				location
			)

			runtime_state = (
				NavigatorLocationStateResolver.resolve(
					location
				)
			)

		if not runtime_state.should_show:
			continue

		var marker := (
			marker_scene.instantiate()
			as NavigatorLocationMarker
		)

		if marker == null:
			push_error(
				"NavigatorWorldMapView: marker_scene must "
				+ "instantiate "
				+ "NavigatorLocationMarker."
			)
			return

		marker_layer.add_child(marker)

		marker.setup(
			location,
			runtime_state,
			world_data.new_location_badge
		)

		marker.marker_selected.connect(
			_on_marker_selected
		)

		var location_id: String = (
			location.get_display_id()
		)

		_markers_by_location_id[
			location_id
		] = marker

		if runtime_state.needs_discovery_announcement:
			_enqueue_location_discovery(
				location_id
			)

	call_deferred(
		"_refresh_marker_positions"
	)

	call_deferred(
		"_process_discovery_queue"
	)


func _clear_markers() -> void:
	_markers_by_location_id.clear()

	for child in marker_layer.get_children():
		marker_layer.remove_child(child)
		child.queue_free()

func _enqueue_location_discovery(
	location_id: String
) -> void:
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty():
		return

	if clean_id == _active_discovery_id:
		return

	if _queued_discovery_ids.has(clean_id):
		return

	_discovery_queue.append(clean_id)
	_queued_discovery_ids[clean_id] = true


func _remove_queued_location_discovery(
	location_id: String
) -> void:
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty():
		return

	_queued_discovery_ids.erase(clean_id)
	_discovery_queue.erase(clean_id)


func _process_discovery_queue() -> void:
	if _discovery_sequence_running:
		return

	if not is_visible_in_tree():
		return

	if _discovery_queue.is_empty():
		return

	_discovery_sequence_running = true

	_map_pointer_pressed = false
	_map_dragging = false

	transition_layer.move_to_front()
	transition_layer.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	while (
		not _discovery_queue.is_empty()
		and is_inside_tree()
	):
		var location_id: String = (
			_discovery_queue.pop_front()
		)

		_queued_discovery_ids.erase(
			location_id
		)

		var location := _get_location_by_id(
			location_id
		)

		if location == null:
			continue

		var runtime_state := (
			NavigatorLocationStateResolver.resolve(
				location
			)
		)

		if not runtime_state.needs_discovery_announcement:
			continue

		var marker := (
			_markers_by_location_id.get(
				location_id
			)
			as NavigatorLocationMarker
		)

		if not is_instance_valid(marker):
			continue

		_active_discovery_id = location_id

		await _present_location_discovery(
			location,
			marker
		)

		NavigatorLocationStateResolver.mark_announced(
			location
		)

		_active_discovery_id = ""

	_discovery_sequence_running = false

	transition_layer.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	if _location_state_refresh_pending_after_discovery:
		_location_state_refresh_pending_after_discovery = false
		_queue_location_state_refresh()
		
func _present_location_discovery(
	location: MapLocation,
	marker: NavigatorLocationMarker
) -> void:
	await _animate_map_to_location(location)

	if (
		world_data != null
		and world_data.location_discovery_sound != null
	):
		discovery_audio.stream = (
			world_data.location_discovery_sound
		)

		discovery_audio.play()

	await marker.play_discovery_animation()

	if discovery_hold_duration > 0.0:
		await get_tree().create_timer(
			discovery_hold_duration
		).timeout


func _animate_map_to_location(
	location: MapLocation
) -> void:
	if location == null:
		return

	_kill_map_pan_tween()

	var target_position: Vector2 = (
		_get_centered_map_position(location)
	)

	_map_pan_tween = create_tween()

	_map_pan_tween.set_trans(
		Tween.TRANS_CUBIC
	)

	_map_pan_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	_map_pan_tween.tween_method(
		Callable(
			self,
			"_set_map_position_during_discovery"
		),
		map_content.position,
		target_position,
		discovery_pan_duration
	)

	await _map_pan_tween.finished

	_map_pan_tween = null

	map_content.position = target_position

	_current_pan_normalized = (
		get_pan_normalized()
	)


func _set_map_position_during_discovery(
	value: Vector2
) -> void:
	map_content.position = (
		KubuOSMetrics.snap_vector(value)
	)


func _kill_map_pan_tween() -> void:
	if (
		_map_pan_tween != null
		and _map_pan_tween.is_valid()
	):
		_map_pan_tween.kill()

	_map_pan_tween = null


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
	set_pan_normalized(_current_pan_normalized)
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

	_current_pan_normalized = get_pan_normalized()

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
	_current_pan_normalized = clean_pan

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


func center_map_on_location(
	location: MapLocation
) -> void:
	if location == null:
		return

	map_content.position = (
		_get_centered_map_position(location)
	)

	_current_pan_normalized = (
		get_pan_normalized()
	)

func _get_centered_map_position(
	location: MapLocation
) -> Vector2:
	if location == null:
		return map_content.position

	var normalized_position := Vector2(
		clampf(
			location.world_map_position.x,
			0.0,
			1.0
		),
		clampf(
			location.world_map_position.y,
			0.0,
			1.0
		)
	)

	var map_position := Vector2(
		normalized_position.x * map_content.size.x,
		normalized_position.y * map_content.size.y
	)

	var target_position: Vector2 = (
		map_viewport.size * 0.5
		- map_position
	)

	target_position.x = _clamp_map_axis(
		target_position.x,
		map_viewport.size.x,
		map_content.size.x
	)

	target_position.y = _clamp_map_axis(
		target_position.y,
		map_viewport.size.y,
		map_content.size.y
	)

	return KubuOSMetrics.snap_vector(
		target_position
	)


func _on_marker_selected(
	location: MapLocation
) -> void:
	var runtime_state := (
		NavigatorLocationStateResolver.resolve(
			location
		)
	)

	if not runtime_state.can_select():
		return

	var location_id: String = (
		location.get_display_id()
	)

	_remove_queued_location_discovery(
		location_id
	)

	NavigatorLocationStateResolver.mark_viewed(
		location
	)

	_set_selected_location(location)
	location_selected.emit(location)
	_queue_location_state_refresh()


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
		enter_area_button.disabled = true
		enter_area_button.text = "ENTER"
		return

	selection_panel.show()
	location_name_label.text = location.location_name
	location_subtitle_label.text = location.location_subtitle
	location_subtitle_label.visible = not location.location_subtitle.strip_edges().is_empty()
	location_description_label.text = location.location_description
	if location.local_area == null:
		enter_area_button.disabled = true
		enter_area_button.text = "ENTER"
	else:
		enter_area_button.disabled = (
			not location.local_area.is_valid()
		)

		enter_area_button.text = (
			location.local_area.enter_button_text
		)
		

func _select_location_by_id(location_id: String) -> void:
	if world_data == null:
		return

	for location in world_data.locations:
		if location == null:
			continue

		if location.get_display_id() == location_id:
			_set_selected_location(location)
			return

func _on_game_state_changed() -> void:
	if _discovery_sequence_running:
		_location_state_refresh_pending_after_discovery = true
		return

	_queue_location_state_refresh()


func _on_lead_state_changed(_lead_id: String) -> void:
	if _discovery_sequence_running:
		_location_state_refresh_pending_after_discovery = true
		return

	_queue_location_state_refresh()


func _on_navigator_time_advanced(
	_period: int,
	_days_passed: int,
	_calendar_day: int,
	_month: String
) -> void:
	if _discovery_sequence_running:
		_location_state_refresh_pending_after_discovery = true
		return

	_queue_location_state_refresh()


func _queue_location_state_refresh() -> void:
	if _location_state_refresh_queued:
		return

	_location_state_refresh_queued = true
	call_deferred("_refresh_location_states")


func _refresh_location_states() -> void:
	_location_state_refresh_queued = false

	if world_data == null:
		return

	var selected_location_id: String = ""

	if _selected_location != null:
		selected_location_id = (
			_selected_location.get_display_id()
		)

	_rebuild_markers()

	if selected_location_id.is_empty():
		_set_selected_location(null)
		return

	var restored_location := _get_location_by_id(
		selected_location_id
	)

	if restored_location == null:
		_set_selected_location(null)
		return

	var restored_state := (
		NavigatorLocationStateResolver.resolve(
			restored_location
		)
	)

	if restored_state.can_select():
		_set_selected_location(restored_location)
	else:
		_set_selected_location(null)


func _get_location_by_id(
	location_id: String
) -> MapLocation:
	if world_data == null:
		return null

	for location in world_data.locations:
		if location == null:
			continue

		if location.get_display_id() == location_id:
			return location

	return null

func activate() -> void:
	show()
	call_deferred("_process_discovery_queue")


func deactivate() -> void:
	hide()


func get_selected_location() -> MapLocation:
	return _selected_location


func get_location_by_id(
	location_id: String
) -> MapLocation:
	return _get_location_by_id(location_id)


func select_location_by_id(
	location_id: String
) -> bool:
	var location := _get_location_by_id(location_id)

	if location == null:
		return false

	var runtime_state := (
		NavigatorLocationStateResolver.resolve(location)
	)

	if not runtime_state.can_select():
		return false

	_set_selected_location(location)
	return true


func _on_enter_area_button_pressed() -> void:
	if _selected_location == null:
		push_warning(
			"NavigatorWorldMapView: no location selected."
		)
		return

	var runtime_state := (
		NavigatorLocationStateResolver.resolve(
			_selected_location
		)
	)

	if not runtime_state.can_select():
		return

	if _selected_location.local_area == null:
		push_warning(
			"NavigatorWorldMapView: location '%s' has no local area."
			% _selected_location.location_name
		)
		return

	enter_area_requested.emit(_selected_location)

