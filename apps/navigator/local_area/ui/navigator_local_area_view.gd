extends Control
class_name NavigatorLocalAreaView


signal back_requested


@onready var background: ColorRect = %Background
@onready var viewport_container: SubViewportContainer = (
	%ViewportContainer
)
@onready var area_viewport: SubViewport = %AreaViewport
@onready var area_root: Node2D = %AreaRoot

@onready var area_name_label: Label = %AreaNameLabel
@onready var area_subtitle_label: Label = (
	%AreaSubtitleLabel
)
@onready var error_label: Label = %ErrorLabel
@onready var back_button: Button = %BackButton


var _current_area_data: LocalAreaData
var _current_area_instance: NavigatorLocalAreaScene


func _ready() -> void:
	if not back_button.pressed.is_connected(
		_on_back_button_pressed
	):
		back_button.pressed.connect(
			_on_back_button_pressed
		)

	if not viewport_container.resized.is_connected(
		_sync_subviewport_size
	):
		viewport_container.resized.connect(
			_sync_subviewport_size
		)

	error_label.hide()

	call_deferred("_sync_subviewport_size")


func open_area(
	data: LocalAreaData,
	entry_id: String = ""
) -> bool:
	if data == null:
		_show_error(
			"NavigatorLocalAreaView: LocalAreaData is null."
		)
		return false

	if data.area_scene == null:
		_show_error(
			"NavigatorLocalAreaView: '%s' has no area scene."
			% data.area_name
		)
		return false

	_clear_current_area()
	error_label.hide()

	_current_area_data = data

	background.color = data.background_color
	area_name_label.text = data.area_name
	area_subtitle_label.text = data.area_subtitle
	area_subtitle_label.visible = (
		not data.area_subtitle.strip_edges().is_empty()
	)

	var raw_instance: Node = (
		data.area_scene.instantiate()
	)

	var local_area_instance := (
		raw_instance as NavigatorLocalAreaScene
	)

	if local_area_instance == null:
		raw_instance.free()

		_show_error(
			"NavigatorLocalAreaView: '%s' must inherit "
			+ "NavigatorLocalAreaScene."
			% data.area_name
		)

		return false

	local_area_instance.setup_local_area(
		data,
		entry_id
	)

	area_root.add_child(local_area_instance)

	_current_area_instance = local_area_instance

	_sync_subviewport_size()

	return true


func close_area() -> void:
	_clear_current_area()

	_current_area_data = null

	area_name_label.text = ""
	area_subtitle_label.text = ""
	error_label.hide()


func get_current_area_data() -> LocalAreaData:
	return _current_area_data


func get_current_area_instance() -> NavigatorLocalAreaScene:
	return _current_area_instance


func _clear_current_area() -> void:
	for child in area_root.get_children():
		area_root.remove_child(child)
		child.queue_free()

	_current_area_instance = null


func _sync_subviewport_size() -> void:
	if not is_instance_valid(viewport_container):
		return

	if not is_instance_valid(area_viewport):
		return

	var resolved_width: int = maxi(
		1,
		int(round(viewport_container.size.x))
	)

	var resolved_height: int = maxi(
		1,
		int(round(viewport_container.size.y))
	)

	area_viewport.size = Vector2i(
		resolved_width,
		resolved_height
	)


func _show_error(message: String) -> void:
	push_error(message)

	error_label.text = message
	error_label.show()


func _on_back_button_pressed() -> void:
	back_requested.emit()
