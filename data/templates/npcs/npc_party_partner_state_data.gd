extends Resource
class_name NPCPartyPartnerStateData


const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 100
const MAX_STABILITY: int = 100

var npc_id: String = ""
var character_id: String = ""
var level: int = MIN_LEVEL
var current_exp: int = 0
var current_hp: int = 1
var current_stability: int = MAX_STABILITY
var lost: bool = false
var lost_action_index: int = -1
var lost_encounter_id: String = ""


func initialize_from_loadout(
	owner_npc_id: String,
	loadout: CharacterLoadout
) -> bool:
	var clean_npc_id: String = owner_npc_id.strip_edges()

	if clean_npc_id.is_empty() or loadout == null:
		return false

	var clean_character_id: String = str(loadout.character_id).strip_edges()

	if clean_character_id.is_empty():
		return false

	npc_id = clean_npc_id
	character_id = clean_character_id
	level = clampi(loadout.level, MIN_LEVEL, MAX_LEVEL)
	current_exp = APKProgressionService.get_total_exp_for_level(level)
	current_hp = clampi(
		loadout.starting_hp if loadout.starting_hp >= 0 else loadout.max_hp,
		0,
		maxi(1, loadout.max_hp)
	)
	current_stability = clampi(
		loadout.starting_stability
		if loadout.starting_stability >= 0
		else loadout.max_stability,
		0,
		maxi(1, loadout.max_stability)
	)
	lost = current_hp <= 0
	lost_action_index = -1
	lost_encounter_id = ""
	return true


func is_alive() -> bool:
	return not lost and current_hp > 0


func is_compatible_with(
	owner_npc_id: String,
	loadout: CharacterLoadout
) -> bool:
	if loadout == null:
		return false

	return (
		npc_id == owner_npc_id.strip_edges()
		and character_id == str(loadout.character_id).strip_edges()
	)


func grant_experience(amount: int) -> Dictionary:
	var result := {
		"granted": 0,
		"old_level": level,
		"new_level": level
	}

	if amount <= 0 or not is_alive() or level >= MAX_LEVEL:
		return result

	current_exp += amount
	result["granted"] = amount

	while level < MAX_LEVEL:
		var next_level: int = level + 1

		if current_exp < APKProgressionService.get_total_exp_for_level(next_level):
			break

		level = next_level

	if level >= MAX_LEVEL:
		current_exp = APKProgressionService.get_total_exp_for_level(MAX_LEVEL)

	result["new_level"] = level
	return result


func update_combat_vitals(
	hp: int,
	stability: int,
	maximum_hp: int,
	maximum_stability: int
) -> void:
	if lost:
		return

	current_hp = clampi(hp, 0, maxi(1, maximum_hp))
	current_stability = clampi(
		stability,
		0,
		maxi(1, maximum_stability)
	)


func mark_lost(
	encounter_id: String,
	action_index: int
) -> bool:
	if lost:
		return false

	lost = true
	current_hp = 0
	lost_action_index = maxi(0, action_index)
	lost_encounter_id = encounter_id.strip_edges()
	return true


func duplicate_state() -> NPCPartyPartnerStateData:
	var copy := NPCPartyPartnerStateData.new()
	copy.load_save_data(to_save_data())
	return copy


func to_save_data() -> Dictionary:
	return {
		"npc_id": npc_id,
		"character_id": character_id,
		"level": level,
		"current_exp": current_exp,
		"current_hp": current_hp,
		"current_stability": current_stability,
		"lost": lost,
		"lost_action_index": lost_action_index,
		"lost_encounter_id": lost_encounter_id
	}


func load_save_data(data: Dictionary) -> void:
	npc_id = str(data.get("npc_id", "")).strip_edges()
	character_id = str(data.get("character_id", "")).strip_edges()
	level = clampi(int(data.get("level", MIN_LEVEL)), MIN_LEVEL, MAX_LEVEL)
	current_exp = maxi(0, int(data.get("current_exp", 0)))
	current_hp = maxi(0, int(data.get("current_hp", 1)))
	current_stability = clampi(
		int(data.get("current_stability", MAX_STABILITY)),
		0,
		MAX_STABILITY
	)
	lost = bool(data.get("lost", false))
	lost_action_index = int(data.get("lost_action_index", -1))
	lost_encounter_id = str(data.get("lost_encounter_id", "")).strip_edges()

	if lost:
		current_hp = 0


func validate_state() -> PackedStringArray:
	var errors := PackedStringArray()

	if npc_id.strip_edges().is_empty():
		errors.append("NPC party partner state requires npc_id.")

	if character_id.strip_edges().is_empty():
		errors.append("NPC party partner state requires character_id.")

	if level < MIN_LEVEL or level > MAX_LEVEL:
		errors.append("NPC party partner level must remain between 1 and 100.")

	if current_exp < 0:
		errors.append("NPC party partner EXP cannot be negative.")

	if current_hp < 0:
		errors.append("NPC party partner HP cannot be negative.")

	if current_stability < 0 or current_stability > MAX_STABILITY:
		errors.append("NPC party partner Stability must remain between 0 and 100.")

	if lost and current_hp != 0:
		errors.append("A lost NPC party partner must remain at 0 HP.")

	var minimum_exp: int = APKProgressionService.get_total_exp_for_level(level)
	var next_exp: int = APKProgressionService.get_total_exp_for_level(
		mini(MAX_LEVEL, level + 1)
	)

	if current_exp < minimum_exp \
		or (level < MAX_LEVEL and current_exp >= next_exp):
		errors.append("NPC party partner EXP is inconsistent with its level.")

	return errors
