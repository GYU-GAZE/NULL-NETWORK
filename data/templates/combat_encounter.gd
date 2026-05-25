extends Resource
class_name CombatEncounter

@export var encounter_id: String = ""
@export var encounter_name: String = "Novo Encontro"

@export_category("Slot Layout")
@export var ally_slots: Array[CombatSlotData] = []
@export var enemy_slots: Array[CombatSlotData] = []

@export_category("Legacy Compatibility")
@export var allies: Array[CharacterLoadout] = []
@export var enemies: Array[CharacterLoadout] = []


func uses_slot_layout() -> bool:
	return not ally_slots.is_empty() or not enemy_slots.is_empty()