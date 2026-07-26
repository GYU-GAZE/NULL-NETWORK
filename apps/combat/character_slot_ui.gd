extends VBoxContainer
class_name CharacterSlotUI


var slot_index: int = -1
var current_actor: Variant = null
var is_ally_slot: bool = false
var is_preview: bool = false

var icon_rect: TextureRect
var hp_bar: ProgressBar
var stability_bar: ProgressBar
var original_hp_color: Color = Color.CRIMSON
var preview_tween: Tween
var ghost_overlay: TextureRect
var original_texture: Texture2D
var _is_drag_hovered: bool = false


func _ready() -> void:
	if not is_preview:
		add_to_group("CombatUI")

	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(
	actor: Variant,
	index: int,
	is_ally: bool
) -> void:
	current_actor = actor
	slot_index = index
	is_ally_slot = is_ally

	for child in get_children():
		child.queue_free()

	if current_actor == null:
		_build_empty_slot()
		return

	_build_actor_slot()


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
			Color(2, 2, 2, 1),
			0.3
		)
		preview_tween.tween_property(
			icon_rect,
			"modulate",
			Color.WHITE,
			0.3
		)

		var hp_delta := int(
			entry.get("hp_delta", 0)
		)

		if hp_delta != 0:
			hp_bar.get_theme_stylebox(
				"fill"
			).bg_color = (
				Color.LIME_GREEN
				if hp_delta > 0
				else Color.ORANGE
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

	hp_bar.get_theme_stylebox(
		"fill"
	).bg_color = original_hp_color
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

	var preview_slot := CharacterSlotUI.new()
	preview_slot.is_preview = true
	preview_slot.setup(
		current_actor,
		slot_index,
		is_ally_slot
	)
	preview_slot.modulate = Color(
		1,
		1,
		1,
		0.7
	)

	var center := Control.new()
	preview_slot.position = -Vector2(70, 65)
	center.add_child(preview_slot)
	set_drag_preview(center)

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
		get_tree().call_group(
			"CombatUI",
			"refresh_combat_field"
		)


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


func _build_empty_slot() -> void:
	var empty_slot := PanelContainer.new()
	empty_slot.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	empty_slot.custom_minimum_size = Vector2(
		96,
		80
	)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(
		0.3,
		0.3,
		0.3,
		0.5
	)
	empty_slot.add_theme_stylebox_override(
		"panel",
		style
	)
	add_child(empty_slot)

	ghost_overlay = TextureRect.new()
	ghost_overlay.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)
	ghost_overlay.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	ghost_overlay.custom_minimum_size = Vector2(
		72,
		40
	)
	ghost_overlay.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	ghost_overlay.modulate = Color(
		0.5,
		1.5,
		2.0,
		0.8
	)
	ghost_overlay.hide()
	empty_slot.add_child(ghost_overlay)


func _build_actor_slot() -> void:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = Vector2(96, 52)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = (
		Color.CYAN
		if current_actor.get("is_player", false)
		else (
			Color.LIME_GREEN
			if current_actor.get("is_ally", false)
			else Color.CRIMSON
		)
	)
	frame.add_theme_stylebox_override(
		"panel",
		style
	)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var header := Label.new()
	header.text = "Lv.%d [%s] %s.apk" % [
		int(current_actor.get("level", 1)),
		current_actor.get("type", "INIT"),
		current_actor.get("name", "Entity")
	]
	header.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	content.add_child(header)
	content.add_child(HSeparator.new())

	icon_rect = TextureRect.new()
	icon_rect.texture = current_actor.get("icon")
	original_texture = icon_rect.texture
	icon_rect.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)
	icon_rect.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	icon_rect.custom_minimum_size = Vector2(72, 30)
	icon_rect.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	content.add_child(icon_rect)
	frame.add_child(content)
	add_child(frame)

	hp_bar = _create_bar(
		float(current_actor.get("hp", 0.0)),
		float(current_actor.get("max_hp", 0.0)),
		"HP",
		Color.CRIMSON
	)
	stability_bar = _create_bar(
		float(current_actor.get(
			"stability",
			0.0
		)),
		float(current_actor.get(
			"max_stability",
			0.0
		)),
		"STB",
		Color.DODGER_BLUE
	)
	add_child(hp_bar)
	add_child(stability_bar)


func _create_bar(
	value: float,
	maximum: float,
	prefix: String,
	color: Color
) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = Vector2(96, 10)
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)

	var label := Label.new()
	label.text = "%s: %d/%d" % [
		prefix,
		int(roundf(value)),
		int(roundf(maximum))
	]
	label.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	label.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)
	label.add_theme_constant_override(
		"shadow_outline_size",
		2
	)
	bar.add_child(label)
	return bar


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
		if ghost_overlay:
			ghost_overlay.hide()
	elif icon_rect:
		icon_rect.texture = original_texture
		modulate = Color.WHITE
