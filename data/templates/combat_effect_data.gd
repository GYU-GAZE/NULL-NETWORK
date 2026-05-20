extends Resource
class_name CombatEffectData

enum EffectType {
	DAMAGE,
	APPLY_STATUS,
	SPAWN_DUMMY,
	REDIRECT_NEXT_ATTACK
}

enum SpawnSlotRule {
	FIRST_EMPTY,
	LEFTMOST_EMPTY,
	RIGHTMOST_EMPTY,
	SAME_SLOT_AS_USER
}

@export var effect_type: EffectType = EffectType.DAMAGE

@export_category("Damage")
@export var power: int = 10
@export var scaling_stat: ModuleData.ScalingStat = ModuleData.ScalingStat.ATK
@export var scaling_factor: float = 1.0

@export_category("Status")
@export var status_effect: StatusEffect

@export_category("Dummy")
@export var dummy_loadout: CharacterLoadout
@export var spawn_slot_rule: SpawnSlotRule = SpawnSlotRule.FIRST_EMPTY

@export_category("Redirect")
@export var redirect_duration_actions: int = 1