extends LocalAreaInteractable
class_name LocalAreaLegacySiteActor


var legacy_site_id: String = ""
var archived_operator_id: String = ""


func configure_population_actor(
	new_actor_id: String,
	descriptor: Dictionary
) -> bool:
	var site := LegacySiteStateData.from_save_data(descriptor)
	var validation_errors: PackedStringArray = site.validate_state()

	if not validation_errors.is_empty():
		return false

	legacy_site_id = site.get_display_id()
	archived_operator_id = site.operator_id
	persistence_scope = PersistenceScope.WORLD_POPULATION

	var data := LocalAreaInteractionData.new()
	data.interaction_id = new_actor_id.strip_edges()
	data.display_name = "Broken KubuOS Handtop"
	data.kind = LocalAreaInteractionData.InteractionKind.EXAMINE
	data.prompt_verb = "INSPECT"
	data.response_text = (
		"The damaged handtop still identifies its archived Operator as %s. "
		+ "Its material data remains sealed behind a corrupted NULL NETWORK session."
	) % (
		site.operator_display_name
		if not site.operator_display_name.is_empty()
		else site.operator_id
	)
	interaction_data = data

	var label := get_node_or_null("LegacyLabel") as Label

	if label != null:
		label.text = "LEGACY // %s" % site.operator_id.to_upper()

	return not legacy_site_id.is_empty() and not data.interaction_id.is_empty()


func get_persistent_state() -> Dictionary:
	var state: Dictionary = super.get_persistent_state()
	state["legacy_site_id"] = legacy_site_id
	state["archived_operator_id"] = archived_operator_id
	return state
