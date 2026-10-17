@tool
extends EditorPlugin

var _dialog: ConfirmationDialog
var _fields: Dictionary = {}
var _template: OptionButton
var _message: Label


func _enter_tree() -> void:
	add_tool_menu_item("Create Website", _open_dialog)
	_dialog = ConfirmationDialog.new()
	_dialog.title = "Create Website"
	_dialog.ok_button_text = "Create and Register"
	_dialog.min_size = Vector2i(560, 420)
	var column := VBoxContainer.new()
	_dialog.add_child(column)
	for key: String in ["name", "url", "title", "folder", "favicon", "catalog"]:
		var label := Label.new()
		label.text = {"name": "Internal name", "url": "Domain / page URL", "title": "Page title", "folder": "Destination folder (res://)", "favicon": "Favicon path (optional)", "catalog": "WebsiteCatalog"}[key]
		column.add_child(label)
		var edit := LineEdit.new()
		_fields[key] = edit
		column.add_child(edit)
	_fields.folder.text = "res://apps/browser/sites/new_site"
	_fields.catalog.text = WebsiteAuthoring.DEFAULT_CATALOG
	_template = OptionButton.new()
	for label: String in ["Document — Browser scroll", "Application — own scroll", "Viewport — intentional clipping"]:
		_template.add_item(label)
	column.add_child(_template)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_message)
	_dialog.dialog_hide_on_ok = false
	_dialog.confirmed.connect(_create)
	get_editor_interface().get_base_control().add_child(_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item("Create Website")
	if is_instance_valid(_dialog):
		_dialog.queue_free()


func _open_dialog() -> void:
	_message.text = ""
	_dialog.popup_centered()


func _create() -> void:
	var options := {}
	for key: String in _fields:
		options[key] = _fields[key].text
	options.template = ["document", "application", "viewport"][_template.selected]
	var result := WebsiteAuthoring.create_page(options)
	if not result.ok:
		_message.text = "\n".join(result.errors)
		return
	_dialog.hide()
	get_editor_interface().get_resource_filesystem().scan()
	get_editor_interface().open_scene_from_path(result.scene)
	print("Website created and registered: ", result.page)
