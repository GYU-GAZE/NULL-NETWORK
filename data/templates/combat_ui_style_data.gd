extends Resource
class_name CombatUIStyleData


@export_category("Shared Fonts")
@export var interface_font: Font
@export_range(0, 128) var interface_font_size: int = 0
@export var actor_name_font: Font
@export_range(0, 128) var actor_name_font_size: int = 0
@export var bar_font: Font
@export_range(0, 128) var bar_font_size: int = 0
@export var status_count_font: Font
@export_range(0, 128) var status_count_font_size: int = 0
@export var timeline_font: Font
@export_range(0, 128) var timeline_font_size: int = 0
@export var module_font: Font
@export_range(0, 128) var module_font_size: int = 0
@export var floating_text_font: Font
@export_range(1, 128) var floating_text_font_size: int = 28

@export_category("Actor Geometry")
@export var actor_frame_size := Vector2(96, 52)
@export var empty_slot_size := Vector2(96, 80)
@export var portrait_size := Vector2(72, 30)
@export var status_row_size := Vector2(96, 22)
@export var status_badge_size := Vector2(20, 20)
@export var bar_size := Vector2(96, 10)
@export var actor_preview_pulse_color := Color(2, 2, 2, 1)
@export var actor_drag_preview_color := Color(1, 1, 1, 0.7)
@export var actor_ghost_color := Color(0.5, 1.5, 2, 0.8)
@export_range(0.01, 10.0, 0.01) var actor_preview_pulse_duration := 0.3

@export_category("Actor Cards")
@export var player_actor_style: StyleBox
@export var ally_actor_style: StyleBox
@export var enemy_actor_style: StyleBox
@export var disabled_actor_style: StyleBox
@export var empty_slot_style: StyleBox
@export var locked_slot_style: StyleBox

@export_category("Bars")
@export var bar_background_style: StyleBox
@export var hp_fill_style: StyleBox
@export var hp_preview_damage_style: StyleBox
@export var hp_preview_heal_style: StyleBox
@export var stability_fill_style: StyleBox

@export_category("Status Badges")
@export var status_badge_style: StyleBox
@export var status_stack_color := Color.WHITE
@export var status_stack_shadow_color := Color.BLACK
@export_range(0, 16) var status_stack_outline_size: int = 2
@export_range(0, 16) var status_separation: int = 2

@export_category("Timeline")
@export var timeline_cell_size := Vector2(48, 48)
@export var timeline_card_size := Vector2(48, 48)
@export var timeline_icon_size := Vector2(8, 8)
@export var player_timeline_style: StyleBox
@export var ally_timeline_style: StyleBox
@export var enemy_timeline_style: StyleBox
@export var player_fallback_color := Color(0.4, 0.8, 1.0)
@export var ally_fallback_color := Color(0.5, 1.0, 0.5)
@export var enemy_fallback_color := Color(1.0, 0.4, 0.4)
@export_range(0, 32) var timeline_separation: int = 1
@export var timeline_executed_modulate := Color(0.3, 0.3, 0.3, 1)
@export var timeline_feedback_offset := Vector2(5, -5)
@export_range(0.01, 10.0, 0.01) var timeline_feedback_step_duration := 0.05

@export_category("Module Inventory")
@export var module_slot_size := Vector2(120, 40)
@export var module_icon_size := Vector2(28, 28)
@export var module_slot_style: StyleBox
@export_range(0, 32) var module_separation: int = 4

@export_category("Floating Text")
@export var floating_text_shadow_color := Color.BLACK
@export_range(0, 16) var floating_text_outline_size: int = 4
@export var floating_text_origin_offset := Vector2(20, 20)
@export_range(0, 256) var floating_text_stack_spacing: int = 35
@export var floating_text_travel := Vector2(0, -60)
@export_range(0.01, 10.0, 0.01) var floating_text_duration := 0.8
@export_range(0.0, 10.0, 0.01) var floating_text_fade_delay := 0.2


func apply_font(
	control: Control,
	font: Font,
	font_size: int
) -> void:
	if control == null:
		return

	if font != null:
		control.add_theme_font_override("font", font)

	if font_size > 0:
		control.add_theme_font_size_override(
			"font_size",
			font_size
		)


func apply_rich_text_font(
	control: RichTextLabel,
	font: Font,
	font_size: int
) -> void:
	if control == null:
		return

	if font != null:
		for font_key in [
			"normal_font",
			"bold_font",
			"italics_font",
			"bold_italics_font",
			"mono_font"
		]:
			control.add_theme_font_override(
				font_key,
				font
			)

	if font_size > 0:
		for size_key in [
			"normal_font_size",
			"bold_font_size",
			"italics_font_size",
			"bold_italics_font_size",
			"mono_font_size"
		]:
			control.add_theme_font_size_override(
				size_key,
				font_size
			)


func copy_style(style: StyleBox) -> StyleBox:
	return (
		style.duplicate(true) as StyleBox
		if style != null
		else StyleBoxEmpty.new()
	)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var configured_sizes: Dictionary = {
		"actor_frame_size": actor_frame_size,
		"empty_slot_size": empty_slot_size,
		"portrait_size": portrait_size,
		"status_row_size": status_row_size,
		"status_badge_size": status_badge_size,
		"bar_size": bar_size,
		"timeline_cell_size": timeline_cell_size,
		"timeline_card_size": timeline_card_size,
		"timeline_icon_size": timeline_icon_size,
		"module_slot_size": module_slot_size,
		"module_icon_size": module_icon_size
	}

	for size_entry: String in configured_sizes:
		var configured_size: Vector2 = (
			configured_sizes[size_entry]
		)

		if configured_size.x <= 0.0 or configured_size.y <= 0.0:
			errors.append(
				"Combat UI style '%s' must be positive."
				% size_entry
			)

	if (
		not is_equal_approx(
			timeline_card_size.x,
			timeline_card_size.y
		)
	):
		errors.append(
			"timeline_card_size must remain square."
		)

	return errors
