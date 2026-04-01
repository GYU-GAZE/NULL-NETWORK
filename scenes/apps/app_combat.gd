extends Control

@export var test_encounter: CombatEncounter

var floating_offsets: Dictionary = {} # Guarda o "elevador" de cada personagem
@onready var menu_box: VBoxContainer = %MenuBox
@onready var execute_btn: Button = %ExecuteBtn
@onready var change_modules_btn: Button = %ChangeModulesBtn
@onready var module_swap_ui: VBoxContainer = %ModuleSwapUI
@onready var equipped_list: VBoxContainer = %EquippedModulesList
@onready var inventory_list: VBoxContainer = %InventoryModulesList

@onready var timeline_bar: HBoxContainer = %TimelineBar
@onready var enemies_container: HBoxContainer = %EnemiesContainer
@onready var allies_container: HBoxContainer = %AlliesContainer

var actor_nodes: Dictionary = {} # Guarda as referências da UI de cada personagem
@onready var combat_log: RichTextLabel = %CombatLog # Puxe o Log

@onready var hover_tooltip: PanelContainer = %HoverTooltip
@onready var tooltip_label: Label = %TooltipLabel

@onready var resolution_screen: PanelContainer = %ResolutionScreen
@onready var res_title: Label = resolution_screen.get_node("VBoxContainer/Title")
@onready var btn_consume: Button = %BtnConsume
@onready var btn_purify: Button = %BtnPurify
@onready var btn_tame: Button = %BtnTame

func _ready() -> void:
	# 1. ADICIONADO AQUI! Registra essa UI para receber o sinal do Drag & Drop
	add_to_group("CombatUI")
	
	CombatManager.timeline_generated.connect(_on_timeline_generated)
	CombatManager.stats_updated.connect(_update_field_ui)
	CombatManager.action_executed.connect(_on_action_executed)
	
	execute_btn.pressed.connect(func(): 
		execute_btn.disabled = true
		CombatManager.execute_cycle()
	)
	
	# 2. ATUALIZADO AQUI! Agora ele chama a função nova de refresh
	change_modules_btn.pressed.connect(func():
		module_swap_ui.visible = !module_swap_ui.visible
		if module_swap_ui.visible: 
			refresh_module_ui()
			# Pega a posição do Menu e soma a largura dele + 10 pixels de respiro!
			module_swap_ui.global_position = menu_box.global_position + Vector2(menu_box.size.x + 10, 0)
	)
	
	if test_encounter:
		CombatManager.load_encounter(test_encounter)
	CombatManager.combat_log_added.connect(_update_log)
	CombatManager.floating_text_requested.connect(_spawn_floating_text)
	
	CombatManager.combat_victory.connect(_on_victory)
	CombatManager.combat_defeat.connect(_on_defeat)
	CombatManager.cycle_ended_ready_for_next.connect(_on_cycle_ended)
	
	# AS ESCOLHAS DO GDD
	btn_consume.pressed.connect(func():
		print("CONSUME: XP Ganho. Destruiu o EXE.")
		hide() # Esconde o combate para voltar ao OS/Navigator
	)
	btn_purify.pressed.connect(func():
		print("PURIFY: EXE Purificado para APK. Ganhou Module Passivo.")
		hide()
	)
	btn_tame.pressed.connect(func():
		print("TAME: Trocou o seu APK atual pelo novo.")
		hide()
	)
# COMO O SO CARREGOU O COMBAT MANAGER ANTES, MANDAMOS DESENHAR A TELA LOGO NO NASCIMENTO!
	refresh_combat_field()
	CombatManager._build_timeline() # Garante que a timeline apareça logo de cara
func _update_log(msg: String) -> void:
	if combat_log:
		combat_log.append_text(msg + "\n")

func refresh_combat_field() -> void:
	_update_field_ui() # Atalho usado pelo Drag&Drop

func _spawn_floating_text(actor: Dictionary, text: String, color: Color) -> void:
	var key = actor.name
	if not actor_nodes.has(key): return
	var target_node: Control = actor_nodes[key] 
	
	var lbl = Label.new()
	lbl.text = text
	lbl.top_level = true 
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_outline_size", 4)
	
	add_child(lbl)
	
	# Pega o andar atual do elevador (Começa no 0)
	var current_offset = floating_offsets.get(key, 0)
	
	# Posição = Centro do Ícone - 20px - O Andar do Elevador
	lbl.global_position = target_node.global_position + (target_node.size / 2.0) - Vector2(20, 20 + current_offset)
	
	# Sobe o elevador 35 pixels para o próximo texto que vier neste mesmo ciclo!
	floating_offsets[key] = current_offset + 35 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(lbl, "global_position", lbl.global_position + Vector2(randf_range(-15, 15), -60), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.chain().tween_callback(lbl.queue_free)
	
# ==========================================
# RENDERIZANDO A BATALHA
# ==========================================
# (Atenção: Modifique a sua função _update_field_ui para retirar as cores antigas)
func _update_field_ui() -> void:
	# Passamos o 'true' pros aliados ativarem o Drag&Drop
	_draw_team(CombatManager.enemy_team, enemies_container, false)
	_draw_team(CombatManager.ally_team, allies_container, true)

# ==========================================
# RENDERIZANDO A BATALHA (BARRAS E ÍCONES)
# ==========================================
func _draw_team(team_array: Array, container: Control, is_ally: bool) -> void:
	for c in container.get_children(): c.queue_free()
	
	# Agora o Container Principal só gera os 4 Slots Novinhos!
	for i in range(4):
		var slot = CharacterSlotUI.new()
		container.add_child(slot)
		slot.setup(team_array[i], i, is_ally)
		
		# Recarrega as referências dos nós para o Dano Flutuante
		if team_array[i] != null:
			actor_nodes[team_array[i].name] = slot.icon_rect
# ==========================================
# RENDERIZANDO A TIMELINE (CORES DA FILA)
# ==========================================
func _on_timeline_generated(actions: Array) -> void:
	for c in timeline_bar.get_children(): c.queue_free()
	
	for action in actions:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(80, 100)
		
		var mod = action.module
		if mod:
			# TOOLTIP E PREVISÃO (GHOST HP)
			var t_text = "[%s]\n%s\nPower: %d | Custo: %d STB" % [mod.module_name, mod.description, mod.power, mod.stability_cost]
			panel.mouse_entered.connect(func(): 
				show_tooltip(t_text)
				get_tree().call_group("CombatUI", "preview_timeline_action", action)
			)
			panel.mouse_exited.connect(func(): 
				hide_tooltip()
				get_tree().call_group("CombatUI", "clear_timeline_preview")
			)
			
		var bg_color = Color.CRIMSON
		if action.actor.is_ally: bg_color = Color.DODGER_BLUE if action.actor.is_player else Color.LIME_GREEN
		var style = StyleBoxFlat.new()
		style.bg_color = bg_color.darkened(0.4)
		style.border_width_bottom = 4
		style.border_color = bg_color
		panel.add_theme_stylebox_override("panel", style)
		
		var mod_vbox = VBoxContainer.new()
		mod_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var lbl = Label.new()
		lbl.text = mod.module_name if mod else "VAZIO"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		mod_vbox.add_child(lbl)
		
		if mod and mod.module_icon:
			var ic = TextureRect.new()
			ic.texture = mod.module_icon
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(40, 40)
			mod_vbox.add_child(ic)
			
		panel.add_child(mod_vbox)
		timeline_bar.add_child(panel)

func _on_action_executed(index: int, action_data: Dictionary) -> void:
	floating_offsets.clear() # <--- ADICIONE ESTA LINHA AQUI! A cada nova ação na timeline, o elevador zera.
	
	if index < timeline_bar.get_child_count():
		var panel = timeline_bar.get_child(index)
		panel.modulate = Color(0.3, 0.3, 0.3, 1.0) # Escurece
		
		# A TREMEDEIRA! (Screen Shake Local)
		var t = create_tween()
		var orig = panel.position
		t.tween_property(panel, "position", orig + Vector2(5, -5), 0.05)
		t.tween_property(panel, "position", orig + Vector2(-5, 5), 0.05)
		t.tween_property(panel, "position", orig, 0.05)

# ==========================================
# O SISTEMA DE INVENTÁRIO (SWAP NATIVO)
# ==========================================
# 3. TUDO DAQUI PRA BAIXO FOI REESCRITO PARA USAR O DRAG & DROP

func refresh_module_ui() -> void:
	_populate_equip_list()
	_populate_inventory_list()

func _populate_equip_list() -> void:
	for c in equipped_list.get_children(): c.queue_free()
	var player = CombatManager.ally_team[0]
	
	for i in range(4):
		var slot = ModuleSlotUI.new()
		equipped_list.add_child(slot)
		slot.setup(player.modules[i], i, true)

func _populate_inventory_list() -> void:
	for c in inventory_list.get_children(): c.queue_free()
	var pool = test_encounter.allies[0].module_pool 
	
	for i in range(pool.size()):
		var slot = ModuleSlotUI.new()
		inventory_list.add_child(slot)
		slot.setup(pool[i], -1, false)

func _process(delta: float) -> void:
	# Se o tooltip estiver ligado, ele persegue o mouse o tempo todo!
	if hover_tooltip.visible:
		hover_tooltip.global_position = get_global_mouse_position() + Vector2(15, 15)

func show_tooltip(text: String) -> void:
	tooltip_label.text = text
	hover_tooltip.show()

func hide_tooltip() -> void:
	hover_tooltip.hide()

# ==========================================
# GESTÃO DO LOOP E RESOLUÇÃO
# ==========================================
func _on_cycle_ended() -> void:
	# O turno acabou e ninguém morreu. Liga o botão de novo!
	execute_btn.disabled = false

func _on_victory() -> void:
	res_title.text = "VITÓRIA"
	res_title.add_theme_color_override("font_color", Color.LIME_GREEN)
	resolution_screen.show()

func _on_defeat() -> void:
	res_title.text = "DERROTA CRÍTICA"
	res_title.add_theme_color_override("font_color", Color.CRIMSON)
	btn_purify.hide() # Na derrota não há loot!
	btn_tame.hide()
	btn_consume.text = "REINICIAR SISTEMA" # Reaproveitamos o botão para fechar
	resolution_screen.show()
