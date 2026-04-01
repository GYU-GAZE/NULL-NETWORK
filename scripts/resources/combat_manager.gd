extends Node

signal combat_victory
signal combat_defeat
signal cycle_ended_ready_for_next
signal combat_log_added(message: String)
signal floating_text_requested(actor: Dictionary, text: String, color: Color)
signal timeline_generated(actions: Array)
signal stats_updated()
signal action_executed(index: int, action_data: Dictionary)

var ally_team: Array = [null, null, null, null]
var enemy_team: Array = [null, null, null, null]
var current_cycle_actions: Array = []

func load_encounter(encounter: CombatEncounter) -> void:
	ally_team = [null, null, null, null]
	enemy_team = [null, null, null, null]
	
	for i in range(min(4, encounter.allies.size())):
		if encounter.allies[i] != null:
			ally_team[i] = _create_combatant_dict(encounter.allies[i], true, i == 0)
			
	for i in range(min(4, encounter.enemies.size())):
		if encounter.enemies[i] != null:
			enemy_team[i] = _create_combatant_dict(encounter.enemies[i], false, false)
			
	stats_updated.emit()
	_build_timeline()

func _create_combatant_dict(data: CharacterLoadout, is_ally: bool, is_player: bool = false) -> Dictionary:
	return {
		"uid": randi(), # <--- A IDENTIDADE ÚNICA (O SEGREDO!)
		"name": data.char_name, "icon": data.combat_icon, 
		"level": data.level, "type": data.apk_type,
		"hp": data.max_hp, "max_hp": data.max_hp,
		"stability": data.max_stability, "max_stability": data.max_stability,
		"atk": data.base_atk, "def": data.base_def, "dodge": data.dodge_chance,
		"modules": data.equipped_modules.duplicate(),
		"is_ally": is_ally, "is_player": is_player, "active_effects": []
	}

func _build_timeline() -> void:
	current_cycle_actions.clear()
	var ally_actors = _get_timeline_actors(ally_team)
	var enemy_actors = _get_timeline_actors(enemy_team)
	
	for i in range(4):
		if i < ally_actors.size():
			var actor = ally_actors[i]
			var mod = actor.modules[i] # Ele usa o módulo da posição atual do ciclo!
			if mod != null:
				current_cycle_actions.append({"actor": actor, "module": mod, "target": _get_target(actor, mod)})
				
		if i < enemy_actors.size():
			var actor = enemy_actors[i]
			var mod = actor.modules[i]
			if mod != null:
				current_cycle_actions.append({"actor": actor, "module": mod, "target": _get_target(actor, mod)})
				
	timeline_generated.emit(current_cycle_actions)

func _get_target(actor: Dictionary, mod: ModuleData):
	var team = ally_team if actor.is_ally else enemy_team
	var opposing = enemy_team if actor.is_ally else ally_team
	
	var my_index = team.find(actor)
	if my_index == -1: return null # Se não achou no array, ignora

	if mod.target_type == "SingleEnemy":
		return opposing[my_index] # Ataque Reto: Slot X ataca Slot X (pode ser null se estiver vazio!)
		
	elif mod.target_type == "Ally":
		var target_idx = (my_index + 1) % 4 # A Magia Modular: Slot X cura Slot X+1. Se for 3, vira 0!
		return team[target_idx] 
		
	elif mod.target_type == "Self":
		return actor
		
	return null

func execute_cycle() -> void:
	var base_wait: float = 1.0
	combat_log_added.emit("\n[color=yellow]--- NOVO CICLO INICIADO ---[/color]")

	for i in range(current_cycle_actions.size()):
		var action = current_cycle_actions[i]
		var actor = action.actor
		var mod = action.module
		var target = action.target
		
		if actor.hp > 0 and actor.stability >= mod.stability_cost:
			actor.stability -= mod.stability_cost
			combat_log_added.emit("[color=cyan]%s[/color] ativou [b]%s[/b]." % [actor.name, mod.module_name])
			
			# Aplica Buffs/Debuffs (Inclusive o Buff de DEF das habilidades de Suporte/Defesa!)
			for effect in mod.applied_effects:
				if effect != null:
					var new_eff = effect.duplicate()
					var target_to_apply = actor if new_eff.effect_type == "Buff" else target
					if target_to_apply != null:
						target_to_apply.active_effects.append(new_eff)
			
			if mod.module_type == "Attack":
				if target != null and target.hp > 0:
					var dynamic_atk = _get_stat(actor, mod.scaling_stat)
					var raw_damage = mod.power + ((dynamic_atk * mod.scaling_factor) if mod.scaling_stat != "NONE" else 0)
					
					# Calcula a DEF dinâmica do alvo (Respeitando os Buffs/Debuffs!)
					var target_def = _get_stat(target, "def")
					var final_damage = max(1, raw_damage - target_def) 
					
					target.hp = max(0, target.hp - final_damage)
					floating_text_requested.emit(target, "-" + str(final_damage), Color.CRIMSON)
					combat_log_added.emit("> Dano causado: " + str(final_damage))
				else:
					combat_log_added.emit("> O ataque de " + actor.name + " acertou o VAZIO!")
					floating_text_requested.emit(actor, "MISS!", Color.GRAY)
					
			action_executed.emit(i, action)
			stats_updated.emit()
			
		await get_tree().create_timer(base_wait).timeout 
		base_wait = max(0.15, base_wait * 0.70)

	_end_cycle_cleanup()

func _end_cycle_cleanup() -> void:
	for team in [ally_team, enemy_team]:
		for actor in team:
			if actor == null: continue # <--- ISTO AQUI PREVINE O CRASH!!!
			
			actor.stability = min(actor.max_stability, actor.stability + 20)
			
			var i = actor.active_effects.size() - 1
			while i >= 0:
				actor.active_effects[i].duration_cycles -= 1
				if actor.active_effects[i].duration_cycles <= 0:
					actor.active_effects.remove_at(i)
				i -= 1
				
	_desfragment_enemies() # Inimigos deslizam
	stats_updated.emit()
	_check_combat_state()
		
func _get_stat(actor: Dictionary, stat_name: String) -> int:
	var base_val: int = actor.get(stat_name.to_lower(), 0)
	var modifier: int = 0
	
	for effect in actor.active_effects:
		if effect.target_stat.to_lower() == stat_name.to_lower():
			if effect.effect_type == "Buff":
				modifier += effect.flat_value
			elif effect.effect_type == "Debuff":
				modifier -= effect.flat_value
				
	return max(0, base_val + modifier) # Garante que o status não fique negativo
	
func _check_combat_state() -> void:
	var all_enemies_dead = true
	for e in enemy_team:
		# Só verifica o HP se existir alguém neste slot!
		if e != null and e.hp > 0: 
			all_enemies_dead = false
			
	var all_allies_dead = true
	for a in ally_team:
		# Mesma proteção para os aliados
		if a != null and a.hp > 0: 
			all_allies_dead = false
			
	if all_enemies_dead:
		combat_log_added.emit("\n[color=lime]>>> VITÓRIA! Inimigos eliminados. <<<<[/color]")
		combat_victory.emit()
	elif all_allies_dead:
		combat_log_added.emit("\n[color=red]>>> DERROTA CRÍTICA! Sistema comprometido. <<<<[/color]")
		combat_defeat.emit()
	else:
		# Se a luta continua, reconstrói a timeline para o próximo turno e avisa a UI!
		_build_timeline()
		cycle_ended_ready_for_next.emit()

func _desfragment_enemies() -> void:
	var alive_enemies = []
	
	# 1. Pega todo mundo que ainda está vivo e arranca do Grid
	for e in enemy_team:
		if e != null and e.hp > 0:
			alive_enemies.append(e)
			
	# 2. Zera o Grid Inimigo
	enemy_team = [null, null, null, null]
	
	# 3. A Força da Gravidade do GDD (Índices: 1 é o Slot 2, 0 é o Slot 1...)
	var gravity_slots = [1, 0, 2, 3] 
	
	# 4. Reposiciona os sobreviventes na ordem de prioridade central!
	for i in range(alive_enemies.size()):
		var target_slot = gravity_slots[i]
		enemy_team[target_slot] = alive_enemies[i]

func _get_timeline_actors(team: Array) -> Array:
	var alive = []
	var main_actor = null
	
	# 1. Identifica o "Rei" (Quem está no Slot Principal - Índice 1 / Slot 2)
	if team[1] != null and team[1].hp > 0:
		main_actor = team[1]
		
	# 2. Identifica os "Súditos" (Os outros vivos, varrendo da esquerda pra direita)
	for i in range(4):
		if team[i] != null and team[i].hp > 0 and team[i] != main_actor:
			alive.append(team[i])
			
	# 3. Proteção: Se o Slot Principal estiver vazio (morto ou sem ninguém), 
	# o primeiro súdito vivo assume o manto de Rei.
	if main_actor == null and alive.size() > 0:
		main_actor = alive[0]
		alive.remove_at(0)
		
	# 4. A Nova Repartição da Timeline (GDD Atualizado)
	var total_chars = alive.size() + (1 if main_actor != null else 0)
	
	if total_chars == 0: return []
	
	if total_chars == 1: 
		return [main_actor, main_actor, main_actor, main_actor]
		
	if total_chars == 2:
		# Rei ganha Ação 1 e 2. Súdito ganha Ação 3 e 4.
		return [main_actor, main_actor, alive[0], alive[0]]
		
	if total_chars == 3:
		# Rei ganha Ação 1 e 2. Súdito A ganha Ação 3, Súdito B ganha Ação 4.
		return [main_actor, main_actor, alive[0], alive[1]]
		
	if total_chars == 4:
		# O Rei abre o combate na Ação 1, os súditos seguem a fila nas Ações 2, 3 e 4.
		return [main_actor, alive[0], alive[1], alive[2]]
		
	return []
