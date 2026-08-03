extends Node
class_name GameBootstrap


const MAIN_SCENE: PackedScene = preload("res://core/main.tscn")

@onready var campaign_select: CampaignSelect = %CampaignSelect
@onready var runtime_root: Node = %RuntimeRoot

var _desktop_instance: Node


func _ready() -> void:
	campaign_select.campaign_load_requested.connect(_on_campaign_load_requested)
	campaign_select.campaign_create_requested.connect(
		_on_campaign_create_requested
	)


func _on_campaign_load_requested(
	campaign_id: String,
	checkpoint_file_id: String
) -> void:
	campaign_select.set_busy(true)
	var errors := SaveManager.load_campaign(campaign_id, checkpoint_file_id)

	if not errors.is_empty():
		campaign_select.set_busy(false)
		campaign_select.show_error("\n".join(errors))
		return

	_launch_desktop()


func _on_campaign_create_requested(
	campaign_id: String,
	display_name: String,
	save_mode: CampaignState.SaveMode
) -> void:
	campaign_select.set_busy(true)
	var errors := SaveManager.create_campaign(
		campaign_id,
		save_mode,
		display_name
	)

	if not errors.is_empty():
		campaign_select.set_busy(false)
		campaign_select.show_error("\n".join(errors))
		return

	_launch_desktop()


func _launch_desktop() -> void:
	if is_instance_valid(_desktop_instance):
		return

	_desktop_instance = MAIN_SCENE.instantiate()

	if _desktop_instance == null:
		campaign_select.set_busy(false)
		campaign_select.show_error("KubuOS desktop failed to instantiate.")
		return

	runtime_root.add_child(_desktop_instance)
	campaign_select.queue_free()
