extends CenterContainer
class_name TimelineActionCardUI


signal tooltip_requested(text: String)
signal tooltip_hidden
signal preview_requested(action: Dictionary)
signal preview_cleared


@export var ui_style: CombatUIStyleData = preload(
	"res://data/content/combat/default_combat_ui_style.tres"
)

@onready var card: PanelContainer = %Card
@onready var content: VBoxContainer = %Content
@onready var icon_rect: TextureRect = %ModuleIcon
@onready var icon_fallback: ColorRect = %IconFallback
@onready var name_label: Label = %ModuleName


var action_data: Dictionary = {}
var _tooltip_text: String = ""
var _feedback_tween: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(
	action: Dictionary,
	style: CombatUIStyleData = null
) -> void:
	action_data = action

	if style != null:
		ui_style = style

	var module: ModuleData = action_data.get(
		"module"
	) as ModuleData
	var player_action: PlayerActionData = action_data.get(
		"player_action"
	) as PlayerActionData
	var actor: Variant = action_data.get("actor")

	_apply_style(actor)
	icon_rect.texture = (
		player_action.icon
		if player_action != null
		else module.module_icon
		if module != null
		else null
	)
	icon_rect.visible = (
		(player_action != null and player_action.icon != null)
		or (module != null and module.module_icon != null)
	)
	icon_fallback.visible = not icon_rect.visible

	if player_action != null:
		name_label.text = player_action.display_name
		_tooltip_text = CombatManager.get_player_action_tooltip(
			player_action,
			int(action_data.get("target_uid", -1))
		)
		return

	if module == null:
		name_label.text = "VAZIO"
		_tooltip_text = ""
		return

	name_label.text = (
		"%s ×%d"
		% [
			module.module_name,
			module.execution_count
		]
		if module.execution_count > 1
		else module.module_name
	)
	_tooltip_text = CombatManager.get_module_tooltip(
		module,
		action_data
	)


func get_card_control() -> PanelContainer:
	return card


func play_execution_feedback() -> void:
	if _feedback_tween:
		_feedback_tween.kill()

	card.modulate = ui_style.timeline_executed_modulate
	var original_position := card.position
	var feedback_offset: Vector2 = (
		ui_style.timeline_feedback_offset
	)
	var step_duration: float = (
		ui_style.timeline_feedback_step_duration
	)
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(
		card,
		"position",
		original_position + feedback_offset,
		step_duration
	)
	_feedback_tween.tween_property(
		card,
		"position",
		original_position - feedback_offset,
		step_duration
	)
	_feedback_tween.tween_property(
		card,
		"position",
		original_position,
		step_duration
	)


func _apply_style(actor: Variant) -> void:
	if ui_style == null:
		return

	custom_minimum_size = ui_style.timeline_cell_size
	card.custom_minimum_size = ui_style.timeline_card_size
	icon_rect.custom_minimum_size = ui_style.timeline_icon_size
	icon_fallback.custom_minimum_size = (
		ui_style.timeline_icon_size
	)
	content.add_theme_constant_override(
		"separation",
		ui_style.timeline_separation
	)
	ui_style.apply_font(
		name_label,
		ui_style.timeline_font,
		ui_style.timeline_font_size
	)

	var card_style: StyleBox = (
		ui_style.enemy_timeline_style
	)
	var fallback_color: Color = (
		ui_style.enemy_fallback_color
	)

	if actor is Dictionary and bool(
		actor.get("is_ally", false)
	):
		if bool(actor.get("is_player", false)):
			card_style = ui_style.player_timeline_style
			fallback_color = (
				ui_style.player_fallback_color
			)
		else:
			card_style = ui_style.ally_timeline_style
			fallback_color = (
				ui_style.ally_fallback_color
			)

	card.add_theme_stylebox_override(
		"panel",
		ui_style.copy_style(card_style)
	)
	icon_fallback.color = fallback_color


func _on_mouse_entered() -> void:
	if _tooltip_text.is_empty():
		return

	tooltip_requested.emit(_tooltip_text)
	preview_requested.emit(action_data)


func _on_mouse_exited() -> void:
	tooltip_hidden.emit()
	preview_cleared.emit()
