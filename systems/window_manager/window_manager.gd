extends Control
class_name WindowManager

@export_category("Dependencies")
@export var window_base_scene: PackedScene

var open_windows: Dictionary = {} # app_id -> WindowBase
var saved_window_states: Dictionary = {} # app_id -> Dictionary { position, size }


func _ready() -> void:
	# HOTFIX:
	# WindowManager fica em Full Rect por cima do Desktop.
	# Se ele consumir mouse, ele bloqueia botões/ícones do desktop fora das janelas.
	# Com IGNORE, áreas vazias passam clique para o Desktop,
	# mas as janelas filhas continuam recebendo input normalmente.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	GlobalSignals.request_open_app.connect(_on_request_open_app)
	GlobalSignals.request_close_app.connect(close_window)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		cycle_windows()
		get_viewport().set_input_as_handled()


func _on_request_open_app(app: AppResource) -> void:
	if app == null:
		return

	var app_id: String = app.app_id

	if open_windows.has(app_id):
		focus_window(app_id)
		return

	var window_size: Vector2 = app.default_window_size
	var min_window_size: Vector2 = app.min_window_size
	var can_resize: bool = app.can_resize

	var new_window: WindowBase = window_base_scene.instantiate() as WindowBase
	add_child(new_window)

	new_window.setup(
		app.app_id,
		app.app_name,
		window_size,
		min_window_size,
		can_resize
	)

	open_windows[app_id] = new_window

	if app.app_scene:
		var app_instance: Node = app.app_scene.instantiate()
		new_window.content_container.add_child(app_instance)

	_apply_saved_or_default_window_state(app_id, new_window)

	new_window.window_focused.connect(focus_window.bind(app_id))
	new_window.window_closed.connect(_on_window_closed.bind(app_id))
	new_window.window_moved.connect(_on_window_changed.bind(app_id))
	new_window.window_resized.connect(_on_window_changed.bind(app_id))

	focus_window(app_id)


func focus_window(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]
	window.move_to_front()
	window.pulse()


func close_window(app_id: String) -> void:
	if open_windows.has(app_id):
		open_windows[app_id].close()


func _on_window_closed(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]
	_save_window_state(app_id, window)

	open_windows.erase(app_id)
	window.queue_free()


func _on_window_changed(app_id: String) -> void:
	if not open_windows.has(app_id):
		return

	var window: WindowBase = open_windows[app_id]
	_clamp_window_to_screen(window)
	_save_window_state(app_id, window)


func cycle_windows() -> void:
	if open_windows.size() <= 1:
		return

	for child in get_children():
		if child is WindowBase:
			child.move_to_front()
			child.pulse()
			break


func _apply_saved_or_default_window_state(app_id: String, window: WindowBase) -> void:
	if saved_window_states.has(app_id):
		var state: Dictionary = saved_window_states[app_id]

		if state.has("size"):
			window.size = _enforce_min_size(state["size"], window.min_window_size)

		if state.has("position"):
			window.position = state["position"]
	else:
		window.position = (size - window.size) / 2.0

	_clamp_window_to_screen(window)
	_save_window_state(app_id, window)


func _save_window_state(app_id: String, window: WindowBase) -> void:
	if window.is_maximized:
		saved_window_states[app_id] = {
			"position": window.restore_position,
			"size": window.restore_size
		}
		return

	saved_window_states[app_id] = {
		"position": window.position,
		"size": window.size
	}


func _clamp_window_to_screen(window: WindowBase) -> void:
	var parent_size: Vector2 = size

	if parent_size.x <= 0 or parent_size.y <= 0:
		parent_size = get_viewport_rect().size

	var max_position: Vector2 = Vector2(
		max(0.0, parent_size.x - window.size.x),
		max(0.0, parent_size.y - window.size.y)
	)

	window.position = Vector2(
		clamp(window.position.x, 0.0, max_position.x),
		clamp(window.position.y, 0.0, max_position.y)
	)


func _enforce_min_size(value: Vector2, min_size: Vector2) -> Vector2:
	return Vector2(
		max(value.x, min_size.x),
		max(value.y, min_size.y)
	)
