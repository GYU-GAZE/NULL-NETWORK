extends Control
class_name KubuBottomDock

@export_category("Dock Scenes")
@export var dock_item_scene: PackedScene

@export_category("App Rail")
@export var rail_width: float = 40.0

@export_category("Boot Animation")
@export var item_spawn_delay: float = 0.06
@export var item_fade_duration: float = 0.18

@onready var sidebar_margin: MarginContainer = $SidebarMargin
@onready var app_container: VBoxContainer = %AppContainer
@onready var dock_panel: PanelContainer = $SidebarMargin/DockPanel

var _items_by_app_id: Dictionary = {}
var _badge_states_by_app_id: Dictionary = {}
var _focused_app_id: String = ""
var _active_workspace_id: String = ""
var _dock_locked: bool = false
var _dock_lock_reason: String = ""
var _shell_reveal_tween: Tween

func _ready() -> void:
	_connect_global_signals()
	if not KubuOSMetrics.metrics_changed.is_connected(_apply_metrics):
		KubuOSMetrics.metrics_changed.connect(_apply_metrics)
	_register_work_area_reservation()
	_apply_metrics()
	_sync_dock()

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
	if not GlobalSignals.app_badge_count_changed.is_connected(set_app_badge):
		GlobalSignals.app_badge_count_changed.connect(set_app_badge)
	if not GlobalSignals.app_badge_dot_changed.is_connected(set_app_dot_badge):
		GlobalSignals.app_badge_dot_changed.connect(set_app_dot_badge)
	if not GlobalSignals.app_badge_icon_changed.is_connected(set_app_icon_badge):
		GlobalSignals.app_badge_icon_changed.connect(set_app_icon_badge)
	if not CampaignState.app_installed.is_connected(_on_app_installed):
		CampaignState.app_installed.connect(_on_app_installed)
	if not CampaignState.campaign_changed.is_connected(_on_campaign_changed):
		CampaignState.campaign_changed.connect(_on_campaign_changed)
	if not ContentRegistry.registry_rebuilt.is_connected(_on_registry_rebuilt):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)

func _register_work_area_reservation() -> void:
	var desired_width: float = maxf(32.0, rail_width)
	if is_equal_approx(KubuOSMetrics.reserved_left_width, desired_width):
		return
	KubuOSMetrics.reserved_left_width = desired_width
	KubuOSMetrics.emit_changed()

func _apply_metrics() -> void:
	var rail_width_from_metrics: float = maxf(32.0, KubuOSMetrics.reserved_left_width)
	sidebar_margin.anchor_left = 0.0
	sidebar_margin.anchor_top = 0.0
	sidebar_margin.anchor_right = 0.0
	sidebar_margin.anchor_bottom = 1.0
	sidebar_margin.offset_left = 0.0
	sidebar_margin.offset_top = KubuOSMetrics.taskbar_height
	sidebar_margin.offset_right = rail_width_from_metrics
	sidebar_margin.offset_bottom = 0.0
	dock_panel.custom_minimum_size = Vector2(rail_width_from_metrics, 0.0)

func _sync_dock() -> void:
	if dock_item_scene == null:
		push_error("KubuBottomDock: dock_item_scene is not configured.")
		return
	var catalog: AppCatalog = ContentRegistry.get_app_catalog()
	if catalog == null:
		push_error("KubuBottomDock: AppCatalog is not configured.")
		return
	var desired_apps: Array[AppResource] = []
	var desired_ids: Dictionary = {}
	for app: AppResource in catalog.get_ordered_apps():
		var app_id: String = app.app_id.strip_edges()
		if not app.show_in_dock or not CampaignState.has_installed_app(app_id):
			continue
		desired_apps.append(app)
		desired_ids[app_id] = true
	for raw_app_id: Variant in _items_by_app_id.keys():
		var existing_id: String = str(raw_app_id)
		if not desired_ids.has(existing_id):
			_remove_item(existing_id)
	for index: int in range(desired_apps.size()):
		var app: AppResource = desired_apps[index]
		var app_id: String = app.app_id.strip_edges()
		var item: KubuDockItem = _get_item(app_id)
		if item == null:
			item = _create_item(app, index)
		if item != null and item.get_index() != index:
			app_container.move_child(item, index)

func _create_item(app: AppResource, index: int) -> KubuDockItem:
	var item := dock_item_scene.instantiate() as KubuDockItem
	if item == null:
		push_error("KubuBottomDock: dock_item_scene did not instantiate KubuDockItem.")
		return null
	app_container.add_child(item)
	item.setup(app)
	item.activated.connect(_on_item_activated)
	var app_id: String = app.app_id.strip_edges()
	_items_by_app_id[app_id] = item
	item.set_locked(_dock_locked)
	item.set_running(_focused_app_id == app_id or _active_workspace_id == app_id)
	item.set_focused(_focused_app_id == app_id or _active_workspace_id == app_id)
	_apply_saved_badge(app_id, item)
	_play_item_spawn_animation(item, index)
	return item

func _remove_item(app_id: String) -> void:
	var item: KubuDockItem = _get_item(app_id)
	if item == null:
		return
	_items_by_app_id.erase(app_id)
	app_container.remove_child(item)
	item.queue_free()

func get_visible_app_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for child: Node in app_container.get_children():
		var item := child as KubuDockItem
		if item != null and item.app_data != null:
			result.append(item.app_data.app_id.strip_edges())
	return result

func has_app_item(app_id: String) -> bool:
	return _items_by_app_id.has(app_id.strip_edges())

func _on_item_activated(app: AppResource) -> void:
	if app == null:
		return
	if _dock_locked and not app.available_while_locked:
		return
	match app.presentation_mode:
		AppResource.PresentationMode.WINDOW:
			GlobalSignals.request_open_app.emit(app)
		AppResource.PresentationMode.WORKSPACE:
			GlobalSignals.request_activate_workspace.emit(app)

func _on_app_opened(app_id: String) -> void:
	var item: KubuDockItem = _get_item(app_id)
	if item != null:
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

func _on_dock_lock_changed(locked: bool, reason: String) -> void:
	set_locked(locked, reason)

func _on_app_installed(_app_id: String) -> void:
	_sync_dock()

func _on_campaign_changed(section: StringName) -> void:
	if section in [&"campaign", &"installed_apps"]:
		_sync_dock()

func _on_registry_rebuilt() -> void:
	_sync_dock()

func set_locked(locked: bool, reason: String = "") -> void:
	_dock_locked = locked
	_dock_lock_reason = reason
	for value: Variant in _items_by_app_id.values():
		var item := value as KubuDockItem
		if item != null:
			item.set_locked(_dock_locked)

func set_app_badge(app_id: String, count: int) -> void:
	var clean_id: String = app_id.strip_edges()
	if clean_id.is_empty():
		return
	if count <= 0:
		clear_app_badge(clean_id)
		return
	_badge_states_by_app_id[clean_id] = {
		"mode": KubuDockItem.BadgeMode.COUNT,
		"count": count
	}
	var item: KubuDockItem = _get_item(clean_id)
	if item != null:
		item.set_badge_count(count)

func set_app_dot_badge(app_id: String, visible: bool = true) -> void:
	var clean_id: String = app_id.strip_edges()
	if clean_id.is_empty():
		return
	if not visible:
		clear_app_badge(clean_id)
		return
	_badge_states_by_app_id[clean_id] = {
		"mode": KubuDockItem.BadgeMode.DOT
	}
	var item: KubuDockItem = _get_item(clean_id)
	if item != null:
		item.set_badge_dot()

func set_app_icon_badge(app_id: String, icon: Texture2D) -> void:
	var clean_id: String = app_id.strip_edges()
	if clean_id.is_empty():
		return
	if icon == null:
		clear_app_badge(clean_id)
		return
	_badge_states_by_app_id[clean_id] = {
		"mode": KubuDockItem.BadgeMode.ICON,
		"icon": icon
	}
	var item: KubuDockItem = _get_item(clean_id)
	if item != null:
		item.set_badge_icon(icon)

func clear_app_badge(app_id: String) -> void:
	var clean_id: String = app_id.strip_edges()
	_badge_states_by_app_id.erase(clean_id)
	var item: KubuDockItem = _get_item(clean_id)
	if item != null:
		item.clear_badge()

func _apply_saved_badge(app_id: String, item: KubuDockItem) -> void:
	if item == null or not _badge_states_by_app_id.has(app_id):
		return
	var state: Dictionary = _badge_states_by_app_id[app_id]
	var mode: int = int(state.get("mode", KubuDockItem.BadgeMode.NONE))
	match mode:
		KubuDockItem.BadgeMode.COUNT:
			item.set_badge_count(int(state.get("count", 0)))
		KubuDockItem.BadgeMode.DOT:
			item.set_badge_dot()
		KubuDockItem.BadgeMode.ICON:
			item.set_badge_icon(state.get("icon") as Texture2D)
		_:
			item.clear_badge()

func get_lock_reason() -> String:
	return _dock_lock_reason

func prepare_shell_reveal(hidden_scale: Vector2 = Vector2(0.2, 1.0)) -> void:
	_kill_shell_reveal_tween()
	refresh_shell_reveal_pivot()
	dock_panel.show()
	dock_panel.modulate.a = 0.0
	dock_panel.scale = Vector2(clampf(hidden_scale.x, 0.01, 1.0), 1.0)

func refresh_shell_reveal_pivot() -> void:
	if not is_instance_valid(dock_panel):
		return
	dock_panel.pivot_offset = Vector2(0.0, dock_panel.size.y * 0.5)

func start_shell_reveal(duration: float) -> void:
	_kill_shell_reveal_tween()
	refresh_shell_reveal_pivot()
	dock_panel.show()
	var resolved_duration: float = maxf(0.01, duration)
	_shell_reveal_tween = create_tween().set_parallel(true)
	_shell_reveal_tween.set_trans(Tween.TRANS_BACK)
	_shell_reveal_tween.set_ease(Tween.EASE_OUT)
	_shell_reveal_tween.tween_property(dock_panel, "scale:x", 1.0, resolved_duration)
	_shell_reveal_tween.tween_property(
		dock_panel,
		"modulate:a",
		1.0,
		resolved_duration * 0.72
	).set_trans(Tween.TRANS_CUBIC)

func finish_shell_reveal() -> void:
	_kill_shell_reveal_tween()
	dock_panel.scale = Vector2.ONE
	dock_panel.modulate.a = 1.0

func _kill_shell_reveal_tween() -> void:
	if _shell_reveal_tween != null and _shell_reveal_tween.is_valid():
		_shell_reveal_tween.kill()
	_shell_reveal_tween = null

func _clear_item_focus() -> void:
	for value: Variant in _items_by_app_id.values():
		var item := value as KubuDockItem
		if item != null:
			item.set_focused(false)

func _get_item(app_id: String) -> KubuDockItem:
	var clean_id: String = app_id.strip_edges()
	if not _items_by_app_id.has(clean_id):
		return null
	return _items_by_app_id[clean_id] as KubuDockItem

func _play_item_spawn_animation(item: KubuDockItem, index: int) -> void:
	item.modulate.a = 0.0
	item.scale = Vector2(0.86, 0.86)
	item.pivot_offset = item.custom_minimum_size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	var delay: float = float(index) * item_spawn_delay
	tween.tween_property(item, "modulate:a", 1.0, item_fade_duration).set_delay(delay)
	tween.tween_property(item, "scale", Vector2.ONE, item_fade_duration).set_delay(delay)
