extends Control
class_name BrowserApp

const SESSION_STATE_VERSION: int = 2

@export_category("Browser Scenes")
@export var tab_button_scene: PackedScene
@export var new_tab_button_scene: PackedScene
@export var error_page_scene: PackedScene

@export_category("Browser Routes")
@export var home_url: String = "home"

@export_category("Tab Layout")
@export var tab_width: float = 112.0
@export var minimum_tab_width: float = 78.0
@export var new_tab_button_width: float = 18.0
@export var tab_bar_reserved_margin: float = 2.0

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

@onready var motion_player: UiMotionPlayer = %MotionPlayer
@onready var tab_bar_margin: MarginContainer = %TabBarMargin
@onready var address_bar_margin: MarginContainer = %AddressBarMargin
@onready var tab_button_container: HBoxContainer = %TabButtonContainer
@onready var new_tab_button_holder: MarginContainer = %NewTabButtonHolder
@onready var tab_scroll: ScrollContainer = %TabScroll
@onready var url_line_edit: LineEdit = %UrlLineEdit
@onready var go_button: Button = %GoButton
@onready var browser_back_btn: Button = %BrowserBackBtn
@onready var browser_forward_btn: Button = %BrowserForwardBtn
@onready var favorite_button: Button = %FavoriteButton
@onready var content_area: Control = %ContentArea
@onready var site_container: Control = %SiteContainer
@onready var page_scroll: ScrollContainer = %PageScroll
@onready var scroll_site_container: BrowserPageScrollHost = %ScrollSiteContainer

var tabs: Array[BrowserTabData] = []
var current_tab_index: int = -1
var _tab_buttons: Array[BrowserTabButton] = []
var _new_tab_button: Button
var _tab_overflow_active: bool = false
var _navigation_locked: bool = false
var _navigation_revision: int = 0
var _active_site: Control
var _active_surface: BrowserPageSurface
var _outgoing_surface: BrowserPageSurface
var _incoming_surface: BrowserPageSurface
var _active_context: BrowserPageContext
var _active_policy: WebsitePage.OverflowPolicy = WebsitePage.OverflowPolicy.PAGE_SCROLL
var _active_url: String = ""
var _active_entry: BrowserHistoryEntry
var _pending_scroll_y: int = -1
var _tab_layout_queued: bool = false
var _tab_close_in_progress: bool = false


func _ready() -> void:
	_apply_browser_shell_layout()
	go_button.pressed.connect(_on_go_pressed)
	url_line_edit.text_submitted.connect(_load_page)
	browser_back_btn.pressed.connect(_on_browser_back_pressed)
	browser_forward_btn.pressed.connect(_on_browser_forward_pressed)
	favorite_button.pressed.connect(_on_favorite_pressed)
	resized.connect(_queue_tab_layout_refresh)
	tab_scroll.resized.connect(_queue_tab_layout_refresh)
	var chrome_context := BrowserPageContext.new()
	add_child(chrome_context)
	set_meta(BrowserPageContext.META, chrome_context)
	chrome_context.navigation_requested.connect(_load_page)
	page_scroll.get_v_scroll_bar().changed.connect(_restore_pending_scroll)
	page_scroll.scroll_started.connect(func() -> void: _pending_scroll_y = -1)
	if not GlobalSignals.request_browser_navigation.is_connected(_on_story_browser_navigation_requested):
		GlobalSignals.request_browser_navigation.connect(_on_story_browser_navigation_requested)
	_ensure_new_tab_button()
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
	site_container.clip_contents = true
	page_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_scroll.visible = false
	var scrollbar := tab_scroll.get_h_scroll_bar()
	scrollbar.custom_minimum_size.y = 2.0


func _on_story_browser_navigation_requested(url: String, event_id: String, step_id: String) -> void:
	_load_page(url)
	GlobalSignals.story_event_step_completed.emit(event_id, step_id, true)


func _on_go_pressed() -> void:
	_load_page(url_line_edit.text)


func _create_tab(start_url: String = "") -> void:
	_save_current_site_state()
	var tab := BrowserTabData.new()
	tabs.append(tab)
	current_tab_index = tabs.size() - 1
	_sync_tab_buttons(true)
	if start_url.is_empty():
		_clear_site_containers()
		url_line_edit.text = ""
		_refresh_favorite_button()
		return
	_load_page(start_url)


func _close_tab(tab_index: int) -> void:
	if _tab_close_in_progress or tabs.size() <= 1 or tab_index < 0 or tab_index >= tabs.size():
		return
	_tab_close_in_progress = true
	var closing_tab := tabs[tab_index]
	var closed_current := tab_index == current_tab_index
	if closed_current:
		_save_current_site_state()
	var closing_button: BrowserTabButton = _tab_buttons[tab_index]
	await motion_player.exit_scaled_control(closing_button, Vector2(0.92, 0.82), Vector2(0, -2), 0.10)
	tab_index = tabs.find(closing_tab)
	if tab_index < 0:
		_tab_close_in_progress = false
		return
	closed_current = current_tab_index == tab_index
	if closed_current:
		_save_current_site_state()
	if is_instance_valid(closing_button):
		tab_button_container.remove_child(closing_button)
		closing_button.queue_free()
	_tab_buttons.remove_at(tab_index)
	tabs.remove_at(tab_index)
	if tab_index < current_tab_index:
		current_tab_index -= 1
	elif tab_index == current_tab_index:
		current_tab_index = mini(tab_index, tabs.size() - 1)
	_sync_tab_buttons()
	_tab_close_in_progress = false
	if closed_current:
		_render_current_tab(false)


func _switch_tab(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= tabs.size() or tab_index == current_tab_index:
		return
	_save_current_site_state()
	var forward := tab_index > current_tab_index
	current_tab_index = tab_index
	_sync_tab_buttons()
	_render_current_tab(forward)


func _get_current_tab() -> BrowserTabData:
	if current_tab_index < 0 or current_tab_index >= tabs.size():
		push_error("BrowserApp: current tab index is invalid.")
		return null
	return tabs[current_tab_index]


func _ensure_new_tab_button() -> void:
	if is_instance_valid(_new_tab_button):
		return
	if new_tab_button_scene == null:
		push_error("BrowserApp: new_tab_button_scene is not configured.")
		return
	_new_tab_button = new_tab_button_scene.instantiate() as Button
	if _new_tab_button == null:
		push_error("BrowserApp: new_tab_button_scene must instantiate Button.")
		return
	_new_tab_button.custom_minimum_size.x = new_tab_button_width
	_new_tab_button.pressed.connect(func() -> void: _create_tab(home_url))
	new_tab_button_holder.add_child(_new_tab_button)


func _sync_tab_buttons(animate_new: bool = false) -> void:
	if tab_button_scene == null:
		push_error("BrowserApp: tab_button_scene is not configured.")
		return
	while _tab_buttons.size() < tabs.size():
		var tab_button := tab_button_scene.instantiate() as BrowserTabButton
		if tab_button == null:
			push_error("BrowserApp: tab_button_scene must instantiate BrowserTabButton.")
			return
		tab_button_container.add_child(tab_button)
		tab_button.tab_selected.connect(_switch_tab)
		tab_button.tab_close_requested.connect(_close_tab)
		_tab_buttons.append(tab_button)
		if animate_new and is_inside_tree():
			motion_player.enter_scaled_control(tab_button, Vector2(0.9, 0.72), Vector2(0, 2), 0.12)
	while _tab_buttons.size() > tabs.size():
		var stale: BrowserTabButton = _tab_buttons.pop_back()
		if is_instance_valid(stale):
			stale.queue_free()
	var resolved_width := _calculate_tab_width()
	for i in range(_tab_buttons.size()):
		var tab: BrowserTabData = tabs[i]
		_tab_buttons[i].setup(i, tab.page_title, tab.favicon, i == current_tab_index, tabs.size() > 1, resolved_width)
	_queue_tab_layout_refresh()


func _calculate_tab_width() -> float:
	if tabs.is_empty():
		return tab_width
	var available := _get_available_tab_strip_width()
	var separation := float(tab_button_container.get_theme_constant("separation"))
	var total_spacing := separation * float(maxi(0, tabs.size() - 1))
	return clampf(floor((available - total_spacing) / float(tabs.size())), minimum_tab_width, tab_width)


func _queue_tab_layout_refresh() -> void:
	if _tab_layout_queued:
		return
	_tab_layout_queued = true
	call_deferred("_refresh_tab_layout_only")


func _refresh_tab_layout_only() -> void:
	_tab_layout_queued = false
	if not is_instance_valid(tab_scroll) or tabs.is_empty():
		return
	var resolved_width := _calculate_tab_width()
	for i in range(mini(_tab_buttons.size(), tabs.size())):
		var tab: BrowserTabData = tabs[i]
		_tab_buttons[i].setup(i, tab.page_title, tab.favicon, i == current_tab_index, tabs.size() > 1, resolved_width)
	var required_width := get_required_tab_content_width()
	var available_width := _get_available_tab_strip_width()
	_tab_overflow_active = required_width > available_width + 0.5
	tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if _tab_overflow_active else ScrollContainer.SCROLL_MODE_DISABLED
	if not _tab_overflow_active:
		tab_scroll.scroll_horizontal = 0


func _get_available_tab_strip_width() -> float:
	var new_tab_width := maxf(new_tab_button_width, new_tab_button_holder.get_combined_minimum_size().x)
	var chrome_separation := 0.0
	var tab_bar := tab_scroll.get_parent() as BoxContainer
	if tab_bar != null:
		chrome_separation = float(tab_bar.get_theme_constant("separation"))
	return maxf(1.0, size.x - new_tab_width - chrome_separation - tab_bar_reserved_margin)


func _load_page(target_url: String, is_history_nav: bool = false, forward: bool = true) -> void:
	var clean_url: String = SimulatedDNS.normalize_url(target_url)
	if clean_url.is_empty():
		return
	var tab := _get_current_tab()
	if tab == null:
		return
	if not is_history_nav:
		_save_current_site_state()
	var page: WebsitePage = SimulatedDNS.fetch_page(clean_url)
	var title: String = page.page_title if page != null else clean_url
	var icon: Texture2D = page.favicon if page != null else null
	if not is_history_nav:
		tab.navigate_to(clean_url, title, icon)
	else:
		tab.set_page_title(title)
		tab.set_favicon(icon)
	if page != null and page.record_in_browser_history:
		GameState.register_browser_visit(clean_url, title, icon)
	url_line_edit.text = clean_url
	_sync_tab_buttons()
	_refresh_favorite_button()
	_present_url(clean_url, page, forward)


func _render_current_tab(forward: bool = true) -> void:
	var tab := _get_current_tab()
	if tab == null:
		return
	url_line_edit.text = tab.current_url
	if tab.current_url.is_empty():
		_clear_site_containers()
		_refresh_favorite_button()
		return
	_present_url(tab.current_url, SimulatedDNS.fetch_page(tab.current_url), forward)
	_refresh_favorite_button()


func _present_url(target_url: String, page: WebsitePage, forward: bool) -> void:
	_cancel_navigation_transition()
	_navigation_locked = true
	var revision := _navigation_revision
	_set_chrome_interaction(false)
	var next_instance: Node
	var policy := WebsitePage.OverflowPolicy.FIXED_VIEWPORT
	if page == null:
		next_instance = _build_error_page("403", "CONNECTION REFUSED", "The server refused the connection or the domain does not exist.", target_url)
	elif page.site_scene == null:
		next_instance = _build_error_page("500", "PAGE SCENE MISSING", "The route exists, but has no page scene.", target_url)
	else:
		next_instance = page.site_scene.instantiate()
		policy = page.overflow_policy
	if next_instance is not Control:
		if next_instance != null:
			next_instance.free()
		next_instance = _build_fallback_error("500", "INVALID PAGE ROOT", target_url)
	if is_instance_valid(_active_context):
		_active_context.enabled = false
	_outgoing_surface = _active_surface
	var old_policy := _active_policy
	_active_policy = policy
	_active_url = target_url
	_active_entry = _get_current_tab().current_entry()
	_active_site = next_instance as Control
	_incoming_surface = BrowserPageSurface.new()
	_incoming_surface.name = "PageSurface"
	_incoming_surface.size = content_area.size.floor()
	_active_surface = _incoming_surface
	_active_context = BrowserPageContext.new()
	_active_context.url = target_url
	_active_context.enabled = false
	_incoming_surface.add_child(_active_context)
	var context := _active_context
	context.navigation_requested.connect(func(url: String) -> void:
		if context == _active_context and context.enabled:
			_load_page(url)
	)
	_get_host_for_policy(policy).add_child(_incoming_surface)
	_active_context.bind_page(_active_site)
	_incoming_surface.mount(_active_site, policy == WebsitePage.OverflowPolicy.PAGE_SCROLL)
	_set_active_host(policy)
	if _active_site.has_method("set_browser_url"):
		_active_site.call("set_browser_url", target_url)
	if _active_entry != null:
		await _active_context.restore_state(_active_entry.page_state.duplicate(true))
	if revision != _navigation_revision:
		return
	_pending_scroll_y = _active_entry.scroll_y if _active_entry != null else 0
	# Scroll range is calculated by Containers after mounting/restoring content.
	# Listen for range changes and schedule one layout-bound application, not a
	# frame loop. The transition's end clamps invalid legacy offsets once.
	call_deferred("_restore_pending_scroll")
	_active_context.enabled = true
	if is_instance_valid(_outgoing_surface):
		_outgoing_surface.process_mode = Node.PROCESS_MODE_DISABLED
		if old_policy != policy:
			_outgoing_surface.hide()
		await motion_player.transition_between(_outgoing_surface, _incoming_surface, forward)
	else:
		await motion_player.enter_control(_incoming_surface, Vector2(4 if forward else -4, 0), 0.13)
	if revision != _navigation_revision:
		return
	_dispose_surface(_outgoing_surface)
	_outgoing_surface = null
	_incoming_surface = null
	_restore_pending_scroll()
	_pending_scroll_y = -1
	_navigation_locked = false
	_set_chrome_interaction(true)


func _get_host_for_policy(policy: WebsitePage.OverflowPolicy) -> Control:
	if policy == WebsitePage.OverflowPolicy.PAGE_SCROLL:
		return scroll_site_container
	return site_container


func _set_active_host(policy: WebsitePage.OverflowPolicy) -> void:
	var uses_scroll := policy == WebsitePage.OverflowPolicy.PAGE_SCROLL
	page_scroll.visible = uses_scroll
	site_container.visible = not uses_scroll
	if uses_scroll:
		scroll_site_container.active_page = _active_surface
		page_scroll.scroll_vertical = 0
		page_scroll.move_to_front()
	else:
		site_container.move_to_front()


func _build_error_page(code: String, title: String, message: String, requested_url: String) -> Node:
	if error_page_scene != null:
		var instance := error_page_scene.instantiate()
		if instance != null and instance.has_method("setup"):
			instance.call("setup", code, title, message, requested_url)
		return instance
	return _build_fallback_error(code, title, "%s\n\n%s" % [message, requested_url])


func _build_fallback_error(code: String, title: String, detail: String) -> Label:
	var fallback := Label.new()
	fallback.text = "%s: %s\n\n%s" % [code, title, detail]
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback.autowrap_mode = TextServer.AUTOWRAP_WORD
	return fallback


func _on_browser_back_pressed() -> void:
	var current_site := _get_current_site()
	if current_site != null and current_site.has_method("handle_browser_back"):
		if bool(current_site.call("handle_browser_back")):
			_save_current_site_state()
			_refresh_favorite_button()
			return
	_save_current_site_state()
	var tab := _get_current_tab()
	if tab != null and tab.can_go_back():
		_load_page(tab.go_back(), true, false)


func _on_favorite_pressed() -> void:
	var tab := _get_current_tab()
	if tab == null or tab.current_url.is_empty() or _is_home_url(tab.current_url):
		return
	GameState.toggle_browser_site_pin(tab.current_url, tab.page_title, tab.favicon)
	_refresh_favorite_button()


func _refresh_favorite_button() -> void:
	if not is_instance_valid(favorite_button):
		return
	var tab := _get_current_tab()
	if tab == null or tab.current_url.is_empty() or _is_home_url(tab.current_url):
		_apply_favorite_button_visual(false, favorite_blocked_text, favorite_blocked_icon, favorite_blocked_tooltip)
	elif GameState.is_browser_site_pinned(tab.current_url):
		_apply_favorite_button_visual(true, favorite_remove_text, favorite_remove_icon, favorite_remove_tooltip)
	else:
		_apply_favorite_button_visual(true, favorite_add_text, favorite_add_icon, favorite_add_tooltip)


func _apply_favorite_button_visual(enabled: bool, button_text: String, button_icon: Texture2D, tooltip: String) -> void:
	favorite_button.disabled = not enabled
	favorite_button.text = button_text
	favorite_button.icon = button_icon
	favorite_button.tooltip_text = tooltip


func _set_chrome_interaction(enabled: bool) -> void:
	go_button.disabled = not enabled
	url_line_edit.editable = enabled
	browser_back_btn.disabled = not enabled or not _get_current_tab().can_go_back()
	browser_forward_btn.disabled = not enabled or not _get_current_tab().can_go_forward()
	for tab_button in _tab_buttons:
		if is_instance_valid(tab_button):
			tab_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_new_tab_button):
		_new_tab_button.disabled = not enabled


func _get_current_site() -> Node:
	return _active_site if is_instance_valid(_active_site) and not _active_site.is_queued_for_deletion() else null


func _save_current_site_state() -> void:
	if _active_entry == null or not is_instance_valid(_active_site):
		return
	if is_instance_valid(_active_context):
		_active_entry.page_state = _active_context.capture_state()
	if _active_policy == WebsitePage.OverflowPolicy.PAGE_SCROLL:
		_active_entry.scroll_y = page_scroll.scroll_vertical


func _dispose_surface(surface: BrowserPageSurface) -> void:
	if not is_instance_valid(surface):
		return
	motion_player.cancel_control(surface, false, false)
	if surface.get_parent() != null:
		surface.get_parent().remove_child(surface)
	surface.queue_free()


func _cancel_navigation_transition() -> void:
	_navigation_revision += 1
	_dispose_surface(_outgoing_surface)
	_outgoing_surface = null
	if is_instance_valid(_active_surface):
		motion_player.cancel_control(_active_surface, false, false)
		_active_surface.position = Vector2.ZERO
		_active_surface.scale = Vector2.ONE
		_active_surface.modulate = Color.WHITE
	_incoming_surface = null
	_navigation_locked = false


func _clear_site_containers() -> void:
	_cancel_navigation_transition()
	if is_instance_valid(_active_context):
		_active_context.enabled = false
	_dispose_surface(_active_surface)
	_active_surface = null
	_active_site = null
	_active_context = null
	_active_entry = null
	_set_chrome_interaction(true)


func _on_browser_forward_pressed() -> void:
	_save_current_site_state()
	var tab := _get_current_tab()
	if tab != null and tab.can_go_forward():
		_load_page(tab.go_forward(), true, true)


func _restore_pending_scroll() -> void:
	if _pending_scroll_y < 0 or _active_policy != WebsitePage.OverflowPolicy.PAGE_SCROLL:
		return
	page_scroll.scroll_vertical = _pending_scroll_y


func _is_home_url(url: String) -> bool:
	return SimulatedDNS.normalize_url(url) == SimulatedDNS.normalize_url(home_url)


func is_tab_overflow_active() -> bool:
	return _tab_overflow_active


func get_tab_button_count() -> int:
	return _tab_buttons.size()


func get_required_tab_content_width() -> float:
	if _tab_buttons.is_empty():
		return 0.0
	var required_width := 0.0
	for tab_button: BrowserTabButton in _tab_buttons:
		if is_instance_valid(tab_button):
			required_width += tab_button.get_combined_minimum_size().x
	var separation := float(tab_button_container.get_theme_constant("separation"))
	required_width += separation * float(maxi(0, _tab_buttons.size() - 1))
	return required_width


func get_browser_chrome_height() -> float:
	return tab_bar_margin.size.y + address_bar_margin.size.y + 1.0


func get_site_viewport_ratio() -> float:
	if size.y <= 0.0:
		return 0.0
	return content_area.size.y / size.y


func get_app_session_state() -> Dictionary:
	_save_current_site_state()
	var serialized_tabs: Array[Dictionary] = []
	for tab in tabs:
		if tab != null:
			serialized_tabs.append(tab.to_session_state())
	return {"version": SESSION_STATE_VERSION, "current_tab_index": current_tab_index, "tabs": serialized_tabs}


func restore_app_session_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	var saved_version := int(state.get("version", 0))
	if saved_version > SESSION_STATE_VERSION:
		push_warning("BrowserApp: session version %d is newer than supported version %d." % [saved_version, SESSION_STATE_VERSION])
		return
	var raw_tabs: Variant = state.get("tabs", [])
	if not raw_tabs is Array:
		push_warning("BrowserApp: stored tabs value is not an Array.")
		return
	var restored_tabs: Array[BrowserTabData] = []
	for raw_tab_state in raw_tabs:
		if raw_tab_state is Dictionary:
			var restored := BrowserTabData.from_session_state(raw_tab_state as Dictionary)
			if restored != null:
				restored_tabs.append(restored)
	if restored_tabs.is_empty():
		return
	_clear_site_containers()
	tabs = restored_tabs
	current_tab_index = clampi(int(state.get("current_tab_index", 0)), 0, tabs.size() - 1)
	_clear_site_containers()
	_sync_tab_buttons()
	_render_current_tab()
