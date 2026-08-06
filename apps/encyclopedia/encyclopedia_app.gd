extends PanelContainer
class_name EncyclopediaApp


@onready var search_input: LineEdit = %SearchInput
@onready var kind_filter: OptionButton = %KindFilter
@onready var result_count: Label = %ResultCount
@onready var entry_list: VBoxContainer = %EntryList

@onready var entry_texture: TextureRect = %EntryTexture
@onready var entry_name: Label = %EntryName
@onready var entry_subtitle: Label = %EntrySubtitle
@onready var entry_kind: Label = %EntryKind
@onready var subject_label: Label = %SubjectLabel
@onready var summary_label: Label = %SummaryLabel
@onready var milestone_list: HFlowContainer = %MilestoneList
@onready var observation_label: Label = %ObservationLabel
@onready var section_list: VBoxContainer = %SectionList
@onready var module_list: VBoxContainer = %ModuleList
@onready var location_list: VBoxContainer = %LocationList
@onready var evolution_list: VBoxContainer = %EvolutionList
@onready var empty_detail: Label = %EmptyDetail


var _selected_entry_id: String = ""
var _visible_entries: Array[Dictionary] = []
var _entry_buttons: Dictionary = {}
var _refresh_queued: bool = false


func _ready() -> void:
	_configure_filters()
	_connect_signals()
	refresh_entries()


func refresh_entries() -> void:
	_refresh_queued = false
	_visible_entries = EncyclopediaProjectionService.build_entries(
		search_input.text,
		_get_selected_kind_filter()
	)
	_rebuild_entry_list()
	_render_selected_entry()


func get_entry_count() -> int:
	return _visible_entries.size()


func get_selected_entry_id() -> String:
	return _selected_entry_id


func get_rendered_milestone_count() -> int:
	return milestone_list.get_child_count()


func select_entry(entry_id: String) -> bool:
	var clean_id: String = entry_id.strip_edges()

	if clean_id.is_empty() or not _entry_buttons.has(clean_id):
		return false

	_selected_entry_id = clean_id
	_update_button_selection()
	_render_selected_entry()
	return true


func _configure_filters() -> void:
	kind_filter.clear()
	kind_filter.add_item("ALL RECORDS", -1)

	for kind_index: int in range(EncyclopediaEntryData.EntryKind.size()):
		kind_filter.add_item(
			EncyclopediaEntryData.EntryKind.keys()[kind_index],
			kind_index
		)

	kind_filter.select(0)


func _connect_signals() -> void:
	search_input.text_changed.connect(_on_search_changed)
	kind_filter.item_selected.connect(_on_kind_selected)

	if not EncyclopediaService.encyclopedia_changed.is_connected(
		_on_encyclopedia_changed
	):
		EncyclopediaService.encyclopedia_changed.connect(
			_on_encyclopedia_changed
		)

	if not EncyclopediaService.encyclopedia_reloaded.is_connected(
		_on_encyclopedia_reloaded
	):
		EncyclopediaService.encyclopedia_reloaded.connect(
			_on_encyclopedia_reloaded
		)

	if not ContentRegistry.registry_rebuilt.is_connected(
		_on_registry_rebuilt
	):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)


func _get_selected_kind_filter() -> int:
	if kind_filter.selected < 0:
		return -1

	return kind_filter.get_item_id(kind_filter.selected)


func _rebuild_entry_list() -> void:
	_clear_container(entry_list)
	_entry_buttons.clear()
	var selected_visible: bool = false

	for snapshot: Dictionary in _visible_entries:
		var entry_id: String = str(snapshot.get("entry_id", ""))
		var button := Button.new()
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 42.0
		button.text = "%s\n%s" % [
			str(snapshot.get("display_name", entry_id)),
			str(snapshot.get("kind_label", "UNKNOWN"))
		]
		button.tooltip_text = str(snapshot.get("subtitle", ""))
		button.set_meta(&"entry_id", entry_id)
		button.pressed.connect(_on_entry_pressed.bind(entry_id))
		entry_list.add_child(button)
		_entry_buttons[entry_id] = button

		if entry_id == _selected_entry_id:
			selected_visible = true

	result_count.text = "%d CONFIRMED" % _visible_entries.size()

	if not selected_visible:
		_selected_entry_id = (
			str(_visible_entries[0].get("entry_id", ""))
			if not _visible_entries.is_empty()
			else ""
		)

	_update_button_selection()


func _update_button_selection() -> void:
	for raw_id: Variant in _entry_buttons:
		var button := _entry_buttons[raw_id] as Button

		if button != null:
			button.button_pressed = str(raw_id) == _selected_entry_id


func _render_selected_entry() -> void:
	_clear_container(milestone_list)
	_clear_container(section_list)
	_clear_container(module_list)
	_clear_container(location_list)
	_clear_container(evolution_list)

	var snapshot: Dictionary = EncyclopediaProjectionService.build_entry_snapshot(
		_selected_entry_id
	)
	var has_entry: bool = not snapshot.is_empty()
	empty_detail.visible = not has_entry
	entry_texture.visible = has_entry
	entry_name.visible = has_entry
	entry_subtitle.visible = has_entry
	entry_kind.visible = has_entry
	subject_label.visible = has_entry
	summary_label.visible = has_entry
	observation_label.visible = has_entry

	if not has_entry:
		entry_texture.texture = null
		entry_name.text = "NO CONFIRMED RECORD"
		return

	entry_texture.texture = snapshot.get("texture") as Texture2D
	entry_name.text = str(snapshot.get("display_name", "UNKNOWN"))
	entry_subtitle.text = str(snapshot.get("subtitle", ""))
	entry_kind.text = str(snapshot.get("kind_label", "UNKNOWN"))
	summary_label.text = str(snapshot.get("summary", ""))
	var subject: Dictionary = snapshot.get("subject", {}) as Dictionary
	subject_label.text = (
		"APK  %s  ·  FORM  %s" % [
			str(subject.get("apk_id", "—")),
			str(subject.get("form_name", "—"))
		]
		if not subject.is_empty()
		else "SUBJECT ID  %s" % _selected_entry_id
	)

	for milestone_value: Variant in snapshot.get("milestones", []):
		if milestone_value is not Dictionary:
			continue

		var milestone: Dictionary = milestone_value as Dictionary
		var label := Label.new()
		label.text = "%s %s" % [
			"[X]" if bool(milestone.get("unlocked", false)) else "[ ]",
			str(milestone.get("label", ""))
		]
		milestone_list.add_child(label)

	var counts: Dictionary = snapshot.get("counts", {}) as Dictionary
	observation_label.text = (
		"ENCOUNTERS %d  ·  SCANS %d  ·  DEFEATS %d  ·  TAMES %d"
		% [
			int(counts.get("encountered", 0)),
			int(counts.get("scanned", 0)),
			int(counts.get("defeated", 0)),
			int(counts.get("tamed", 0))
		]
	)

	_render_sections(snapshot.get("sections", []) as Array)
	_render_reference_list(
		module_list,
		snapshot.get("known_modules", []) as Array,
		"NO MODULE SIGNATURES CONFIRMED"
	)
	_render_reference_list(
		location_list,
		snapshot.get("known_locations", []) as Array,
		"NO LOCATIONS CONFIRMED"
	)
	_render_reference_list(
		evolution_list,
		snapshot.get("known_evolutions", []) as Array,
		"NO EVOLUTIONS CONFIRMED"
	)


func _render_sections(sections: Array) -> void:
	for section_value: Variant in sections:
		if section_value is not Dictionary:
			continue

		var section: Dictionary = section_value as Dictionary
		var title := Label.new()
		title.text = str(section.get("title", "DATA"))
		var body := Label.new()
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.text = (
			str(section.get("text", ""))
			if bool(section.get("unlocked", false))
			else "DATA NOT CONFIRMED"
		)
		section_list.add_child(title)
		section_list.add_child(body)


func _render_reference_list(
	container: VBoxContainer,
	entries: Array,
	empty_text: String
) -> void:
	if entries.is_empty():
		var empty := Label.new()
		empty.text = empty_text
		container.add_child(empty)
		return

	for entry_value: Variant in entries:
		if entry_value is not Dictionary:
			continue

		var entry: Dictionary = entry_value as Dictionary
		var label := Label.new()
		label.text = "• %s" % str(entry.get("display_name", entry.get("id", "—")))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(label)


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _queue_refresh() -> void:
	if _refresh_queued or is_queued_for_deletion():
		return

	_refresh_queued = true
	call_deferred("refresh_entries")


func _on_search_changed(_new_text: String) -> void:
	refresh_entries()


func _on_kind_selected(_index: int) -> void:
	refresh_entries()


func _on_entry_pressed(entry_id: String) -> void:
	select_entry(entry_id)


func _on_encyclopedia_changed(_entry_id: String) -> void:
	_queue_refresh()


func _on_encyclopedia_reloaded() -> void:
	_queue_refresh()


func _on_registry_rebuilt() -> void:
	_queue_refresh()
