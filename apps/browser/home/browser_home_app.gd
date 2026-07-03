extends Control
class_name BrowserHomeApp

signal browser_navigation_requested(url: String)

@export_category("Site Cards")
@export var site_card_scene: PackedScene

@export_category("History")
@export var max_recent_sites: int = 12

@onready var pinned_container: VBoxContainer = %PinnedContainer
@onready var recent_container: VBoxContainer = %RecentContainer


func _ready() -> void:
	_rebuild_page()

	if not GameState.browser_history_changed.is_connected(_rebuild_page):
		GameState.browser_history_changed.connect(_rebuild_page)

	if not GameState.game_state_changed.is_connected(_rebuild_page):
		GameState.game_state_changed.connect(_rebuild_page)


func _exit_tree() -> void:
	if GameState.browser_history_changed.is_connected(_rebuild_page):
		GameState.browser_history_changed.disconnect(_rebuild_page)

	if GameState.game_state_changed.is_connected(_rebuild_page):
		GameState.game_state_changed.disconnect(_rebuild_page)


func _rebuild_page() -> void:
	_rebuild_pinned_sites()
	_rebuild_recent_sites()


func _rebuild_pinned_sites() -> void:
	_clear_container(pinned_container)

	var pinned_sites: Array[Dictionary] = GameState.get_pinned_browser_sites()

	if pinned_sites.is_empty():
		_add_empty_label(pinned_container, "No favorite sites yet.")
		return

	for entry in pinned_sites:
		var url: String = str(entry.get("url", ""))
		var title: String = str(entry.get("title", url))
		var favicon: Texture2D = entry.get("favicon", null)

		_add_site_button(
			pinned_container,
			url,
			title,
			favicon
		)


func _rebuild_recent_sites() -> void:
	_clear_container(recent_container)

	var recent_sites: Array[Dictionary] = GameState.get_recent_browser_sites(max_recent_sites)

	if recent_sites.is_empty():
		_add_empty_label(recent_container, "No recent sites yet.")
		return

	for entry in recent_sites:
		var url: String = str(entry.get("url", ""))
		var title: String = str(entry.get("title", url))
		var favicon: Texture2D = entry.get("favicon", null)

		_add_site_button(
			recent_container,
			url,
			title,
			favicon
		)


func _add_site_button(container: VBoxContainer, url: String, title: String, favicon: Texture2D = null) -> void:
	if url.strip_edges().is_empty():
		return

	if site_card_scene != null:
		var card: BrowserHomeCard = site_card_scene.instantiate() as BrowserHomeCard

		if card != null:
			container.add_child(card)
			card.setup(url, title, favicon)
			card.site_selected.connect(_on_site_pressed)
			return

	var button: Button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.text = "%s\n%s" % [
		title if not title.strip_edges().is_empty() else url,
		url
	]
	button.icon = favicon
	button.expand_icon = false

	button.pressed.connect(_on_site_pressed.bind(url))

	container.add_child(button)


func _add_empty_label(container: VBoxContainer, message: String) -> void:
	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)


func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_site_pressed(url: String) -> void:
	browser_navigation_requested.emit(url)
