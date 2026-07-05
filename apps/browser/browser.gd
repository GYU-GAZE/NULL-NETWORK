extends Control
class_name BrowserApp

@export var tab_button_scene: PackedScene
@export var new_tab_button_scene: PackedScene

@export_category("Browser Routes")
@export var home_url: String = "home"

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

@onready var normal_site_scroll: ScrollContainer = %NormalSiteScroll
@onready var normal_site_content: VBoxContainer = %NormalSiteContent
@onready var custom_site_scroll: ScrollContainer = %CustomSiteScroll
@onready var custom_site_container: MarginContainer = %CustomSiteContainer

var tabs: Array[BrowserTabData] = []
var current_tab_index: int = -1
var last_known_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	go_button.pressed.connect(_on_go_pressed)
	url_line_edit.text_submitted.connect(_load_page)
	browser_back_btn.pressed.connect(_on_browser_back_pressed)
	favorite_button.pressed.connect(_on_favorite_pressed)

	_connect_browser_navigation_signals(self)

	_create_tab(home_url)


func _on_go_pressed() -> void:
	_load_page(url_line_edit.text)


func _create_tab(start_url: String = "") -> void:
	_save_current_custom_site_state()

	var tab := BrowserTabData.new()
	tabs.append(tab)
	current_tab_index = tabs.size() - 1

	if start_url.is_empty():
		_clear_containers()
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
		_save_current_custom_site_state()

	tabs.remove_at(tab_index)

	if current_tab_index >= tabs.size():
		current_tab_index = tabs.size() - 1

	_render_current_tab()
	_refresh_tab_buttons()
	_refresh_favorite_button()


func _switch_tab(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= tabs.size():
		return

	if tab_index == current_tab_index:
		return

	_save_current_custom_site_state()

	current_tab_index = tab_index

	_render_current_tab()
	_refresh_tab_buttons()
	_refresh_favorite_button()


func _get_current_tab() -> BrowserTabData:
	if current_tab_index < 0 or current_tab_index >= tabs.size():
		_create_tab()

	return tabs[current_tab_index]


func _refresh_tab_buttons() -> void:
	for child in tab_button_container.get_children():
		child.queue_free()

	for child in new_tab_button_holder.get_children():
		child.queue_free()

	var tab_width: float = 160.0
	_refresh_tab_layout_only()

	for i in range(tabs.size()):
		var tab := tabs[i]

		var tab_button: BrowserTabButton = tab_button_scene.instantiate() as BrowserTabButton
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

	var new_tab_button := new_tab_button_scene.instantiate() as Button
	new_tab_button.custom_minimum_size.x = 36.0
	new_tab_button.pressed.connect(func(): _create_tab(home_url))
	new_tab_button_holder.add_child(new_tab_button)


func _load_page(target_url: String, is_history_nav: bool = false) -> void:
	if target_url.is_empty():
		return

	var clean_url: String = target_url.strip_edges()
	var tab := _get_current_tab()

	if not is_history_nav:
		_save_current_custom_site_state()
		tab.clear_custom_site_state()

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
		_clear_containers()
		_refresh_favorite_button()
		return

	_render_url(tab.current_url)
	_refresh_favorite_button()


func _render_url(target_url: String) -> void:
	_clear_containers()

	var page: WebsitePage = SimulatedDNS.fetch_page(target_url)

	if page == null:
		_render_403_error()
		return

	var tab := _get_current_tab()
	tab.set_page_title(page.page_title)
	tab.set_favicon(page.favicon)

	if page.custom_site_scene == null:
		tab.clear_custom_site_state()
		_render_missing_scene_error(page)
		_refresh_tab_buttons()
		_refresh_favorite_button()
		return

	_render_custom_site(page.custom_site_scene, tab.custom_site_state)
	_refresh_tab_buttons()
	_refresh_favorite_button()


func _on_browser_back_pressed() -> void:
	if custom_site_container.get_child_count() > 0:
		var current_app = custom_site_container.get_child(0)

		if current_app.has_method("handle_browser_back"):
			var handled_by_app: bool = current_app.handle_browser_back()

			if handled_by_app:
				_save_current_custom_site_state()
				_refresh_favorite_button()
				return

	var tab := _get_current_tab()

	if tab.can_go_back():
		var previous_url := tab.go_back()
		_load_page(previous_url, true)
	else:
		print("Histórico vazio, não há para onde voltar.")


func _on_favorite_pressed() -> void:
	var tab := _get_current_tab()

	if tab.current_url.is_empty():
		return

	if tab.current_url == home_url:
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

	if tab.current_url.is_empty() or tab.current_url == home_url:
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


func _apply_favorite_button_visual(enabled: bool, button_text: String, button_icon: Texture2D, tooltip: String) -> void:
	favorite_button.disabled = not enabled
	favorite_button.text = button_text
	favorite_button.icon = button_icon
	favorite_button.tooltip_text = tooltip


func _save_current_custom_site_state() -> void:
	if current_tab_index < 0 or current_tab_index >= tabs.size():
		return

	var tab := tabs[current_tab_index]

	if custom_site_container.get_child_count() <= 0:
		tab.clear_custom_site_state()
		return

	var current_app = custom_site_container.get_child(0)

	if current_app.has_method("get_browser_state"):
		tab.custom_site_state = current_app.get_browser_state()
	else:
		tab.clear_custom_site_state()


func _clear_containers() -> void:
	for child in normal_site_content.get_children():
		child.queue_free()

	for child in custom_site_container.get_children():
		child.queue_free()


func _render_403_error() -> void:
	custom_site_scroll.hide()
	normal_site_scroll.show()

	var error_label := Label.new()
	error_label.text = "ERRO 403: CONNECTION REFUSED\n\nO servidor recusou a conexão ou o domínio não existe."
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	normal_site_content.add_child(error_label)


func _render_missing_scene_error(page: WebsitePage) -> void:
	custom_site_scroll.hide()
	normal_site_scroll.show()

	var error_label := Label.new()
	error_label.text = "ERRO 500: PAGE SCENE MISSING\n\nA rota '%s' existe, mas não possui custom_site_scene configurada." % page.url
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	normal_site_content.add_child(error_label)


func _render_custom_site(scene: PackedScene, state: Dictionary = {}) -> void:
	normal_site_scroll.hide()
	custom_site_scroll.show()

	var instance: Node = scene.instantiate()
	custom_site_container.add_child(instance)

	if instance is Control:
		var control := instance as Control
		control.custom_minimum_size = Vector2.ZERO
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_connect_browser_navigation_signals(instance)

	var tab := _get_current_tab()

	if instance.has_method("set_browser_url"):
		instance.call_deferred("set_browser_url", tab.current_url)

	if instance.has_method("restore_browser_state"):
		instance.call_deferred("restore_browser_state", state)


func _process(_delta: float) -> void:
	if size == last_known_size:
		return

	last_known_size = size
	_refresh_tab_layout_only()


func _refresh_tab_layout_only() -> void:
	if not is_instance_valid(tab_scroll):
		return

	var tab_width: float = 160.0
	var new_tab_button_width: float = 36.0
	var tab_bar_margin: float = 24.0

	var tab_count: int = tabs.size()
	var tab_spacing: float = 0.0

	if is_instance_valid(tab_button_container):
		tab_spacing = float(tab_button_container.get_theme_constant("separation")) * float(max(0, tab_count - 1))

	var total_tabs_width: float = (tab_width * float(tab_count)) + tab_spacing
	var max_scroll_width: float = max(200.0, size.x - new_tab_button_width - tab_bar_margin)

	tab_scroll.custom_minimum_size.x = min(total_tabs_width, max_scroll_width)
	tab_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func _connect_browser_navigation_signals(root: Node) -> void:
	if root.has_signal("browser_navigation_requested"):
		if not root.is_connected("browser_navigation_requested", Callable(self, "_load_page")):
			root.connect("browser_navigation_requested", Callable(self, "_load_page"))

	for child in root.get_children():
		_connect_browser_navigation_signals(child)
