@tool
extends Resource
class_name EcologyNPCActivityData

enum Operation { PURGE, PURIFY, CONTAIN_SWARM, WORLD_PRESSURE }
@export var activity_id: String = ""
@export var npc_id: String = ""
@export var species_line_id: String = ""
@export var operation: Operation = Operation.PURIFY
@export_range(1, 168) var interval_blocks: int = 168
@export var conditions: ConditionRuleData
@export var infestation_delta: int = 0
@export var danger_delta: int = 0
