@tool
extends Resource
class_name EcologyPredatorData

@export var predator_id: String = "null.predator"
@export var apk_id: String = ""
@export_range(1, 100) var level: int = 2
@export var encounter_profile: FieldEncounterProfileData
@export var behavior_profile: FieldBehaviorProfileData
@export var stages: Array[EcologyPredatorStageData] = []
@export var display_name: String = "NULL PREDATOR // PROVISIONAL VISUAL"

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if predator_id.is_empty() or apk_id.is_empty() or encounter_profile == null or behavior_profile == null:
		errors.append("Predator requires stable identity, catalog APK and existing field contracts.")
	return errors
