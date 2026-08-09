extends Control
class_name BrowserApp
const SESSION_STATE_VERSION: int = 1

@export_category("Browser Scenes")
@export var tab_button_scene: PackedScene
@export var new_tab_button_scene: PackedScene
@export var error_page_scene: PackedScene

@export_category("Browser Routes")
@export var home_url: String = "home"

## Compatibility storage for older Browser scenes. Website Controls are now
## always hosted responsively by SiteContainer; individual pages no longer own a
## fixed 600x320 Browser viewport.
@export_storage var fallback_site_canvas_size: Vector2 = Vector2(600, 320)

@export_category("Tab Layout")
@export var tab_width: float = 160.0
@export var new_tab_button_width: float = 36.0
@export var tab_bar_reserved_margin: float = 24.0
@export var minimum_tab_scroll_width: float = 200.0

@export_category("Favorite Button")
@export var favorite_add_text: String = "☆"
@export var favorite_remove_text: String = "★"
@export var favorite_blocked_text: String = "☆"
@export var favorite_add_icon: Texture2D
@export var favorite_remove_icon: Texture2D
@export var favorite_blocked_icon: Texture2D
@export var favorite_add_tooltip: String = "Add favorite"
@export var favorite_remove_tooltip: String = "Remove favorite"
@export var favorite_blocked_tooltip: String = "This page cannot be favorited"

@onready var tab_button_container: HBoxContainer = %TabButtonContainer
@onready var new_tab_button_holder: MarginContainer = %NewTabButtonHolder
@onready var tab_scroll: ScrollContainer = %TabScroll

@onready var url_line_edit: LineEdit = %UrlLineEdit
@onready var go_button: Button = %GoButton
@onready var browser_back_btn: Button = %BrowserBackBtn
@onready var favorite_button: Button = %FavoriteButton

@onready var content_area: Control = %ContentArea
@onready var site_container: Control = %SiteContainer

var tabs: Array[BrowserTabData] = []
var current_tab_index: int = -1


func _ready() -> void:
	_apply_browser_shell_layout()

	go_button.pressed.connect(_on_go_pressed)
	url_line_edit.text_submitted.connect(_load_page)
	browser_back_btn.pressed.connect(_on_browser_back_pressed)
	favorite_button.pressed.connect(_on_favorite_pressed)

	if not resized.is_connected(_refresh_tab_layout_only):
		resized.connect(_refresh_tab_layout_only)

	_connect_browser_navigation_signals(self)

	if not GlobalSignals.request_browser_navigation.is_connected(
		_on_story_browser_navigation_requested
	):
		GlobalSignals.request_browser_navigation.connect(
			_on_story_browser_navigation_requested
		)

	_create_tab(home_url)


func _apply_browser_shell_layout() -> void:
	custom_minimum_size = Vector2.ZERO
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true

	content_area.custom_minimum_size = Vector2.ZERO
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.clip_contents = true

	site_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	site_container.custom_minimum_size = Vector2.ZERO
	site_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	site_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	site_container.clip_contents = true


func _on_story_browser_navigation_requested(
	url: String,
	event_id: String,
	step_id: String
) -> void:
	_load_page(url)
	GlobalSignals.story_event_step_completed.emit(
		event_id,
		step_id,
		true
	)


func _on_go_pressed() -> void:
	_load_page(url_line_edit.text)


func _create_tab(start_url: String = "") -> void:
	_save_current_site_state()

	var tab := BrowserTabData.new()
	tabs.append(tab)
	current_tab_index = tabs.size() - 1

	if start_url.is_empty():
		_clear_site_container()
		url_line_edit.text = ""
		_refresh_tab_buttons()
		_refresh_favorite_button()
		return

	_load_page(start_url)


func _close_tab(tab_index: int) -> void:
	if tabs.size() <= 1:
		return

	if tab_index < 0 or tab_index >= tabs.size():
		return

	if tab_index == current_tab_index:
		_save_current_site_state()

	tabs.remove_at(tab_index)

	if tab_index < current_tab_index:
		current_tab_index -= 1
	elif tab_index == current_tab_index:
		current_tab_index = min(tab_index, tabs.size() - 1)

	_render_current_tab()
	_refresh_tab_buttons()
	_refresh_favorite_button()


func _switch_tab(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= tabs.size():
		return

	if tab_index == current_tab_index:
		return

	_save_current_site_state()
	current_tab_index = tab_index

	_render_current_tab()
	_refresh_tab_buttons()
	_refresh_favorite_button()


func _get_current_tab() -> BrowserTabData:
	if current_tab_index < 0 or current_tab_index >= tabs.size():
		_create_tab()

	return tabs[current_tab_index]


func _refresh_tab_buttons() -> void:
	_clear_control_children(tab_button_container)
	_clear_control_children(new_tab_button_holder)
	_refresh_tab_layout_only()

	if tab_button_scene == null:
		push_error("BrowserApp: tab_button_scene is not configured.")
		return

	for i in range(tabs.size()):
		var tab: BrowserTabData = tabs[i]
		var tab_button := tab_button_scene.instantiate() as BrowserTabButton

		if tab_button == null:
			push_error("BrowserApp: tab_button_scene must instantiate BrowserTabButton.")
			continue

		tab_button_container.add_child(tab_button)
		tab_button.setup(
			i,
			tab.page_title,
			tab.favicon,
			i == current_tab_index,
			tabs.size() > 1,
			tab_width
		)
		tab_button.tab_selected.connect(_switch_tab)
		tab_button.tab_close_requested.connect(_close_tab)

	if new_tab_button_scene == null:
		push_error("BrowserApp: new_tab_button_scene is not configured.")
		return

	var new_tab_button := new_tab_button_scene.instantiate() as Button

	if new_tab_button == null:
		push_error("BrowserApp: new_tab_button_scene must instantiate Button.")
		return

	new_tab_button.custom_minimum_size.x = new_tab_button_width
	new_tab_button.pressed.connect(func(): _create_tab(home_url))
	new_tab_button_holder.add_child(new_tab_button)


func _load_page(target_url: String, is_history_nav: bool = false) -> void:
	var clean_url: String = SimulatedDNS.normalize_url(target_url)

	if clean_url.is_empty():
		return

	var tab := _get_current_tab()

	if not is_history_nav:
		_save_current_site_state()
		tab.clear_site_state()

	var page: WebsitePage = SimulatedDNS.fetch_page(clean_url)

	if page != null:
		tab.set_page_title(page.page_title)
		tab.set_favicon(page.favicon)
	else:
		tab.set_page_title(clean_url)
		tab.set_favicon(null)

	if page != null and page.record_in_browser_history:
		GameState.register_browser_visit(clean_url, tab.page_title, tab.favicon)

	if not is_history_nav:
		tab.navigate_to(clean_url, tab.page_title, tab.favicon)
	else:
		tab.current_url = clean_url

	url_line_edit.text = clean_url

	_render_url(clean_url)
	_refresh_tab_buttons()
	_refresh_favorite_button()


func _render_current_tab() -> void:
	var tab := _get_current_tab()
	url_line_edit.text = tab.current_url

	if tab.current_url.is_empty():
		_clear_site_container()
		_refresh_favorite_button()
		return

	_render_url(tab.current_url)
	_refresh_favorite_button()


func _render_url(target_url: String) -> void:
	_clear_site_container()

	var page: WebsitePage = SimulatedDNS.fetch_page(target_url)

	if page == null:
		_render_error_page(
			"403",
			"CONNECTION REFUSED",
			"The server refused the connection or the domain does not exist.",
			target_url
		)
		return

	var tab := _get_current_tab()
	tab.set_page_title(page.page_title)
	tab.set_favicon(page.favicon)

	if page.site_scene == null:
		tab.clear_site_state()
		_render_error_page(
			"500",
			"PAGE SCENE MISSING",
			"The route exists, but its WebsitePage has no site_scene configured.",
			page.url
		)
		_refresh_tab_buttons()
		_refresh_favorite_button()
		return

	_render_site(page.site_scene, tab.site_state)
	_refresh_tab_buttons()
	_refresh_favorite_button()


func _on_browser_back_pressed() -> void:
	if site_container.get_child_count() > 0:
		var current_site: Node = site_container.get_child(0)

		if current_site.has_method("handle_browser_back"):
			var handled_by_site: bool = bool(current_site.call("handle_browser_back"))

			if handled_by_site:
				_save_current_site_state()
				_refresh_favorite_button()
				return

	var tab := _get_current_tab()

	if tab.can_go_back():
		var previous_url: String = tab.go_back()
		_load_page(previous_url, true)


func _on_favorite_pressed() -> void:
	var tab := _get_current_tab()

	if tab.current_url.is_empty() or _is_home_url(tab.current_url):
		return

	GameState.toggle_browser_site_pin(
		tab.current_url,
		tab.page_title,
		tab.favicon
	)

	_refresh_favorite_button()


func _refresh_favorite_button() -> void:
	if not is_instance_valid(favorite_button):
		return

	var tab := _get_current_tab()

	if tab.current_url.is_empty() or _is_home_url(tab.current_url):
		_apply_favorite_button_visual(
			false,
			favorite_blocked_text,
			favorite_blocked_icon,
			favorite_blocked_tooltip
		)
		return

	if GameState.is_browser_site_pinned(tab.current_url):
		_apply_favorite_button_visual(
			true,
			favorite_remove_text,
			favorite_remove_icon,
			favorite_remove_tooltip
		)
	else:
		_apply_favorite_button_visual(
			true,
			favorite_add_text,
			favorite_add_icon,
			favorite_add_tooltip
		)


func _apply_favorite_button_visual(
	enabled: bool,
	button_text: String,
	button_icon: Texture2D,
	tooltip: String
) -> void:
	favorite_button.disabled = not enabled
	favorite_button.text = button_text
	favorite_button.icon = button_icon
	favorite_button.tooltip_text = tooltip


func _save_current_site_state() -> void:
	if current_tab_index < 0 or current_tab_index >= tabs.size():
		return

	var tab := tabs[current_tab_index]

	if site_container.get_child_count() <= 0:
		tab.clear_site_state()
		return

	var current_site: Node = site_container.get_child(0)

	if not current_site.has_method("get_browser_state"):
		tab.clear_site_state()
		return

	var returned_state: Variant = current_site.call("get_browser_state")

	if returned_state is Dictionary:
		tab.site_state = (returned_state as Dictionary).duplicate(true)
	else:
		tab.clear_site_state()


func _clear_site_container() -> void:
	_clear_control_children(site_container)


func _render_error_page(
	error_code: String,
	error_title: String,
	error_message: String,
	requested_url: String
) -> void:
	if error_page_scene != null:
		var instance: Node = error_page_scene.instantiate()

		if instance != null:
			site_container.add_child(instance)
			_configure_site_control(instance)

			if instance.has_method("setup"):
				instance.call(
					"setup",
					error_code,
					error_title,
					error_message,
					requested_url
				)

			return

	var fallback_label := Label.new()
	fallback_label.text = "%s: %s\n\n%s\n\n%s" % [
		error_code,
		error_title,
		error_message,
		requested_url
	]
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	site_container.add_child(fallback_label)
	_configure_site_control(fallback_label)


func _render_site(
	scene: PackedScene,
	state: Dictionary = {}
) -> void:
	var instance: Node = scene.instantiate()

	if instance == null:
		_render_error_page(
			"500",
			"PAGE INSTANTIATION FAILED",
			"The configured page scene could not be instantiated.",
			_get_current_tab().current_url
		)
		return

	site_container.add_child(instance)
	_configure_site_control(instance)
	_connect_browser_navigation_signals(instance)

	var tab := _get_current_tab()

	if instance.has_method("set_browser_url"):
		instance.call_deferred("set_browser_url", tab.current_url)

	if instance.has_method("restore_browser_state"):
		instance.call_deferred("restore_browser_state", state.duplicate(true))


func _configure_site_control(instance: Node) -> void:
	if not instance is Control:
		return

	# Browser owns the viewport contract for every WebsitePage. The previous code
	# forced every page to its authored 600x320 canvas and SHRINK_BEGIN, so only
	# pages carrying their own deferred AdaptiveBrowserPageLayout escaped the
	# top-left fixed-size box. Full-rect anchors make all sites follow Browser
	# resize/maximize automatically without page-specific scripts.
	var control := instance as Control
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.custom_minimum_size = Vector2.ZERO
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _refresh_tab_layout_only() -> void:
	if not is_instance_valid(tab_scroll):
		return

	var tab_count: int = tabs.size()
	var tab_spacing: float = 0.0

	if is_instance_valid(tab_button_container):
		tab_spacing = float(tab_button_container.get_theme_constant("separation")) * float(max(0, tab_count - 1))

	var total_tabs_width: float = (tab_width * float(tab_count)) + tab_spacing
	var max_scroll_width: float = max(
		minimum_tab_scroll_width,
		size.x - new_tab_button_width - tab_bar_reserved_margin
	)

	tab_scroll.custom_minimum_size.x = min(total_tabs_width, max_scroll_width)
	tab_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN


func _connect_browser_navigation_signals(root: Node) -> void:
	if root.has_signal("browser_navigation_requested"):
		var navigation_callable := Callable(self, "_load_page")

		if not root.is_connected("browser_navigation_requested", navigation_callable):
			root.connect("browser_navigation_requested", navigation_callable)

		return

	for child in root.get_children():
		_connect_browser_navigation_signals(child)


func _clear_control_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _is_home_url(url: String) -> bool:
	return SimulatedDNS.normalize_url(url) == SimulatedDNS.normalize_url(home_url)


func get_app_session_state() -> Dictionary:
	_save_current_site_state()

	var serialized_tabs: Array[Dictionary] = []

	for tab in tabs:
		if tab == null:
			continue

		serialized_tabs.append(tab.to_session_state())

	return {
		"version": SESSION_STATE_VERSION,
		"current_tab_index": current_tab_index,
		"tabs": serialized_tabs
	}


func restore_app_session_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	var saved_version: int = int(state.get("version", 0))

	if saved_version > SESSION_STATE_VERSION:
		push_warning(
			"BrowserApp: session version %d is newer than supported version %d."
			% [saved_version, SESSION_STATE_VERSION]
		)
		return

	var raw_tabs: Variant = state.get("tabs", [])

	if not raw_tabs is Array:
		push_warning("BrowserApp: stored tabs value is not an Array.")
		return

	var restored_tabs: Array[BrowserTabData] = []

	for raw_tab_state in raw_tabs:
		if not raw_tab_state is Dictionary:
			continue

		var restored_tab: BrowserTabData = (
			BrowserTabData.from_session_state(
				raw_tab_state as Dictionary
			)
		)

		if restored_tab != null:
			restored_tabs.append(restored_tab)

	if restored_tabs.is_empty():
		return

	tabs = restored_tabs
	current_tab_index = clampi(
		int(state.get("current_tab_index", 0)),
		0,
		tabs.size() - 1
	)

	_clear_site_container()
	_render_current_tab()
	_refresh_tab_buttons()
	_refresh_favorite_button()
