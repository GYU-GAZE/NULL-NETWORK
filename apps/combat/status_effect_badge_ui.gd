extends PanelContainer
class_name StatusEffectBadgeUI


signal tooltip_requested(text: String)
signal tooltip_hidden


@export var ui_style: CombatUIStyleData = preload(
	"res://data/content/combat/default_combat_ui_style.tres"
)

@onready var icon_rect: TextureRect = %StatusIcon
@onready var fallback_label: Label = %FallbackLabel
@onready var stack_label: Label = %StackLabel


var status_instance: CombatStatusInstance


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(
	instance: CombatStatusInstance,
	style: CombatUIStyleData = null
) -> void:
	status_instance = instance

	if style != null:
		ui_style = style

	_apply_style()

	if status_instance == null or status_instance.data == null:
		icon_rect.texture = null
		icon_rect.hide()
		fallback_label.text = "?"
		fallback_label.show()
		stack_label.text = "0"
		tooltip_text = ""
		return

	var status := status_instance.data
	icon_rect.texture = status.icon
	icon_rect.visible = status.icon != null
	fallback_label.visible = status.icon == null
	fallback_label.text = status.display_name.left(1)
	stack_label.text = str(status_instance.stacks)
	tooltip_text = status.get_runtime_tooltip(
		status_instance
	)


func _apply_style() -> void:
	if ui_style == null:
		return

	custom_minimum_size = ui_style.status_badge_size
	add_theme_stylebox_override(
		"panel",
		ui_style.copy_style(
			ui_style.status_badge_style
		)
	)
	ui_style.apply_font(
		fallback_label,
		ui_style.status_count_font,
		ui_style.status_count_font_size
	)
	ui_style.apply_font(
		stack_label,
		ui_style.status_count_font,
		ui_style.status_count_font_size
	)
	stack_label.add_theme_color_override(
		"font_color",
		ui_style.status_stack_color
	)
	stack_label.add_theme_color_override(
		"font_shadow_color",
		ui_style.status_stack_shadow_color
	)
	stack_label.add_theme_constant_override(
		"shadow_outline_size",
		ui_style.status_stack_outline_size
	)


func _on_mouse_entered() -> void:
	if not tooltip_text.is_empty():
		tooltip_requested.emit(tooltip_text)


func _on_mouse_exited() -> void:
	tooltip_hidden.emit()
