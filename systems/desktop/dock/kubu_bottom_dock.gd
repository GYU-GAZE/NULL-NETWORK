extends Control
class_name KubuBottomDock

@export_category("Dock Data")
@export var dock_apps: Array[AppResource] = []

@export_category("Dock Scenes")
@export var dock_item_scene: PackedScene

@export_category("Boot Animation")
@export var item_spawn_delay: float = 0.06
@export var item_fade_duration: float = 0.18

@onready var app_container: HBoxContainer = %AppContainer

var _items_by_app_id: Dictionary = {}
var _focused_app_id: String = ""
var _active_workspace_id: String = ""

var _dock_locked: bool = false
var _dock_lock_reason: String = ""


func _ready() -> void:
	_connect_global_signals()
	_build_dock()


func _connect_global_signals() -> void:
	if not GlobalSignals.app_opened.is_connected(_on_app_opened):
		GlobalSignals.app_opened.connect(_on_app_opened)

	if not GlobalSignals.app_closed.is_connected(_on_app_closed):
		GlobalSignals.app_closed.connect(_on_app_closed)

	if not GlobalSignals.app_focused.is_connected(_on_app_focused):
		GlobalSignals.app_focused.connect(_on_app_focused)

	if not GlobalSignals.workspace_activated.is_connected(_on_workspace_activated):
		GlobalSignals.workspace_activated.connect(_on_workspace_activated)

	if not GlobalSignals.dock_lock_changed.is_connected(_on_dock_lock_changed):
		GlobalSignals.dock_lock_changed.connect(_on_dock_lock_changed)


func _build_dock() -> void:
	_clear_dock()

	if dock_item_scene == null:
		push_error("KubuBottomDock: dock_item_scene is not configured.")
		return

	for index in range(dock_apps.size()):
		var app: AppResource = dock_apps[index]

		if app == null:
			push_warning(
				"KubuBottomDock: null AppResource at index %d."
				% index
			)
			continue

		if not app.show_in_dock:
			continue

		if app.app_id.strip_edges().is_empty():
			push_warning(
				"KubuBottomDock: app '%s' has an empty app_id."
				% app.app_name
			)
			continue

		var item: KubuDockItem = (
			dock_item_scene.instantiate()
			as KubuDockItem
		)

		if item == null:
			push_error(
				"KubuBottomDock: dock_item_scene did not instantiate KubuDockItem."
			)
			return

		app_container.add_child(item)
		item.setup(app)
		item.activated.connect(_on_item_activated)

		_items_by_app_id[app.app_id] = item

		item.set_locked(_dock_locked)
		_play_item_spawn_animation(item, index)


func _clear_dock() -> void:
	_items_by_app_id.clear()

	for child in app_container.get_children():
		child.queue_free()


func _on_item_activated(app: AppResource) -> void:
	if app == null:
		return

	if (
		_dock_locked
		and not app.available_while_locked
	):
		return

	match app.presentation_mode:
		AppResource.PresentationMode.WINDOW:
			GlobalSignals.request_open_app.emit(app)

		AppResource.PresentationMode.WORKSPACE:
			GlobalSignals.request_activate_workspace.emit(app.app_id)


func _on_app_opened(app_id: String) -> void:
	var item: KubuDockItem = _get_item(app_id)

	if item == null:
		return

	item.set_running(true)


func _on_app_closed(app_id: String) -> void:
	var item: KubuDockItem = _get_item(app_id)

	if item == null:
		return

	item.set_running(false)
	item.set_focused(false)

	if _focused_app_id == app_id:
		_focused_app_id = ""


func _on_app_focused(app_id: String) -> void:
	_focused_app_id = app_id
	_active_workspace_id = ""

	_clear_item_focus()

	var item: KubuDockItem = _get_item(app_id)

	if item != null:
		item.set_running(true)
		item.set_focused(true)


func _on_workspace_activated(workspace_id: String) -> void:
	_active_workspace_id = workspace_id
	_focused_app_id = ""

	_clear_item_focus()

	var item: KubuDockItem = _get_item(workspace_id)

	if item != null:
		item.set_focused(true)


func _on_dock_lock_changed(
	locked: bool,
	reason: String
) -> void:
	set_locked(locked, reason)


func set_locked(
	locked: bool,
	reason: String = ""
) -> void:
	_dock_locked = locked
	_dock_lock_reason = reason

	for value in _items_by_app_id.values():
		var item := value as KubuDockItem

		if item != null:
			item.set_locked(_dock_locked)


func set_app_badge(
	app_id: String,
	count: int
) -> void:
	var item: KubuDockItem = _get_item(app_id)

	if item == null:
		return

	item.set_badge_count(count)


func get_lock_reason() -> String:
	return _dock_lock_reason


func _clear_item_focus() -> void:
	for value in _items_by_app_id.values():
		var item := value as KubuDockItem

		if item != null:
			item.set_focused(false)


func _get_item(app_id: String) -> KubuDockItem:
	if not _items_by_app_id.has(app_id):
		return null

	return _items_by_app_id[app_id] as KubuDockItem


func _play_item_spawn_animation(
	item: KubuDockItem,
	index: int
) -> void:
	item.modulate.a = 0.0
	item.scale = Vector2(0.86, 0.86)
	item.pivot_offset = item.custom_minimum_size / 2.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	var delay: float = float(index) * item_spawn_delay

	tween.tween_property(
		item,
		"modulate:a",
		1.0,
		item_fade_duration
	).set_delay(delay)

	tween.tween_property(
		item,
		"scale",
		Vector2.ONE,
		item_fade_duration
	).set_delay(delay)
