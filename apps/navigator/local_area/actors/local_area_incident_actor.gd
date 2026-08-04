extends LocalAreaInteractable
class_name LocalAreaIncidentActor


var incident_id: String = ""
var population_actor_id: String = ""


func configure_population_actor(
	new_actor_id: String,
	incident: IncidentData
) -> bool:
	if incident == null:
		return false

	population_actor_id = new_actor_id.strip_edges()
	incident_id = incident.get_display_id()
	persistence_scope = PersistenceScope.WORLD_POPULATION

	var data := LocalAreaInteractionData.new()
	data.interaction_id = population_actor_id
	data.display_name = incident.title
	data.kind = LocalAreaInteractionData.InteractionKind.CUSTOM
	data.prompt_verb = "INVESTIGATE"
	interaction_data = data
	return not incident_id.is_empty()


func can_interact() -> bool:
	return (
		not incident_id.is_empty()
		and not CampaignState.has_completed_incident(incident_id)
		and super.can_interact()
	)
