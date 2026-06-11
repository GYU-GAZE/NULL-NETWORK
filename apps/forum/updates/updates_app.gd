extends PanelContainer
class_name UpdatesApp

@export_category("Data")
@export var entry_ui_scene: PackedScene

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var entries_container: VBoxContainer = %EntriesContainer
@onready var refresh_btn: Button = %RefreshBtn


func _ready() -> void:
	_connect_buttons()

	if not ChangelogManager.changelog_changed.is_connected(_refresh_page):
		ChangelogManager.changelog_changed.connect(_refresh_page)

	_refresh_page()
	ChangelogManager.mark_visible_updates_as_read()


func _connect_buttons() -> void:
	if not refresh_btn.pressed.is_connected(_on_refresh_pressed):
		refresh_btn.pressed.connect(_on_refresh_pressed)


func _on_refresh_pressed() -> void:
	ChangelogManager.refresh()
	_refresh_page()


func _refresh_page() -> void:
	_clear_container(entries_container)

	title_label.text = "SYSTEM UPDATES"
	description_label.text = "Recent NULL NETWORK micro-updates and changelog entries."

	var entries: Array[ChangelogEntryData] = ChangelogManager.get_visible_entries()

	if entries.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No updates available."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(empty_label)
		return

	for entry in entries:
		_add_entry(entry)


func _add_entry(entry: ChangelogEntryData) -> void:
	if entry_ui_scene == null:
		push_error("UpdatesApp: entry_ui_scene não configurada.")
		return

	var instance: Node = entry_ui_scene.instantiate()

	if not instance is UpdatesEntryUI:
		push_error("UpdatesApp: entry_ui_scene precisa ter root UpdatesEntryUI.")
		instance.queue_free()
		return

	var row: UpdatesEntryUI = instance as UpdatesEntryUI
	entries_container.add_child(row)
	row.setup(entry)

	entries_container.add_child(HSeparator.new())


func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()
