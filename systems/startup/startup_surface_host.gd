extends Control
class_name StartupSurfaceHost

## Keeps the startup account surface compact at normal resolutions while still
## fitting the complete New User -> save mode flow when one mode is expanded.
## On small canvases the host yields height to the actual menu column and
## ModeScroll owns overflow instead of letting the login composition escape.

@export_range(48.0, 320.0, 1.0) var minimum_surface_height: float = 96.0
@export_range(0.0, 24.0, 1.0) var fit_padding: float = 2.0

@onready var mode_margin: MarginContainer = %ModeMargin
@onready var mode_content_root: VBoxContainer = %ModeContentRoot
@onready var mode_header: Control = %ModeHeader
@onready var mode_hint: Label = %ModeHint
@onready var mode_options: VBoxContainer = %ModeOptions
@onready var safe_mode_option: StartupModeOption = %SafeModeOption
@onready var commit_mode_option: StartupModeOption = %CommitModeOption

var _refresh_queued: bool = false


func _ready() -> void:
	var column := get_parent() as Control
	if column != null and not column.resized.is_connected(_queue_height_refresh):
		column.resized.connect(_queue_height_refresh)
	_queue_height_refresh()


func get_required_mode_surface_height() -> float:
	if not (
		is_instance_valid(mode_margin)
		and is_instance_valid(mode_content_root)
		and is_instance_valid(mode_header)
		and is_instance_valid(mode_hint)
		and is_instance_valid(mode_options)
		and is_instance_valid(safe_mode_option)
		and is_instance_valid(commit_mode_option)
	):
		return minimum_surface_height

	var options_separation := float(mode_options.get_theme_constant("separation"))
	var safe_expanded_height := (
		safe_mode_option.expanded_height
		+ commit_mode_option.collapsed_height
		+ options_separation
	)
	var commit_expanded_height := (
		safe_mode_option.collapsed_height
		+ commit_mode_option.expanded_height
		+ options_separation
	)
	var options_height := maxf(safe_expanded_height, commit_expanded_height)

	var content_separation := float(mode_content_root.get_theme_constant("separation"))
	var content_height := (
		mode_header.get_combined_minimum_size().y
		+ mode_hint.get_combined_minimum_size().y
		+ options_height
		+ content_separation * 2.0
	)

	var vertical_margins := float(
		mode_margin.get_theme_constant("margin_top")
		+ mode_margin.get_theme_constant("margin_bottom")
	)

	return ceilf(content_height + vertical_margins + fit_padding)


func _queue_height_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_height")


func _refresh_height() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return

	var required_height := get_required_mode_surface_height()
	var available_height := _get_available_column_height()
	custom_minimum_size.y = minf(
		required_height,
		maxf(minimum_surface_height, available_height)
	)


func _get_available_column_height() -> float:
	var column := get_parent() as VBoxContainer
	if column == null or column.size.y <= 0.0:
		return get_required_mode_surface_height()

	var visible_sibling_height := 0.0
	var visible_item_count := 1 # SurfaceHost itself.
	for child: Node in column.get_children():
		if child == self or child is not Control:
			continue
		var control := child as Control
		if not control.visible:
			continue
		visible_sibling_height += control.get_combined_minimum_size().y
		visible_item_count += 1

	var separation := float(column.get_theme_constant("separation"))
	var separation_height := separation * float(maxi(0, visible_item_count - 1))
	return maxf(
		minimum_surface_height,
		floorf(column.size.y - visible_sibling_height - separation_height)
	)
