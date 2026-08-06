extends "res://apps/social/app_social.gd"
class_name SocialRuntimeApp


func _synchronize_unlocked_conversations() -> void:
	SocialInboxProjectionService.synchronize_available_conversations()
