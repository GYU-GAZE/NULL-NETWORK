extends Control
class_name NavigatorLocalAreaView


signal back_requested


@export_category("Pixel-Perfect Viewport")
@export var render_size: Vector2i = Vector2i(640, 360)

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
var _render_size_update_queued: bool = false


func _ready() -> void:
	if not back_button.pressed.is_connected(
		_on_back_button_pressed
	):
		back_button.pressed.connect(
			_on_back_button_pressed
		)

	error_label.hide()

	if not viewport_container.resized.is_connected(
		_queue_render_size_update
	):
		viewport_container.resized.connect(
			_queue_render_size_update
		)

	_queue_render_size_update()


func open_area(
	data: LocalAreaData,
	entry_id: String = "",
	restored_player_position: Vector2 = Vector2.ZERO,
	has_restored_player_position: bool = false
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

	local_area_instance.set_area_active(false)
	area_root.add_child(local_area_instance)

	var setup_succeeded: bool = (
		local_area_instance.setup_local_area(
			data,
			entry_id,
			restored_player_position,
			has_restored_player_position
		)
	)

	if not setup_succeeded:
		area_root.remove_child(local_area_instance)
		local_area_instance.free()
		return false

	_clear_current_area(local_area_instance)
	error_label.hide()

	_current_area_data = data
	_current_area_instance = local_area_instance

	background.color = data.background_color
	area_name_label.text = data.area_name
	area_subtitle_label.text = data.area_subtitle
	area_subtitle_label.visible = (
		not data.area_subtitle.strip_edges().is_empty()
	)

	_queue_render_size_update()

	return true


func activate() -> void:
	show()


func deactivate() -> void:
	set_interaction_enabled(false)
	hide()


func set_interaction_enabled(enabled: bool) -> void:
	if not is_instance_valid(_current_area_instance):
		return

	_current_area_instance.set_area_active(enabled)


func close_area() -> void:
	deactivate()
	_clear_current_area()

	_current_area_data = null

	area_name_label.text = ""
	area_subtitle_label.text = ""
	error_label.hide()


func is_area_loaded(data: LocalAreaData) -> bool:
	if data == null or _current_area_data == null:
		return false

	if not is_instance_valid(_current_area_instance):
		return false

	return (
		_current_area_data.get_display_id()
		== data.get_display_id()
	)


func get_current_area_data() -> LocalAreaData:
	return _current_area_data


func get_current_area_instance() -> NavigatorLocalAreaScene:
	return _current_area_instance


func get_current_player_position() -> Vector2:
	if not is_instance_valid(_current_area_instance):
		return Vector2.ZERO

	return _current_area_instance.get_player_position()


func get_current_entry_id() -> String:
	if not is_instance_valid(_current_area_instance):
		return ""

	return _current_area_instance.active_entry_id


func _clear_current_area(
	exception: NavigatorLocalAreaScene = null
) -> void:
	for child in area_root.get_children():
		if child == exception:
			continue

		if child is NavigatorLocalAreaScene:
			(child as NavigatorLocalAreaScene).set_area_active(
				false
			)

		area_root.remove_child(child)
		child.queue_free()

	if exception == null:
		_current_area_instance = null


func _apply_render_size() -> void:
	_render_size_update_queued = false

	if (
		not is_instance_valid(area_viewport)
		or not is_instance_valid(viewport_container)
	):
		return

	var available_size := Vector2i(
		floori(viewport_container.size.x),
		floori(viewport_container.size.y)
	)

	if available_size.x <= 0 or available_size.y <= 0:
		available_size = Vector2i(
			maxi(1, render_size.x),
			maxi(1, render_size.y)
		)

	area_viewport.size = available_size


func _queue_render_size_update() -> void:
	if _render_size_update_queued:
		return

	_render_size_update_queued = true
	call_deferred("_apply_render_size")


func _show_error(message: String) -> void:
	push_error(message)

	error_label.text = message
	error_label.show()


func _on_back_button_pressed() -> void:
	back_requested.emit()
