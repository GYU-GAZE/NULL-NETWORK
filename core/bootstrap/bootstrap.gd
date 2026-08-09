extends Node
class_name GameBootstrap


const MAIN_SCENE: PackedScene = preload("res://core/main.tscn")

@onready var startup_presentation: StartupPresentation = %StartupPresentation
@onready var startup_menu: StartupMenu = %StartupMenu
@onready var runtime_root: Node = %RuntimeRoot

var _desktop_instance: Node
var _returning_to_login: bool = false


func _ready() -> void:
	startup_presentation.boot_completed.connect(_on_startup_boot_completed)
	startup_menu.campaign_load_requested.connect(_on_campaign_load_requested)
	startup_menu.campaign_create_requested.connect(
		_on_campaign_create_requested
	)
	startup_menu.campaign_delete_requested.connect(
		_on_campaign_delete_requested
	)

	if not GlobalSignals.request_logout.is_connected(_on_logout_requested):
		GlobalSignals.request_logout.connect(_on_logout_requested)

	KubuTransitionManager.set_runtime_active(false)
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

	await _launch_desktop()


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

	await _launch_desktop()


func _on_campaign_delete_requested(campaign_id: String) -> void:
	if is_instance_valid(_desktop_instance):
		return

	startup_menu.set_busy(true)
	var errors: PackedStringArray = SaveManager.delete_campaign(campaign_id)

	if not errors.is_empty():
		startup_menu.set_busy(false)
		startup_menu.show_error("\n".join(errors))
		return

	var login_period: int = startup_menu.refresh_profiles()
	await startup_presentation.show_login_state(login_period)
	startup_menu.show_error("")
	startup_menu.set_busy(false)


func _launch_desktop() -> void:
	if is_instance_valid(_desktop_instance):
		return

	await KubuTransitionManager.cover_screen()
	_desktop_instance = MAIN_SCENE.instantiate()

	if _desktop_instance == null:
		await KubuTransitionManager.uncover_screen()
		startup_menu.set_busy(false)
		startup_menu.show_error("KubuOS desktop failed to instantiate.")
		return

	startup_presentation.stop_and_hide()
	startup_menu.hide()
	runtime_root.add_child(_desktop_instance)
	KubuTransitionManager.set_runtime_active(true)
	await get_tree().process_frame
	await KubuTransitionManager.uncover_screen()


func _on_logout_requested() -> void:
	if _returning_to_login or not is_instance_valid(_desktop_instance):
		return

	_returning_to_login = true
	await KubuTransitionManager.cover_screen()

	# Logout is a stable KubuOS boundary. Persist the current living state before
	# removing presentation nodes, regardless of SAFE/COMMIT policy.
	if CampaignState.has_campaign():
		if not SaveManager.save_checkpoint(&"system.logout"):
			push_warning("KubuOS logout checkpoint failed; returning to login anyway.")

	KubuTransitionManager.set_runtime_active(false)
	_desktop_instance.queue_free()
	_desktop_instance = null
	await get_tree().process_frame

	startup_menu.set_busy(false)
	var login_period: int = startup_menu.refresh_profiles()
	await startup_presentation.show_login_state(login_period)
	await startup_menu.reveal()
	await KubuTransitionManager.uncover_screen()
	_returning_to_login = false
