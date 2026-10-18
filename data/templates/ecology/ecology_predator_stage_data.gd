@tool
extends Resource
class_name EcologyPredatorStageData

@export_range(1, 1000) var minimum_collapses: int = 1
@export var active_module_ids: PackedStringArray = PackedStringArray()
@export var passive_module_id: String = ""
## Explicit opt-in content: assimilation reuses existing Modules, never TBD Node stats.
@export var assimilate_destroyed_modules: bool = false
@export var unresolved_design_notes: String = ""
