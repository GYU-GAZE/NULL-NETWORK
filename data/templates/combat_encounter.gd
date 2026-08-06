extends Resource
class_name CombatEncounter


@export var encounter_id: String = ""
@export var encounter_name: String = "New Encounter"

@export_category("Slot Layout")
@export var ally_slots: Array[CombatSlotData] = []
@export var enemy_slots: Array[CombatSlotData] = []

@export_category("Active Party")
## Number of active Social party members automatically inserted into empty
## allied slots. Set to 0 for solo-only or explicitly scripted encounters.
@export_range(0, 3, 1) var active_party_slots: int = 3

@export_category("Escape")
@export var can_escape: bool = true
@export_range(0.0, 1.0, 0.01) var base_escape_chance: float = 0.25

@export_category("Campaign Resolution")
@export var resolution: CombatResolutionData


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if encounter_id.strip_edges().is_empty():
		errors.append("CombatEncounter has an empty encounter_id.")

	if ally_slots.is_empty():
		errors.append(
			"Encounter '%s' has no allies."
			% encounter_id
		)

	if enemy_slots.is_empty():
		errors.append(
			"Encounter '%s' has no enemies."
			% encounter_id
		)

	if resolution == null:
		errors.append("Encounter '%s' has no campaign resolution profile." % encounter_id)
	else:
		errors.append_array(resolution.validate_data())

	var all_slots: Array[CombatSlotData] = []
	all_slots.append_array(ally_slots)
	all_slots.append_array(enemy_slots)

	for slot in all_slots:
		if slot == null:
			errors.append(
				"Encounter '%s' contains an invalid slot."
				% encounter_id
			)
			continue

		errors.append_array(slot.validate_data())

	return errors
