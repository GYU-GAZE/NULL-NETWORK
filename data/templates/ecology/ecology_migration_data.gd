@tool
extends Resource
class_name EcologyMigrationData

@export var migration_id: String = ""
@export var source_zone_id: String = ""
@export var species_line_id: String = ""
@export_range(0, 1000) var maximum_units: int = 1
@export_range(1, 1000) var leave_in_source: int = 1
@export var conditions: ConditionRuleData
