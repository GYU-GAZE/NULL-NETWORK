@tool
extends Resource
class_name EcologyZoneData

@export var ecology_zone_id: String = ""
@export var display_name: String = ""
@export var location_ids: PackedStringArray = PackedStringArray()
@export_range(1, 100000) var population_capacity: int = 8
@export var conditions: ConditionRuleData
@export var species: Array[EcologySpeciesData] = []
@export var danger_number_key: String = ""
## Micro-Update uses the existing calendar. Monday=1, not a second clock.
@export_range(0, 6) var micro_update_weekday: int = 1
@export var migrations: Array[EcologyMigrationData] = []
@export var npc_activities: Array[EcologyNPCActivityData] = []
@export_range(0.0, 1.0) var resonance_presence_bonus: float = 0.1
@export var presentation: EcologyPresentationData
@export var predator: EcologyPredatorData

func get_species(id: String) -> EcologySpeciesData:
	for definition: EcologySpeciesData in species:
		if definition != null and definition.species_line_id == id: return definition
	return null

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if ecology_zone_id.is_empty() or location_ids.is_empty() or presentation == null:
		errors.append("Ecological zone requires identity, locations and presentation.")
	var ids := {}
	var base := 0
	for definition: EcologySpeciesData in species:
		if definition == null: errors.append("Null ecological species.")
		else:
			errors.append_array(definition.validate_data())
			if ids.has(definition.species_line_id): errors.append("Duplicate ecological species.")
			ids[definition.species_line_id] = true
			base += definition.population_base
			for variant: EcologyVariantData in definition.variants:
				if variant != null and not variant.zone_ids.is_empty() and ecology_zone_id not in variant.zone_ids: errors.append("Variant pool incompatible with zone.")
	if base > population_capacity: errors.append("Zone base population exceeds its capacity.")
	if predator != null: errors.append_array(predator.validate_data())
	return errors
