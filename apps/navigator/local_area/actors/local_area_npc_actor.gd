extends LocalAreaInteractable
class_name LocalAreaNPCActor

## Physical projection only. NPCData/routines and CampaignState remain the
## authorities for identity, schedule, social state and dialogue progression.
@export var npc: NPCData


func configure_population_actor(actor_id: String, definition: NPCData) -> bool:
	if definition == null or actor_id.is_empty():
		return false
	npc = definition
	persistence_scope = PersistenceScope.WORLD_POPULATION
	var data := LocalAreaInteractionData.new()
	data.interaction_id = actor_id
	data.display_name = npc.get_display_name()
	data.prompt_verb = "TALK"
	data.dialogue = ContentRegistry.get_dialogue(npc.default_dialogue_id)
	data.kind = LocalAreaInteractionData.InteractionKind.DIALOGUE if data.dialogue != null else LocalAreaInteractionData.InteractionKind.EXAMINE
	data.response_text = npc.get_display_name()
	var routine := npc.get_active_routine()
	if routine != null and not routine.status_text.is_empty():
		data.response_text += ": " + routine.status_text
	interaction_data = data
	return true


func _ready() -> void:
	if npc != null:
		(%NameLabel as Label).text = npc.get_display_name()
		(%Portrait as Sprite2D).texture = npc.portrait
