@tool
extends Resource
class_name SpawnTable

enum RefreshPolicy { PERIOD, DAY, ACTION_BLOCK, CAMPAIGN }
@export var refresh_policy: RefreshPolicy = RefreshPolicy.PERIOD
@export var table_id: String = ""
@export_range(0, 16, 1, "or_greater")
var rolls_per_population: int = 1
@export var entries: Array[SpawnEntry] = []
## Lookup-only migration content; never rolled as ambient population.
@export var retired_entries: Array[SpawnEntry] = []
@export var field_population: FieldPopulationData


func get_display_id() -> String:
	return table_id.strip_edges()


func get_entry(spawn_id: String) -> SpawnEntry:
	var clean_id: String = spawn_id.strip_edges()

	for entry: SpawnEntry in entries + retired_entries:
		if entry != null and entry.get_display_id() == clean_id:
			return entry

	return null


func get_available_entries(context: Dictionary = {}) -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []

	for entry: SpawnEntry in entries:
		if entry != null \
			and (entry.encounter != null or entry.environmental_apk != null) \
			and entry.weight > 0 \
			and entry.is_available(context):
			result.append(entry)

	return result


func roll_entries(
	seed_value: int,
	context: Dictionary = {}
) -> Array[SpawnEntry]:
	var result: Array[SpawnEntry] = []
	var available: Array[SpawnEntry] = get_available_entries(context)
	var desired := rolls_per_population
	if field_population != null:
		if field_population.conditions != null and not field_population.conditions.is_met(context): return result
		desired = clampi(desired, field_population.minimum_units, field_population.maximum_units)
	var used := {}
	if field_population != null:
		for id: String in field_population.guaranteed_spawn_ids:
			var entry := get_entry(id)
			if entry != null and entry in available and result.size() < desired and _ecology_allows(entry, used, context):
				result.append(entry)
				_count_species(entry, used)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	while result.size() < desired and rolls_per_population > 0:
		var eligible: Array[SpawnEntry] = []
		for entry: SpawnEntry in available:
			if _ecology_allows(entry, used, context): eligible.append(entry)
		if eligible.is_empty(): break
		var selected := _roll_one(eligible, rng, context)
		if selected == null: break
		result.append(selected)
		_count_species(selected, used)
	return result

func _count_species(entry: SpawnEntry, used: Dictionary) -> void:
	if entry.environmental_apk != null:
		var id := entry.environmental_apk.species_line_id
		used[id] = int(used.get(id, 0)) + 1

func _ecology_allows(entry: SpawnEntry, used: Dictionary, context: Dictionary) -> bool:
	if entry.environmental_apk == null or not context.has("ecology_limits"): return true
	var id := entry.environmental_apk.species_line_id
	return int(used.get(id, 0)) < int(context.ecology_limits.get(id, 0))



func roll_encounter() -> CombatEncounter:
	var rolled: Array[SpawnEntry] = roll_entries(randi())

	if rolled.is_empty():
		return null

	return rolled[0].encounter


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if field_population != null:
		errors.append_array(field_population.validate_data())
		for id: String in field_population.guaranteed_spawn_ids:
			if get_entry(id) == null:
				errors.append("Guaranteed field spawn ID is not in this table: " + id)
	var spawn_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("table_id cannot be empty.")

	var all_entries: Array[SpawnEntry] = entries + retired_entries
	for index: int in range(all_entries.size()):
		var entry: SpawnEntry = all_entries[index]

		if entry == null:
			errors.append("Entry %d is null." % index)
			continue

		var spawn_id: String = entry.get_display_id()

		if spawn_ids.has(spawn_id):
			errors.append("Duplicate spawn_id '%s'." % spawn_id)
		else:
			spawn_ids[spawn_id] = true

		for error: String in entry.validate_data():
			errors.append("Entry %d: %s" % [index, error])

	return errors


func _roll_one(available: Array[SpawnEntry], rng: RandomNumberGenerator, context: Dictionary = {}) -> SpawnEntry:
	var total_weight := 0.0
	for entry: SpawnEntry in available: total_weight += _weight(entry, context)
	if total_weight <= 0: return null
	var roll := rng.randf() * total_weight
	for entry: SpawnEntry in available:
		roll -= _weight(entry, context)
		if roll < 0: return entry
	return available.back()

func _weight(entry: SpawnEntry, context: Dictionary) -> float:
	var factor := 1.0
	if entry.environmental_apk != null and context.has("ecology_weights"):
		factor = float(context.ecology_weights.get(entry.environmental_apk.species_line_id, 0))
	return entry.weight * factor
