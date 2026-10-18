@tool
extends EditorPlugin

var _dialog: ConfirmationDialog
var _fields: Dictionary = {}
var _category: OptionButton
var _visible: CheckBox
var _unlocked: CheckBox
var _message: Label


func _enter_tree() -> void:
	add_tool_menu_item("Create Navigator Location", _open_dialog)
	_dialog = ConfirmationDialog.new()
	_dialog.title = "Create Navigator Location"
	_dialog.ok_button_text = "Create and Register"
	_dialog.min_size = Vector2i(620, 640)
	var body := VBoxContainer.new()
	_dialog.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 500)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var labels := {"id": "Stable ID", "name": "Location name", "description": "Description", "position": "Map position (normalized X,Y)", "folder": "Destination folder (res://)", "scene": "Existing scene (optional; blank creates a template)", "activity": "Travel ActivityDefinitionData", "spawn_table": "SpawnTable (optional)", "unlock_conditions": "Unlock ConditionRuleData (optional)", "availability_conditions": "Availability ConditionRuleData (optional)", "icon": "Marker texture (optional)", "catalog": "GameContentCatalog", "world": "NavigatorWorldData"}
	for key: String in labels:
		var label := Label.new()
		label.text = labels[key]
		column.add_child(label)
		var field := LineEdit.new()
		_fields[key] = field
		column.add_child(field)
	_fields.folder.text = "res://data/content/navigator/areas/new_area"
	_fields.position.text = "0.5,0.5"
	_fields.catalog.text = LocationAuthoring.DEFAULT_CATALOG
	_fields.world.text = LocationAuthoring.DEFAULT_WORLD
	_category = OptionButton.new()
	for key: String in MapLocation.LocationCategory:
		_category.add_item(key)
	column.add_child(_category)
	_visible = CheckBox.new()
	_visible.text = "Initially discovered"
	_visible.button_pressed = true
	column.add_child(_visible)
	_unlocked = CheckBox.new()
	_unlocked.text = "Unlocked by default (explicit Conditions still apply)"
	_unlocked.button_pressed = true
	column.add_child(_unlocked)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(560, 72)
	_message.max_lines_visible = 4
	body.add_child(_message)
	_dialog.dialog_hide_on_ok = false
	_dialog.confirmed.connect(_create)
	get_editor_interface().get_base_control().add_child(_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item("Create Navigator Location")
	if is_instance_valid(_dialog):
		_dialog.queue_free()


func _open_dialog() -> void:
	_message.text = ""
	_dialog.popup_centered()


func _create() -> void:
	var options := {}
	for key: String in _fields:
		options[key] = _fields[key].text
	var coordinates: PackedStringArray = str(options.position).split(",")
	if coordinates.size() != 2 or not coordinates[0].is_valid_float() or not coordinates[1].is_valid_float():
		_message.text = "Map position must contain two numbers, for example 0.5,0.5."
		return
	options.position = Vector2(float(coordinates[0]), float(coordinates[1]))
	options.visible = _visible.button_pressed
	options.unlocked = _unlocked.button_pressed
	options.category = _category.selected
	var result := LocationAuthoring.create_location(options)
	if not result.ok:
		_message.text = "\n".join(result.errors)
		_message.tooltip_text = _message.text
		return
	_dialog.hide()
	get_editor_interface().get_resource_filesystem().scan()
	get_editor_interface().open_scene_from_path(result.scene)
	print("Navigator location created and registered: ", result.location)
