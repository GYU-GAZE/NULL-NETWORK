extends Resource
class_name ModuleData

enum ModuleType {
	ATTACK,
	SUPPORT,
	DEFEND
}

enum TargetType {
	SELF,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	ALLY,
	ALL_ALLIES
}

enum ScalingStat {
	ATK,
	DEF,
	MAX_HP,
	NONE
}

@export var module_name: String = "Novo Módulo"
@export var module_icon: Texture2D
@export_multiline var description: String = "Descrição do módulo aqui."

@export_category("Core")
@export var module_type: ModuleType = ModuleType.ATTACK
@export var stability_cost: int = 10
@export_range(0.0, 1.0, 0.01) var accuracy: float = 1.0
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

@export_category("Combat Effects")
@export var combat_effects: Array[CombatEffectData] = []