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
@export var power: int = 10
@export var stability_cost: int = 10
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

@export_category("Scaling & Effects")
@export var scaling_stat: ScalingStat = ScalingStat.ATK
@export var scaling_factor: float = 1.0
@export var applied_effects: Array[StatusEffect] = []

@export_category("Combat Effects")
@export var combat_effects: Array[CombatEffectData] = []