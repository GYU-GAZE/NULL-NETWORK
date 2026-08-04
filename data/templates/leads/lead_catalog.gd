extends Resource
class_name LeadCatalog


@export var leads: Array[LeadData] = []


func get_lead(lead_id: String) -> LeadData:
	var clean_id: String = lead_id.strip_edges()

	for lead: LeadData in leads:
		if lead != null and lead.get_display_id() == clean_id:
			return lead

	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var lead_ids: Dictionary = {}

	for index: int in range(leads.size()):
		var lead: LeadData = leads[index]

		if lead == null:
			errors.append("Lead %d is null." % index)
			continue

		var lead_id: String = lead.get_display_id()

		if lead_ids.has(lead_id):
			errors.append("Duplicate lead_id '%s'." % lead_id)
		else:
			lead_ids[lead_id] = true

		for error: String in lead.validate_data():
			errors.append("Lead %d: %s" % [index, error])

	return errors
