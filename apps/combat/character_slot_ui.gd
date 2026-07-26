extends VBoxContainer
class_name CharacterSlotUI


var slot_index: int = -1
var current_actor: Variant = null
var runtime_slot: CombatRuntimeSlot
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
	is_ally: bool,
	slot_state: CombatRuntimeSlot = null
) -> void:
	current_actor = actor
	slot_index = index
	is_ally_slot = is_ally
	runtime_slot = slot_state

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

	if runtime_slot != null and not runtime_slot.enabled:
		style.bg_color = Color(0.2, 0.03, 0.03, 0.8)
		style.border_color = Color.CRIMSON

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

	if runtime_slot != null and not runtime_slot.enabled:
		var locked_label := Label.new()
		locked_label.text = "LOCKED"
		locked_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		locked_label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)
		locked_label.set_anchors_preset(
			Control.PRESET_FULL_RECT
		)
		locked_label.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)
		empty_slot.add_child(locked_label)


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

	if runtime_slot != null and not runtime_slot.enabled:
		style.border_color = Color.CRIMSON
		frame.tooltip_text = (
			"This position is disabled. Its current "
			+ "occupant remains, but no new actor can enter."
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
	content.add_child(_build_status_list())

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


func _build_status_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "StatusScroll"
	scroll.custom_minimum_size = Vector2(96, 22)
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS

	var row := HBoxContainer.new()
	row.name = "StatusRow"
	row.add_theme_constant_override("separation", 2)
	scroll.add_child(row)

	for instance in current_actor.get(
		"active_statuses",
		[]
	):
		if (
			not (instance is CombatStatusInstance)
			or instance.data == null
		):
			continue

		row.add_child(
			_create_status_icon(instance)
		)

	return scroll


func _create_status_icon(
	instance: CombatStatusInstance
) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(20, 20)
	var tooltip := (
		instance.data.get_runtime_tooltip(instance)
	)
	panel.tooltip_text = tooltip
	panel.mouse_entered.connect(
		func() -> void:
			get_tree().call_group(
				"CombatUI",
				"show_tooltip",
				tooltip
			)
	)
	panel.mouse_exited.connect(
		func() -> void:
			get_tree().call_group(
				"CombatUI",
				"hide_tooltip"
			)
	)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.12, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color.CYAN
	panel.add_theme_stylebox_override("panel", style)

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(18, 18)
	panel.add_child(stack)

	if instance.data.icon != null:
		var icon := TextureRect.new()
		icon.texture = instance.data.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.text = instance.data.display_name.left(1)
		fallback.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		fallback.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)
		fallback.set_anchors_preset(
			Control.PRESET_FULL_RECT
		)
		fallback.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)
		stack.add_child(fallback)

	var count := Label.new()
	count.text = str(instance.stacks)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.set_anchors_preset(Control.PRESET_FULL_RECT)
	count.add_theme_color_override(
		"font_color",
		Color.WHITE
	)
	count.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)
	count.add_theme_constant_override(
		"shadow_outline_size",
		2
	)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(count)
	return panel


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
