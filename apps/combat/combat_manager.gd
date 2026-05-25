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
		"atk": data.base_atk,
		"def": data.base_def,
		"dodge": data.dodge_chance,
		"crit": data.crit_chance,
		"modules": data.equipped_modules.duplicate(),
		"is_ally": is_ally,
		"is_player": is_player,
		"combat_behavior": data.combat_behavior,
		"is_dummy": data.combat_behavior == CharacterLoadout.CombatBehavior.DUMMY,
		"active_effects": [],
		"active_combat_effects": []
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
	if my_index == -1:
		return null

	match mod.target_type:
		ModuleData.TargetType.SINGLE_ENEMY:
			return _get_single_enemy_target(my_index, opposing)

		ModuleData.TargetType.ALL_ENEMIES:
			return _get_alive_targets(opposing)

		ModuleData.TargetType.ALLY:
			return _get_ally_target(my_index, team)

		ModuleData.TargetType.ALL_ALLIES:
			return _get_alive_targets(team)

		ModuleData.TargetType.SELF:
			return actor

	return null

func _get_single_enemy_target(attacker_index: int, opposing_team: Array):
	var alive_targets := _get_alive_targets(opposing_team)

	if alive_targets.is_empty():
		return null

	if alive_targets.size() == 1:
		return alive_targets[0]

	if alive_targets.size() == 2:
		if attacker_index <= 1:
			return alive_targets[0]
		else:
			return alive_targets[1]

	if alive_targets.size() == 3:
		return _get_closest_target_by_slot(attacker_index, opposing_team)

	return opposing_team[attacker_index]


func _get_closest_target_by_slot(attacker_index: int, opposing_team: Array):
	var closest_target = null
	var closest_distance := 999

	for i in range(opposing_team.size()):
		var target = opposing_team[i]

		if target == null or target.hp <= 0:
			continue

		var distance = abs(attacker_index - i)

		if distance < closest_distance:
			closest_distance = distance
			closest_target = target

	return closest_target


func _get_ally_target(actor_index: int, team: Array):
	var target_idx = (actor_index + 1) % 4
	var target = team[target_idx]

	if target != null and target.hp > 0:
		return target

	return _get_closest_target_by_slot(actor_index, team)


func _get_alive_targets(team: Array) -> Array:
	var alive_targets := []

	for actor in team:
		if actor != null and actor.hp > 0:
			alive_targets.append(actor)

	return alive_targets

func execute_cycle() -> void:
	var base_wait: float = 1.0
	combat_log_added.emit("\n[color=yellow]--- NOVO CICLO INICIADO ---[/color]")

	for i in range(current_cycle_actions.size()):
		var action = current_cycle_actions[i]
		var actor = action.actor
		var mod = action.module
		var target = action.target
		target = _get_target(actor, mod)
		action.target = target

		if actor.hp > 0 and actor.stability >= mod.stability_cost:
			actor.stability -= mod.stability_cost
			actor.stability = max(0, actor.stability)

			if actor.stability <= 0:
				_apply_unstability(actor)
				
			combat_log_added.emit("[color=cyan]%s[/color] ativou [b]%s[/b]." % [actor.name, mod.module_name])

			if mod.combat_effects.is_empty():
				_fail_combat_effect(actor, "Module sem CombatEffectData configurado.")
			else:
				_apply_combat_effects(actor, mod, target)

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
		var effect_stat := _target_stat_to_string(effect.target_stat)

		if effect_stat == stat_name.to_lower():
			match effect.effect_type:
				StatusEffect.EffectType.BUFF:
					modifier += effect.flat_value

				StatusEffect.EffectType.DEBUFF:
					modifier -= effect.flat_value

	return max(0, base_val + modifier)
	
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
	if team[1] != null and team[1].hp > 0 and not team[1].is_dummy:
		main_actor = team[1]
		
	# 2. Identifica os "Súditos" (Os outros vivos, varrendo da esquerda pra direita)
	for i in range(4):
		if team[i] != null and team[i].hp > 0 and team[i] != main_actor and not team[i].is_dummy:
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

func _scaling_stat_to_string(scaling_stat: ModuleData.ScalingStat) -> String:
	match scaling_stat:
		ModuleData.ScalingStat.ATK:
			return "atk"

		ModuleData.ScalingStat.DEF:
			return "def"

		ModuleData.ScalingStat.MAX_HP:
			return "max_hp"

		ModuleData.ScalingStat.NONE:
			return "none"

	return "none"

func _target_stat_to_string(target_stat: StatusEffect.TargetStat) -> String:
	match target_stat:
		StatusEffect.TargetStat.ATK:
			return "atk"

		StatusEffect.TargetStat.DEF:
			return "def"

		StatusEffect.TargetStat.DODGE:
			return "dodge"

		StatusEffect.TargetStat.STABILITY:
			return "stability"

	return ""


func _apply_combat_effects(actor: Dictionary, mod: ModuleData, target) -> void:
	for effect in mod.combat_effects:
		if effect == null:
			continue

		match effect.effect_type:
			CombatEffectData.EffectType.DAMAGE:
				_apply_damage(
					actor,
					effect.power,
					effect.scaling_stat,
					effect.scaling_factor,
					target,
					mod.accuracy,
					effect.can_crit,
					effect.crit_multiplier,
					effect.applies_unstability_on_crit
				)

			CombatEffectData.EffectType.APPLY_STATUS:
				var status_crit := false

				if effect.can_crit and _roll_crit(actor):
					status_crit = true

					if effect.applies_unstability_on_crit:
						_apply_unstability(target)

				_apply_status_effect(actor, target, effect.status_effect, status_crit)

				if status_crit:
					combat_log_added.emit("> CRITICAL STATUS!")

			CombatEffectData.EffectType.SPAWN_DUMMY:
				_spawn_dummy(actor, effect)

			CombatEffectData.EffectType.REDIRECT_NEXT_ATTACK:
				_apply_redirect_next_attack(actor, target, effect)


func _apply_damage(
	actor: Dictionary,
	power: int,
	scaling_stat: ModuleData.ScalingStat,
	scaling_factor: float,
	target,
	accuracy: float = 1.0,
	can_crit: bool = true,
	crit_multiplier: float = 3.0,
	applies_unstability_on_crit: bool = true
) -> void:
	target = _resolve_redirect_target(target)

	if target == null:
		combat_log_added.emit("> O ataque de " + actor.name + " acertou o VAZIO!")
		floating_text_requested.emit(actor, "MISS!", Color.GRAY)
		return

	if target is Array:
		for single_target in target:
			_apply_damage(
				actor,
				power,
				scaling_stat,
				scaling_factor,
				single_target,
				accuracy,
				can_crit,
				crit_multiplier,
				applies_unstability_on_crit
			)
		return

	if target.hp <= 0:
		return

	if not _roll_accuracy(actor, target, accuracy):
		combat_log_added.emit("> " + actor.name + " errou o ataque contra " + target.name + ".")
		floating_text_requested.emit(target, "MISS!", Color.GRAY)
		return

	var scaling_stat_name := _scaling_stat_to_string(scaling_stat)
	var dynamic_atk := _get_stat(actor, scaling_stat_name)

	var raw_damage = power

	if scaling_stat != ModuleData.ScalingStat.NONE:
		raw_damage += dynamic_atk * scaling_factor

	var target_def = _get_stat(target, "def")
	var final_damage = max(1, raw_damage - target_def)

	final_damage = _apply_damage_dealt_modifiers(actor, final_damage)
	final_damage = _apply_damage_taken_modifiers(target, final_damage)

	var did_crit := false

	if can_crit and _roll_crit(actor):
		did_crit = true
		final_damage = int(final_damage * crit_multiplier)

		if applies_unstability_on_crit:
			_apply_unstability(target)

	target.hp = max(0, target.hp - final_damage)

	if did_crit:
		floating_text_requested.emit(target, "CRIT! -" + str(final_damage), Color.ORANGE_RED)
		combat_log_added.emit("> CRITICAL HIT! Dano causado: " + str(final_damage))
	else:
		floating_text_requested.emit(target, "-" + str(final_damage), Color.CRIMSON)
		combat_log_added.emit("> Dano causado: " + str(final_damage))

	if target.hp <= 0:
		_remove_defeated_actor_from_grid(target)


func _apply_status_effect(actor: Dictionary, target, status_effect: StatusEffect, force_crit: bool = false) -> void:
	if status_effect == null:
		return

	if target == null:
		return

	if target is Array:
		for single_target in target:
			_apply_status_effect(actor, single_target, status_effect, force_crit)
		return

	var new_eff := status_effect.duplicate()

	if force_crit:
		new_eff.flat_value *= 3

	var target_to_apply = actor if new_eff.effect_type == StatusEffect.EffectType.BUFF else target

	if target_to_apply != null:
		target_to_apply.active_effects.append(new_eff)
		combat_log_added.emit("> Status aplicado: " + new_eff.effect_name)


func _spawn_dummy(actor: Dictionary, effect: CombatEffectData) -> void:
	if effect.dummy_loadout == null:
		_fail_combat_effect(actor, "Dummy inválido: nenhum loadout configurado.")
		return

	var team = ally_team if actor.is_ally else enemy_team
	var spawn_index := _find_dummy_spawn_slot(actor, team, effect.spawn_slot_rule)

	if spawn_index == -1:
		_fail_combat_effect(actor, "Não há slot livre para spawnar dummy.")
		return

	var dummy := _create_combatant_dict(effect.dummy_loadout, actor.is_ally, false)
	dummy.is_dummy = true

	team[spawn_index] = dummy

	combat_log_added.emit("> Dummy criado no slot " + str(spawn_index + 1) + ": " + dummy.name)
	stats_updated.emit()


func _find_dummy_spawn_slot(actor: Dictionary, team: Array, rule: CombatEffectData.SpawnSlotRule) -> int:
	match rule:
		CombatEffectData.SpawnSlotRule.FIRST_EMPTY:
			for i in range(team.size()):
				if team[i] == null:
					return i

		CombatEffectData.SpawnSlotRule.LEFTMOST_EMPTY:
			for i in range(team.size()):
				if team[i] == null:
					return i

		CombatEffectData.SpawnSlotRule.RIGHTMOST_EMPTY:
			for i in range(team.size() - 1, -1, -1):
				if team[i] == null:
					return i

		CombatEffectData.SpawnSlotRule.SAME_SLOT_AS_USER:
			var actor_index = team.find(actor)

			if actor_index != -1 and team[actor_index] == null:
				return actor_index

			for i in range(team.size()):
				if team[i] == null:
					return i

	return -1


func _apply_redirect_next_attack(actor: Dictionary, target, effect: CombatEffectData) -> void:
	if target == null:
		return

	if target is Array:
		return

	target.active_combat_effects.append({
		"type": "redirect_next_attack",
		"redirect_to_uid": actor.uid,
		"remaining_actions": effect.redirect_duration_actions
	})

	combat_log_added.emit("> " + target.name + " agora redireciona o próximo ataque para " + actor.name)


func _resolve_redirect_target(original_target):
	if original_target == null:
		return null

	if original_target is Array:
		return original_target

	if not original_target.has("active_combat_effects"):
		return original_target

	for i in range(original_target.active_combat_effects.size() - 1, -1, -1):
		var effect = original_target.active_combat_effects[i]

		if effect.get("type", "") != "redirect_next_attack":
			continue

		var redirect_uid = effect.get("redirect_to_uid", -1)
		var redirect_target = _find_combatant_by_uid(redirect_uid)

		original_target.active_combat_effects.remove_at(i)

		if redirect_target != null and redirect_target.hp > 0:
			combat_log_added.emit("> Ataque redirecionado para " + redirect_target.name)
			return redirect_target

	return original_target


func _find_combatant_by_uid(uid: int):
	for team in [ally_team, enemy_team]:
		for actor in team:
			if actor != null and actor.uid == uid:
				return actor

	return null

func _remove_defeated_actor_from_grid(actor: Dictionary) -> void:
	for i in range(ally_team.size()):
		if ally_team[i] == actor:
			ally_team[i] = null
			stats_updated.emit()
			return

	for i in range(enemy_team.size()):
		if enemy_team[i] == actor:
			enemy_team[i] = null
			stats_updated.emit()
			return

func _fail_combat_effect(actor: Dictionary, message: String) -> void:
	combat_log_added.emit("> FALHA: " + message)
	floating_text_requested.emit(actor, "FAIL!", Color.GRAY)

func _roll_accuracy(actor: Dictionary, target: Dictionary, accuracy: float) -> bool:
	var clamped_accuracy = clamp(accuracy, 0.0, 1.0)
	var target_dodge = clamp(_get_stat(target, "dodge"), 0.0, 1.0)

	var final_hit_chance = clamp(clamped_accuracy - (target_dodge * 0.5), 0.05, 1.0)

	return randf() <= final_hit_chance

func _roll_crit(actor: Dictionary) -> bool:
	var crit_chance = clamp(_get_stat(actor, "crit"), 0.0, 1.0)
	return randf() <= crit_chance

func _apply_unstability(target) -> void:
	if target == null:
		return

	if target is Array:
		for single_target in target:
			_apply_unstability(single_target)
		return

	if _has_status_effect(target, "UNSTABILITY"):
		return

	var unstable_effect := StatusEffect.new()
	unstable_effect.effect_name = "UNSTABILITY"
	unstable_effect.effect_type = StatusEffect.EffectType.SPECIAL
	unstable_effect.target_stat = StatusEffect.TargetStat.NONE
	unstable_effect.trigger_timing = StatusEffect.TriggerTiming.ON_TAKE_DAMAGE
	unstable_effect.damage_taken_multiplier = 2.0
	unstable_effect.duration_cycles = 1
	unstable_effect.remove_after_trigger = true

	target.active_effects.append(unstable_effect)

	combat_log_added.emit("> " + target.name + " entrou em UNSTABILITY!")
	floating_text_requested.emit(target, "UNSTABLE!", Color.MEDIUM_PURPLE)


func _has_status_effect(actor: Dictionary, effect_name: String) -> bool:
	for effect in actor.active_effects:
		if effect.effect_name == effect_name:
			return true

	return false


func _apply_damage_taken_modifiers(target: Dictionary, damage: int) -> int:
	var final_damage := damage

	for i in range(target.active_effects.size() - 1, -1, -1):
		var effect = target.active_effects[i]

		if effect.trigger_timing != StatusEffect.TriggerTiming.ON_TAKE_DAMAGE:
			continue

		if effect.damage_taken_multiplier != 1.0:
			final_damage = int(final_damage * effect.damage_taken_multiplier)
			combat_log_added.emit("> " + effect.effect_name + " modificou o dano recebido.")

		if effect.remove_after_trigger:
			target.active_effects.remove_at(i)

	return max(1, final_damage)


func _apply_damage_dealt_modifiers(actor: Dictionary, damage: int) -> int:
	var final_damage := damage

	for i in range(actor.active_effects.size() - 1, -1, -1):
		var effect = actor.active_effects[i]

		if effect.trigger_timing != StatusEffect.TriggerTiming.ON_DEAL_DAMAGE:
			continue

		if effect.damage_dealt_multiplier != 1.0:
			final_damage = int(final_damage * effect.damage_dealt_multiplier)
			combat_log_added.emit("> " + effect.effect_name + " modificou o dano causado.")

		if effect.remove_after_trigger:
			actor.active_effects.remove_at(i)

	return max(1, final_damage)