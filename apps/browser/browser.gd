extends Control
class_name BrowserApp


@export var tab_button_scene: PackedScene
@export var new_tab_button_scene: PackedScene
@onready var tab_button_container: HBoxContainer = %TabButtonContainer
@onready var new_tab_button_holder: MarginContainer = %NewTabButtonHolder
@onready var tab_scroll: ScrollContainer = %TabScroll

@onready var url_line_edit: LineEdit = %UrlLineEdit
@onready var go_button: Button = %GoButton
@onready var browser_back_btn: Button = %BrowserBackBtn

@onready var normal_site_scroll: ScrollContainer = %NormalSiteScroll
@onready var normal_site_content: VBoxContainer = %NormalSiteContent
@onready var custom_site_container: MarginContainer = %CustomSiteContainer

var tabs: Array[BrowserTabData] = []
var current_tab_index: int = -1
var last_known_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	go_button.pressed.connect(_on_go_pressed)
	url_line_edit.text_submitted.connect(_load_page)
	browser_back_btn.pressed.connect(_on_browser_back_pressed)

	_create_tab("null.net")


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


func _switch_tab(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= tabs.size():
		return

	if tab_index == current_tab_index:
		return

	_save_current_custom_site_state()

	current_tab_index = tab_index

	_render_current_tab()
	_refresh_tab_buttons()


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
			i == current_tab_index,
			tabs.size() > 1,
			tab_width
		)

		tab_button.tab_selected.connect(_switch_tab)
		tab_button.tab_close_requested.connect(_close_tab)

	var new_tab_button := new_tab_button_scene.instantiate() as Button
	new_tab_button.custom_minimum_size.x = 36.0
	new_tab_button.pressed.connect(func(): _create_tab("null.net"))
	new_tab_button_holder.add_child(new_tab_button)


func _load_page(target_url: String, is_history_nav: bool = false) -> void:
	if target_url.is_empty():
		return

	var tab := _get_current_tab()

	if not is_history_nav:
		_save_current_custom_site_state()
		tab.clear_custom_site_state()

	var page: WebsitePage = SimulatedDNS.fetch_page(target_url)

	if page != null:
		tab.set_page_title(page.page_title)
	else:
		tab.set_page_title(target_url)

	if not is_history_nav:
		tab.navigate_to(target_url, tab.page_title)
	else:
		tab.current_url = target_url

	url_line_edit.text = target_url

	_render_url(target_url)
	_refresh_tab_buttons()


func _render_current_tab() -> void:
	var tab := _get_current_tab()

	url_line_edit.text = tab.current_url

	if tab.current_url.is_empty():
		_clear_containers()
		return

	_render_url(tab.current_url)


func _render_url(target_url: String) -> void:
	_clear_containers()

	var page: WebsitePage = SimulatedDNS.fetch_page(target_url)

	if page == null:
		_render_403_error()
		return

	var tab := _get_current_tab()
	tab.set_page_title(page.page_title)

	if page.custom_site_scene != null:
		_render_custom_site(page.custom_site_scene, tab.custom_site_state)
	else:
		tab.clear_custom_site_state()
		_render_normal_site(page)

	_refresh_tab_buttons()


func _on_browser_back_pressed() -> void:
	if custom_site_container.get_child_count() > 0:
		var current_app = custom_site_container.get_child(0)

		if current_app.has_method("handle_browser_back"):
			var handled_by_app: bool = current_app.handle_browser_back()

			if handled_by_app:
				_save_current_custom_site_state()
				return

	var tab := _get_current_tab()

	if tab.can_go_back():
		var previous_url := tab.go_back()
		_load_page(previous_url, true)
	else:
		print("Histórico vazio, não há para onde voltar.")


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
	custom_site_container.hide()
	normal_site_scroll.show()

	var error_label := Label.new()
	error_label.text = "ERRO 403: CONNECTION REFUSED\n\nO servidor recusou a conexão ou o domínio não existe."
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	normal_site_content.add_child(error_label)


func _render_custom_site(scene: PackedScene, state: Dictionary = {}) -> void:
	normal_site_scroll.hide()
	custom_site_container.show()

	var instance = scene.instantiate()
	custom_site_container.add_child(instance)

	if instance.has_signal("browser_navigation_requested"):
		instance.browser_navigation_requested.connect(_load_page)

	if instance.has_method("restore_browser_state"):
		instance.call_deferred("restore_browser_state", state)


func _render_normal_site(page: WebsitePage) -> void:
	custom_site_container.hide()
	normal_site_scroll.show()

	match page.header_type:
		WebsitePage.HeaderType.TEXT:
			var header_label := Label.new()
			header_label.text = page.header_text
			header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			normal_site_content.add_child(header_label)

		WebsitePage.HeaderType.IMAGE:
			if page.header_image:
				var header_rect := TextureRect.new()
				header_rect.texture = page.header_image
				header_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				header_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				header_rect.custom_minimum_size.y = 150
				normal_site_content.add_child(header_rect)

	if not page.navbar_links.is_empty():
		var nav_box := HBoxContainer.new()
		nav_box.alignment = BoxContainer.ALIGNMENT_CENTER

		for link_name in page.navbar_links:
			var dest_url: String = page.navbar_links[link_name]

			var btn := Button.new()
			btn.text = link_name
			nav_box.add_child(btn)
			btn.pressed.connect(func(): _load_page(dest_url))

		normal_site_content.add_child(nav_box)

	normal_site_content.add_child(HSeparator.new())

	for block in page.content_blocks:
		_build_block(block, normal_site_content)


func _build_block(block: PageBlock, parent_node: Control) -> void:
	if block == null:
		return

	var new_node: Control = null

	match block.type:
		PageBlock.BlockType.ROW:
			new_node = HBoxContainer.new()
			new_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		PageBlock.BlockType.COLUMN:
			new_node = VBoxContainer.new()
			new_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		PageBlock.BlockType.TEXT:
			var text_label := RichTextLabel.new()
			text_label.bbcode_enabled = true
			text_label.meta_clicked.connect(_on_bbcode_link_clicked)
			text_label.text = block.text_content
			text_label.fit_content = true
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_label.custom_minimum_size.x = 10
			new_node = text_label

		PageBlock.BlockType.IMAGE:
			var img_rect := TextureRect.new()
			img_rect.texture = block.image_content
			img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			img_rect.custom_minimum_size.y = 200
			new_node = img_rect

		PageBlock.BlockType.BUTTON:
			var btn := Button.new()
			btn.text = block.text_content
			btn.pressed.connect(func(): _handle_block_button(block))
			new_node = btn

		PageBlock.BlockType.SPACING:
			var spacer := Control.new()
			spacer.custom_minimum_size.y = block.spacing_size
			new_node = spacer

	if new_node != null:
		parent_node.add_child(new_node)

		if block.type == PageBlock.BlockType.ROW or block.type == PageBlock.BlockType.COLUMN:
			for child_block in block.child_blocks:
				_build_block(child_block, new_node)


func _handle_block_button(block: PageBlock) -> void:
	match block.button_action:
		PageBlock.ButtonAction.NONE:
			return

		PageBlock.ButtonAction.NAVIGATE:
			if not block.target_url.is_empty():
				_load_page(block.target_url)

		PageBlock.ButtonAction.APPLY_EFFECTS:
			_apply_block_effects(block)


func _apply_block_effects(block: PageBlock) -> void:
	for effect in block.effects:
		if effect == null:
			continue

		effect.apply()


func _on_bbcode_link_clicked(meta: Variant) -> void:
	var target_url := str(meta)

	if target_url.is_empty():
		return

	_load_page(target_url)

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

	var total_tabs_width: float = tab_width * float(tabs.size())
	var max_scroll_width: float = max(200.0, size.x - new_tab_button_width - tab_bar_margin)

	tab_scroll.custom_minimum_size.x = min(total_tabs_width, max_scroll_width)
	tab_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
