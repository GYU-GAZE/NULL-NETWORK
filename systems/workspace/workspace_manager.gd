extends Control
class_name WorkspaceManager

signal active_workspace_changed(
	workspace_id: String,
	workspace_instance: Control
)

@onready var active_workspace_container: Control = %ActiveWorkspaceContainer

var _active_app: AppResource
var _active_workspace_instance: Control
var _layout_refresh_queued: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_connect_global_signals()
	_connect_metrics_signals()

	call_deferred("_refresh_workspace_geometry")


func _connect_global_signals() -> void:
	if not GlobalSignals.request_activate_workspace.is_connected(
		_on_request_activate_workspace
	):
		GlobalSignals.request_activate_workspace.connect(
			_on_request_activate_workspace
		)


func _connect_metrics_signals() -> void:
	if not KubuOSMetrics.metrics_changed.is_connected(
		_on_metrics_changed
	):
		KubuOSMetrics.metrics_changed.connect(
			_on_metrics_changed
		)


func _on_request_activate_workspace(app: AppResource) -> void:
	activate_workspace(app)


func activate_workspace(app: AppResource) -> void:
	if not _is_valid_workspace_app(app):
		return

	var requested_app_id: String = app.app_id.strip_edges()

	if (
		_active_app != null
		and _active_app.app_id.strip_edges() == requested_app_id
		and is_instance_valid(_active_workspace_instance)
	):
		_active_workspace_instance.show()
		_active_workspace_instance.move_to_front()

		GlobalSignals.workspace_activated.emit(requested_app_id)
		active_workspace_changed.emit(
			requested_app_id,
			_active_workspace_instance
		)
		return

	_clear_active_workspace()

	var workspace_instance: Control = _instantiate_workspace(app)

	if workspace_instance == null:
		return

	_active_app = app
	_active_workspace_instance = workspace_instance

	GlobalSignals.workspace_activated.emit(requested_app_id)
	active_workspace_changed.emit(
		requested_app_id,
		_active_workspace_instance
	)


func clear_active_workspace() -> void:
	if _active_app == null and not is_instance_valid(
		_active_workspace_instance
	):
		return

	_clear_active_workspace()

	GlobalSignals.workspace_activated.emit("")
	active_workspace_changed.emit("", null)


func get_active_workspace_id() -> String:
	if _active_app == null:
		return ""

	return _active_app.app_id.strip_edges()


func get_active_workspace_instance() -> Control:
	if not is_instance_valid(_active_workspace_instance):
		return null

	return _active_workspace_instance


func has_active_workspace() -> bool:
	return (
		_active_app != null
		and is_instance_valid(_active_workspace_instance)
	)


func _is_valid_workspace_app(app: AppResource) -> bool:
	if app == null:
		push_warning(
			"WorkspaceManager: null AppResource received."
		)
		return false

	var app_id: String = app.app_id.strip_edges()

	if app_id.is_empty():
		push_error(
			"WorkspaceManager: AppResource has an empty app_id."
		)
		return false

	if (
		app.presentation_mode
		!= AppResource.PresentationMode.WORKSPACE
	):
		push_error(
			"WorkspaceManager: app '%s' does not use WORKSPACE presentation."
			% app_id
		)
		return false

	if app.app_scene == null:
		push_error(
			"WorkspaceManager: workspace '%s' has no app_scene."
			% app_id
		)
		return false

	return true


func _instantiate_workspace(app: AppResource) -> Control:
	var instance: Node = app.app_scene.instantiate()

	if instance == null:
		push_error(
			"WorkspaceManager: failed to instantiate workspace '%s'."
			% app.app_id
		)
		return null

	if not instance is Control:
		push_error(
			"WorkspaceManager: app_scene for '%s' must have a Control root."
			% app.app_id
		)
		instance.queue_free()
		return null

	var workspace_control := instance as Control

	active_workspace_container.add_child(workspace_control)

	_configure_workspace_control(workspace_control)
	workspace_control.show()

	return workspace_control


func _configure_workspace_control(
	workspace_control: Control
) -> void:
	workspace_control.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)
	workspace_control.position = Vector2.ZERO
	workspace_control.size = active_workspace_container.size
	workspace_control.custom_minimum_size = Vector2.ZERO
	workspace_control.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	workspace_control.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


func _clear_active_workspace() -> void:
	_active_app = null

	if is_instance_valid(_active_workspace_instance):
		active_workspace_container.remove_child(
			_active_workspace_instance
		)
		_active_workspace_instance.queue_free()

	_active_workspace_instance = null


func _on_metrics_changed() -> void:
	_queue_layout_refresh()


func _queue_layout_refresh() -> void:
	if _layout_refresh_queued:
		return

	_layout_refresh_queued = true
	call_deferred("_refresh_workspace_geometry")


func _refresh_workspace_geometry() -> void:
	_layout_refresh_queued = false

	if not is_instance_valid(active_workspace_container):
		return

	var parent_size: Vector2 = size

	if parent_size.x <= 0.0 or parent_size.y <= 0.0:
		parent_size = get_viewport_rect().size

	var work_rect: Rect2 = KubuOSMetrics.get_work_area_rect(
		parent_size
	)

	active_workspace_container.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)
	active_workspace_container.position = (
		KubuOSMetrics.snap_vector(work_rect.position)
	)
	active_workspace_container.size = (
		KubuOSMetrics.snap_vector(work_rect.size)
	)

	if is_instance_valid(_active_workspace_instance):
		_configure_workspace_control(
			_active_workspace_instance
		)
