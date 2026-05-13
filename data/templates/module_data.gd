extends Resource
class_name ModuleData

@export var module_name: String = "Novo Módulo"
@export var module_icon: Texture2D
@export_multiline var description: String = "Descrição do módulo aqui."
@export_enum("Attack", "Support", "Defend") var module_type: String = "Attack"
@export var power: int = 10
@export var stability_cost: int = 10
@export_enum("Self", "SingleEnemy", "AllEnemies", "Ally", "AllAllies") var target_type: String = "SingleEnemy"

@export_category("Scaling & Effects")
@export_enum("ATK", "DEF", "MAX_HP", "NONE") var scaling_stat: String = "ATK"
@export var scaling_factor: float = 1.0
@export var applied_effects: Array[StatusEffect] = []
