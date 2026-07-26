extends Resource
class_name CombatTargetSelector


enum TargetKind {
	USER,
	DIRECT_ENEMY,
	ALL_ENEMIES,
	ENEMY_SLOT,
	ADJACENT_ALLY,
	ALL_ALLIES,
	ALLY_SLOT,
	EVENT_SOURCE,
	EVENT_TARGET,
	STATUS_HOLDER,
	DUMMY_CREATOR
}


@export var target_kind: TargetKind = TargetKind.DIRECT_ENEMY
@export_range(0, 3) var slot_index: int = 0
@export var include_defeated: bool = false
@export var fallback_to_closest: bool = true


func describe() -> String:
	match target_kind:
		TargetKind.USER:
			return "user"
		TargetKind.DIRECT_ENEMY:
			return "enemy directly ahead"
		TargetKind.ALL_ENEMIES:
			return "all enemies"
		TargetKind.ENEMY_SLOT:
			return "enemy slot %d" % (slot_index + 1)
		TargetKind.ADJACENT_ALLY:
			return "adjacent ally"
		TargetKind.ALL_ALLIES:
			return "all allies"
		TargetKind.ALLY_SLOT:
			return "ally slot %d" % (slot_index + 1)
		TargetKind.EVENT_SOURCE:
			return "event source"
		TargetKind.EVENT_TARGET:
			return "event target"
		TargetKind.STATUS_HOLDER:
			return "status holder"
		TargetKind.DUMMY_CREATOR:
			return "dummy creator"

	return "target"
