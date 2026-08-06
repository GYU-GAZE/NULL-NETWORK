extends "res://core/autoloads/social_service.gd"


## Concrete campaign runtime for the Social domain.
##
## SocialStateData is serialized inside CampaignState, so every successful
## SocialService mutation only needs to queue the shared Campaign checkpoint.
## Deferred checkpoint coalescing prevents one save per delivered message.

func _commit(npc_id: String) -> void:
	super._commit(npc_id)

	var checkpoint_suffix: String = npc_id.strip_edges()

	if checkpoint_suffix.is_empty():
		checkpoint_suffix = "global"

	SaveManager.request_checkpoint(
		StringName("social.state.%s" % checkpoint_suffix),
		false
	)
