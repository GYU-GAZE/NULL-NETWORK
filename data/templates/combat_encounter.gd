extends Resource
class_name CombatEncounter

@export var encounter_id: String = ""
@export var encounter_name: String = "Novo Encontro"

@export_category("Slot Layout")
@export var ally_slots: Array[CombatSlotData] = []
@export var enemy_slots: Array[CombatSlotData] = []