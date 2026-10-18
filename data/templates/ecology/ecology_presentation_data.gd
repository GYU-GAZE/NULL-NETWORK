@tool
extends Resource
class_name EcologyPresentationData

## These thresholds are CONTENT decisions, not canonical universal numbers.
@export_range(0.0, 1.0) var healthy_ratio: float = 0.9
@export_range(0.0, 1.0) var stable_ratio: float = 0.65
@export_range(0.0, 1.0) var declining_ratio: float = 0.35
@export var healthy_text: String = "HEALTHY"
@export var stable_text: String = "STABLE"
@export var declining_text: String = "DECLINING"
@export var critical_text: String = "CRITICAL"
@export var last_signature_text: String = "LAST ACTIVE EXE SIGNATURE"
@export var collapsed_text: String = "ECOLOGICALLY COLLAPSED"
@export var absent_text: String = "LOCALLY ABSENT"
@export_multiline var collapse_warning: String = "LAST ACTIVE EXE SIGNATURE\nThis PURGE will permanently collapse this zone.\nLocal regeneration and ordinary migration will become impossible.\nThe weekly Micro-Update cannot reverse this consequence."
@export var purge_feedback: String = "EXE SIGNAL DELETED // LOCAL PRESENCE REDUCED"
@export var purify_feedback: String = "SIGNATURE STABILIZED // RESONANCE INCREASED"
@export var weekly_feedback: String = "MICRO-UPDATE // ECOLOGICAL RECOMPILATION"
@export var predator_feedback: String = "NULL SIGNATURE COMPILED // OPERATOR IDENTIFIED"
@export var collapsed_tint: Color = Color(0.28, 0.2, 0.35, 1)
