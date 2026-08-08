extends Node
class_name GameBootstrap


const MAIN_SCENE: PackedScene = preload("res://core/main.tscn")

@onready var startup_presentation: StartupPresentation = %StartupPresentation
@onready var startup_menu: StartupMenu = %StartupMenu
@onready var runtime_root: Node = %RuntimeRoot

var _desktop_instance: Node


func _ready() -> void:
	startup_presentation.boot_completed.connect(_on_startup_boot_completed)
	startup_menu.campaign_load_requested.connect(_on_campaign_load_requested)
	startup_menu.campaign_create_requested.connect(
		_on_campaign_create_requested
	)
	var initial_period: int = startup_menu.refresh_profiles()
	startup_presentation.play(initial_period)


func _on_startup_boot_completed() -> void:
	startup_menu.reveal()


func _on_campaign_load_requested(
	campaign_id: String,
	checkpoint_file_id: String
) -> void:
	startup_menu.set_busy(true)
	var errors := SaveManager.load_campaign(campaign_id, checkpoint_file_id)

	if not errors.is_empty():
		startup_menu.set_busy(false)
		startup_menu.show_error("\n".join(errors))
		return

	_launch_desktop()


func _on_campaign_create_requested(
	campaign_id: String,
	display_name: String,
	save_mode: CampaignState.SaveMode
) -> void:
	startup_menu.set_busy(true)
	var errors := SaveManager.create_campaign(
		campaign_id,
		save_mode,
		display_name
	)

	if not errors.is_empty():
		startup_menu.set_busy(false)
		startup_menu.show_error("\n".join(errors))
		return

	_launch_desktop()


func _launch_desktop() -> void:
	if is_instance_valid(_desktop_instance):
		return

	_desktop_instance = MAIN_SCENE.instantiate()

	if _desktop_instance == null:
		startup_menu.set_busy(false)
		startup_menu.show_error("KubuOS desktop failed to instantiate.")
		return

	startup_presentation.stop_and_hide()
	startup_menu.hide()
	runtime_root.add_child(_desktop_instance)
