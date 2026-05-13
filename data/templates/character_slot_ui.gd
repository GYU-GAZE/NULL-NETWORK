extends VBoxContainer
class_name CharacterSlotUI

var slot_index: int = -1
var current_actor: Variant = null
var is_ally_slot: bool = false
var is_preview: bool = false # Evita que o clone grudado no mouse faça as lógicas de Hover!

var icon_rect: TextureRect
var hp_bar: ProgressBar
var original_hp_color: Color
var preview_tween: Tween

# Variáveis do Ghost Hover
var is_drag_hovered: bool = false
var ghost_overlay: TextureRect
var original_texture: Texture2D

func _ready() -> void:
	if not is_preview:
		add_to_group("CombatUI") 
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP 

func setup(actor: Variant, index: int, is_ally: bool) -> void:
	current_actor = actor
	slot_index = index
	is_ally_slot = is_ally
	
	for c in get_children(): c.queue_free()
	
	if current_actor == null:
		var empty_slot = PanelContainer.new()
		empty_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		empty_slot.custom_minimum_size = Vector2(140, 130)
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
		empty_style.border_width_left = 2
		empty_style.border_width_top = 2
		empty_style.border_width_right = 2
		empty_style.border_width_bottom = 2
		empty_style.border_color = Color(0.3, 0.3, 0.3, 0.5)
		empty_slot.add_theme_stylebox_override("panel", empty_style)
		add_child(empty_slot)
		
		# PREPARA O FANTASMA (Escondido por padrão)
		ghost_overlay = TextureRect.new()
		ghost_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost_overlay.custom_minimum_size = Vector2(100, 70)
		ghost_overlay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ghost_overlay.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ghost_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost_overlay.modulate = Color(0.5, 1.5, 2.0, 0.8) # Azul neon holográfico
		ghost_overlay.hide()
		empty_slot.add_child(ghost_overlay)
		return

	var cube_frame = PanelContainer.new()
	cube_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	cube_frame.custom_minimum_size = Vector2(140, 130)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.CYAN if current_actor.is_player else (Color.LIME_GREEN if current_actor.is_ally else Color.CRIMSON)
	cube_frame.add_theme_stylebox_override("panel", style)
	
	var cube_vbox = VBoxContainer.new()
	cube_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	var lvl_lbl = Label.new()
	lvl_lbl.text = "Lv." + str(current_actor.get("level", 1)) + " "
	lvl_lbl.add_theme_font_size_override("font_size", 10)
	lvl_lbl.add_theme_color_override("font_color", Color.GOLD)
	var type_lbl = Label.new()
	type_lbl.text = "[" + current_actor.get("type", "INIT") + "] "
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.add_theme_color_override("font_color", Color.LIGHT_SKY_BLUE)
	var name_lbl = Label.new()
	name_lbl.text = current_actor.name + ".apk"
	name_lbl.add_theme_font_size_override("font_size", 12)
	header_hbox.add_child(lvl_lbl)
	header_hbox.add_child(type_lbl)
	header_hbox.add_child(name_lbl)
	
	cube_vbox.add_child(header_hbox)
	cube_vbox.add_child(HSeparator.new())
	
	icon_rect = TextureRect.new()
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	icon_rect.texture = current_actor.icon
	original_texture = current_actor.icon # Salva a textura original para o preview de Swap
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(100, 70)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cube_vbox.add_child(icon_rect)
	
	cube_frame.add_child(cube_vbox)
	add_child(cube_frame)
	
	var create_bar = func(val: int, max_val: int, prefix: String, color: Color):
		var bar = ProgressBar.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		bar.custom_minimum_size = Vector2(140, 18)
		bar.max_value = max_val
		bar.value = val
		bar.show_percentage = false
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = color
		bar.add_theme_stylebox_override("fill", fill_style)
		var lbl = Label.new()
		lbl.text = ("%s: %d/%d" % [prefix, val, max_val]) if max_val > 0 else ("%s: %d" % [prefix, val])
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		lbl.add_theme_constant_override("shadow_outline_size", 2)
		bar.add_child(lbl)
		return bar

	var bars_margin = MarginContainer.new()
	bars_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	bars_margin.add_theme_constant_override("margin_top", 4) 
	var bars_vbox = VBoxContainer.new()
	bars_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	hp_bar = create_bar.call(current_actor.hp, current_actor.max_hp, "HP", Color.CRIMSON)
	original_hp_color = Color.CRIMSON
	
	bars_vbox.add_child(hp_bar)
	bars_vbox.add_child(create_bar.call(current_actor.stability, current_actor.max_stability, "STB", Color.DODGER_BLUE))
	
	bars_margin.add_child(bars_vbox)
	add_child(bars_margin)

# ==========================================
# O NOVO DRAG & DROP CLONADO
# ==========================================
func _get_drag_data(at_position: Vector2) -> Variant:
	if current_actor == null or not is_ally_slot: return null 
	
	# FABRICA UM CLONE PERFEITO DO PERSONAGEM PARA O MOUSE!
	var preview_slot = CharacterSlotUI.new()
	preview_slot.is_preview = true # Diz a ele para não rodar a lógica de colisão
	preview_slot.setup(current_actor, slot_index, is_ally_slot)
	preview_slot.modulate = Color(1, 1, 1, 0.7) # Deixa ele translúcido
	
	var drag_center = Control.new()
	preview_slot.position = -Vector2(70, 65) # Centraliza (Metade de 140x130)
	drag_center.add_child(preview_slot)
	
	set_drag_preview(drag_center)
	return {"type": "character", "source_slot": self}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "character" and is_ally_slot

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var source: CharacterSlotUI = data["source_slot"]
	var team = CombatManager.ally_team
	
	var temp = team[self.slot_index]
	team[self.slot_index] = team[source.slot_index]
	team[source.slot_index] = temp
	
	CombatManager._build_timeline() 
	get_tree().call_group("CombatUI", "refresh_combat_field")

# ==========================================
# GHOST PREVIEW (O Imã do Tabuleiro)
# ==========================================
func _process(_delta: float) -> void:
	if is_preview or not is_ally_slot: return # Preview e Inimigos não leem o mouse
	
	var dragging = get_viewport().gui_is_dragging()
	if dragging:
		var mouse_pos = get_global_mouse_position()
		var is_hovering = get_global_rect().has_point(mouse_pos)
		
		if is_hovering and not is_drag_hovered:
			is_drag_hovered = true
			_show_ghost_preview()
		elif not is_hovering and is_drag_hovered:
			is_drag_hovered = false
			_hide_ghost_preview()
	else:
		if is_drag_hovered:
			is_drag_hovered = false
			_hide_ghost_preview()

func _show_ghost_preview() -> void:
	var data = get_viewport().gui_get_drag_data()
	if typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "character":
		var dragged_actor = data["source_slot"].current_actor
		
		if current_actor == null:
			# SLOT VAZIO: O fantasma azul holográfico aparece dentro dele!
			if ghost_overlay and dragged_actor:
				ghost_overlay.texture = dragged_actor.icon
				ghost_overlay.show()
		else:
			# SLOT OCUPADO: Indica o "Swap" mudando o ícone do morador local e acendendo a luz
			if dragged_actor and icon_rect:
				icon_rect.texture = dragged_actor.icon
				modulate = Color(1.5, 1.5, 1.5, 0.5) # Brilho Glow + Translúcido

func _hide_ghost_preview() -> void:
	if current_actor == null:
		if ghost_overlay:
			ghost_overlay.hide()
	else:
		if icon_rect and original_texture:
			icon_rect.texture = original_texture # Restaura o dono original
		modulate = Color.WHITE

# ==========================================
# FEEDBACK PREDITIVO DA TIMELINE
# ==========================================
func preview_timeline_action(action: Dictionary) -> void:
	if is_queued_for_deletion() or current_actor == null: return
	
	if typeof(action.target) == TYPE_DICTIONARY and action.target.get("uid") == current_actor.get("uid"):
		if preview_tween: preview_tween.kill()
		preview_tween = create_tween().set_loops()
		preview_tween.tween_property(icon_rect, "modulate", Color(2, 2, 2, 1), 0.3)
		preview_tween.tween_property(icon_rect, "modulate", Color.WHITE, 0.3)
		
		hp_bar.get_theme_stylebox("fill").bg_color = Color.ORANGE
		
		if action.module.module_type == "Attack":
			var atk_stat = action.actor.get(action.module.scaling_stat.to_lower(), 0)
			var raw_dmg = action.module.power + (atk_stat * action.module.scaling_factor)
			var def_stat = current_actor.get("def", 0)
			var final_dmg = max(1, raw_dmg - def_stat)
			
			hp_bar.value = max(0, current_actor.hp - final_dmg)

func clear_timeline_preview() -> void:
	if is_queued_for_deletion() or current_actor == null: return
	if preview_tween:
		preview_tween.kill()
		icon_rect.modulate = Color.WHITE
		
	hp_bar.get_theme_stylebox("fill").bg_color = original_hp_color
	hp_bar.value = current_actor.hp
