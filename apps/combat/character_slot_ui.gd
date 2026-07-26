extends VBoxContainer
class_name CharacterSlotUI


signal tooltip_requested(text: String)
signal tooltip_hidden
signal field_refresh_requested


const STATUS_BADGE_SCENE: PackedScene = preload(
	"res://apps/combat/status_effect_badge_ui.tscn"
)


@export var ui_style: CombatUIStyleData = preload(
	"res://data/content/combat/default_combat_ui_style.tres"
)

@onready var actor_frame: PanelContainer = %ActorFrame
@onready var actor_header: Label = %ActorHeader
@onready var status_scroll: ScrollContainer = %StatusScroll
@onready var status_row: HBoxContainer = %StatusRow
@onready var icon_rect: TextureRect = %Portrait
@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var stability_bar: ProgressBar = %StabilityBar
@onready var stability_label: Label = %StabilityLabel
@onready var empty_frame: PanelContainer = %EmptyFrame
@onready var ghost_overlay: TextureRect = %GhostOverlay
@onready var locked_label: Label = %LockedLabel


var slot_index: int = -1
var current_actor: Variant = null
var runtime_slot: CombatRuntimeSlot
var is_ally_slot: bool = false
var is_preview: bool = false

var preview_tween: Tween
var original_texture: Texture2D
var original_hp_style: StyleBox
var _is_drag_hovered: bool = false


func _ready() -> void:
	if not is_preview:
		add_to_group("CombatUI")

	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(
	actor: Variant,
	index: int,
	is_ally: bool,
	slot_state: CombatRuntimeSlot = null,
	style: CombatUIStyleData = null
) -> void:
	current_actor = actor
	slot_index = index
	is_ally_slot = is_ally
	runtime_slot = slot_state

	if style != null:
		ui_style = style

	_apply_style()
	_clear_status_badges()

	if current_actor == null:
		_show_empty_slot()
		return

	_show_actor_slot()


func preview_timeline_action(
	action: Dictionary
) -> void:
	if (
		is_queued_for_deletion()
		or current_actor == null
	):
		return

	var preview := CombatManager.preview_action(action)

	for entry in preview.get("entries", []):
		if (
			int(entry.get("target_uid", -1))
			!= int(current_actor.get("uid", -1))
		):
			continue

		if preview_tween:
			preview_tween.kill()

		preview_tween = create_tween().set_loops()
		preview_tween.tween_property(
			icon_rect,
			"modulate",
			ui_style.actor_preview_pulse_color,
			ui_style.actor_preview_pulse_duration
		)
		preview_tween.tween_property(
			icon_rect,
			"modulate",
			Color.WHITE,
			ui_style.actor_preview_pulse_duration
		)

		var hp_delta := int(
			entry.get("hp_delta", 0)
		)

		if hp_delta != 0:
			var preview_style := (
				ui_style.hp_preview_heal_style
				if hp_delta > 0
				else ui_style.hp_preview_damage_style
			)
			hp_bar.add_theme_stylebox_override(
				"fill",
				ui_style.copy_style(preview_style)
			)
			hp_bar.value = clampf(
				float(current_actor.get("hp", 0.0))
				+ hp_delta,
				0.0,
				float(current_actor.get(
					"max_hp",
					0.0
				))
			)

		var stability_delta := int(
			entry.get("stability_delta", 0)
		)

		if stability_delta != 0:
			stability_bar.value = clampf(
				float(current_actor.get(
					"stability",
					0.0
				)) + stability_delta,
				0.0,
				float(current_actor.get(
					"max_stability",
					0.0
				))
			)
		return


func clear_timeline_preview() -> void:
	if (
		is_queued_for_deletion()
		or current_actor == null
	):
		return

	if preview_tween:
		preview_tween.kill()

	icon_rect.modulate = Color.WHITE
	hp_bar.add_theme_stylebox_override(
		"fill",
		ui_style.copy_style(original_hp_style)
	)
	hp_bar.value = current_actor.get("hp", 0.0)
	stability_bar.value = current_actor.get(
		"stability",
		0.0
	)


func _get_drag_data(
	_at_position: Vector2
) -> Variant:
	if current_actor == null or not is_ally_slot:
		return null

	var preview := TextureRect.new()
	preview.texture = current_actor.get("icon")
	preview.custom_minimum_size = (
		ui_style.portrait_size
		if ui_style != null
		else Vector2(72, 30)
	)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	preview.modulate = (
		ui_style.actor_drag_preview_color
		if ui_style != null
		else Color(1, 1, 1, 0.7)
	)
	set_drag_preview(preview)

	return {
		"type": &"combat_character",
		"source_slot": self
	}


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	return (
		data is Dictionary
		and data.get("type") == &"combat_character"
		and is_ally_slot
		and runtime_slot != null
		and runtime_slot.enabled
	)


func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:
	var source := (
		data.get("source_slot") as CharacterSlotUI
	)

	if source == null:
		return

	if CombatManager.swap_ally_slots(
		source.slot_index,
		slot_index
	):
		field_refresh_requested.emit()


func _process(_delta: float) -> void:
	if is_preview or not is_ally_slot:
		return

	if get_viewport().gui_is_dragging():
		var is_hovering := get_global_rect().has_point(
			get_global_mouse_position()
		)

		if is_hovering and not _is_drag_hovered:
			_is_drag_hovered = true
			_show_ghost_preview()
		elif (
			not is_hovering
			and _is_drag_hovered
		):
			_is_drag_hovered = false
			_hide_ghost_preview()
	elif _is_drag_hovered:
		_is_drag_hovered = false
		_hide_ghost_preview()


func _apply_style() -> void:
	if ui_style == null:
		return

	actor_frame.custom_minimum_size = (
		ui_style.actor_frame_size
	)
	empty_frame.custom_minimum_size = (
		ui_style.empty_slot_size
	)
	icon_rect.custom_minimum_size = (
		ui_style.portrait_size
	)
	ghost_overlay.custom_minimum_size = (
		ui_style.portrait_size
	)
	ghost_overlay.modulate = ui_style.actor_ghost_color
	status_scroll.custom_minimum_size = (
		ui_style.status_row_size
	)
	status_row.add_theme_constant_override(
		"separation",
		ui_style.status_separation
	)
	hp_bar.custom_minimum_size = ui_style.bar_size
	stability_bar.custom_minimum_size = (
		ui_style.bar_size
	)
	ui_style.apply_font(
		actor_header,
		ui_style.actor_name_font,
		ui_style.actor_name_font_size
	)
	ui_style.apply_font(
		locked_label,
		ui_style.actor_name_font,
		ui_style.actor_name_font_size
	)
	ui_style.apply_font(
		hp_label,
		ui_style.bar_font,
		ui_style.bar_font_size
	)
	ui_style.apply_font(
		stability_label,
		ui_style.bar_font,
		ui_style.bar_font_size
	)

	hp_bar.add_theme_stylebox_override(
		"background",
		ui_style.copy_style(
			ui_style.bar_background_style
		)
	)
	stability_bar.add_theme_stylebox_override(
		"background",
		ui_style.copy_style(
			ui_style.bar_background_style
		)
	)
	original_hp_style = ui_style.copy_style(
		ui_style.hp_fill_style
	)
	hp_bar.add_theme_stylebox_override(
		"fill",
		ui_style.copy_style(original_hp_style)
	)
	stability_bar.add_theme_stylebox_override(
		"fill",
		ui_style.copy_style(
			ui_style.stability_fill_style
		)
	)


func _show_empty_slot() -> void:
	actor_frame.hide()
	hp_bar.hide()
	stability_bar.hide()
	empty_frame.show()
	ghost_overlay.hide()

	var is_locked := (
		runtime_slot != null
		and not runtime_slot.enabled
	)
	locked_label.visible = is_locked
	empty_frame.add_theme_stylebox_override(
		"panel",
		ui_style.copy_style(
			ui_style.locked_slot_style
			if is_locked
			else ui_style.empty_slot_style
		)
	)


func _show_actor_slot() -> void:
	empty_frame.hide()
	actor_frame.show()
	hp_bar.show()
	stability_bar.show()

	actor_header.text = "Lv.%d [%s] %s.apk" % [
		int(current_actor.get("level", 1)),
		current_actor.get("type", "INIT"),
		current_actor.get("name", "Entity")
	]
	icon_rect.texture = current_actor.get("icon")
	original_texture = icon_rect.texture

	var actor_style: StyleBox = (
		ui_style.enemy_actor_style
	)

	if current_actor.get("is_player", false):
		actor_style = ui_style.player_actor_style
	elif current_actor.get("is_ally", false):
		actor_style = ui_style.ally_actor_style

	if runtime_slot != null and not runtime_slot.enabled:
		actor_style = ui_style.disabled_actor_style
		actor_frame.tooltip_text = (
			"This position is disabled. Its current "
			+ "occupant remains, but no new actor can enter."
		)
	else:
		actor_frame.tooltip_text = ""

	actor_frame.add_theme_stylebox_override(
		"panel",
		ui_style.copy_style(actor_style)
	)
	_build_status_badges()
	_configure_bar(
		hp_bar,
		hp_label,
		float(current_actor.get("hp", 0.0)),
		float(current_actor.get("max_hp", 0.0)),
		"HP"
	)
	_configure_bar(
		stability_bar,
		stability_label,
		float(current_actor.get(
			"stability",
			0.0
		)),
		float(current_actor.get(
			"max_stability",
			0.0
		)),
		"STB"
	)


func _clear_status_badges() -> void:
	for child in status_row.get_children():
		child.queue_free()


func _build_status_badges() -> void:
	for instance in current_actor.get(
		"active_statuses",
		[]
	):
		if (
			not (instance is CombatStatusInstance)
			or instance.data == null
		):
			continue

		var badge := (
			STATUS_BADGE_SCENE.instantiate()
			as StatusEffectBadgeUI
		)

		if badge == null:
			continue

		status_row.add_child(badge)
		badge.tooltip_requested.connect(
			func(text: String) -> void:
				tooltip_requested.emit(text)
		)
		badge.tooltip_hidden.connect(
			func() -> void:
				tooltip_hidden.emit()
		)
		badge.setup(instance, ui_style)


func _configure_bar(
	bar: ProgressBar,
	label: Label,
	value: float,
	maximum: float,
	prefix: String
) -> void:
	bar.max_value = maximum
	bar.value = value
	label.text = "%s: %d/%d" % [
		prefix,
		int(roundf(value)),
		int(roundf(maximum))
	]


func _show_ghost_preview() -> void:
	var data: Variant = (
		get_viewport().gui_get_drag_data()
	)

	if (
		not (data is Dictionary)
		or data.get("type") != &"combat_character"
	):
		return

	var source := (
		data.get("source_slot") as CharacterSlotUI
	)

	if source == null or source.current_actor == null:
		return

	if current_actor == null:
		ghost_overlay.texture = source.current_actor.get(
			"icon"
		)
		ghost_overlay.show()
	else:
		icon_rect.texture = source.current_actor.get(
			"icon"
		)
		modulate = Color(1.5, 1.5, 1.5, 0.5)


func _hide_ghost_preview() -> void:
	if current_actor == null:
		ghost_overlay.hide()
	else:
		icon_rect.texture = original_texture
		modulate = Color.WHITE
