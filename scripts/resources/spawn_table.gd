extends Resource
class_name SpawnTable

@export var entries: Array[SpawnEntry] = []

# A Matemática Sênior de Pesos que o Producer pediu!
func roll_encounter() -> CombatEncounter:
	var total_weight = 0
	for entry in entries:
		if entry.encounter != null:
			total_weight += entry.weight
			
	if total_weight <= 0: return null
	
	var roll = randi() % total_weight
	for entry in entries:
		if entry.encounter != null:
			roll -= entry.weight
			if roll < 0:
				return entry.encounter
	return null
