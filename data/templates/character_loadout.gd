extends Resource
class_name CharacterLoadout

@export var char_name: String = "Entidade"
@export var combat_icon: Texture2D # A NOVA IMAGEM!
@export var level: int = 1
@export_enum("INIT", "VALOUR", "LOGIC", "SYNC", "SELF", "BALANCED", "null", "XVALOUR", "XLOGIC", "XSYNC", "XSELF") var apk_type: String = "INIT"
@export var max_hp: int = 100
@export var max_stability: int = 100

@export_category("Core Stats")
@export var base_atk: int = 10
@export var base_def: int = 5
@export var dodge_chance: float = 0.05

@export_category("Loadout")
@export var equipped_modules: Array[ModuleData] = [null, null, null, null]
@export var module_pool: Array[ModuleData] = []
