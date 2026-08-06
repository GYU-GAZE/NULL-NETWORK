extends Node


signal installation_succeeded(app_id: String)
signal installation_rejected(app_id: String, reason: String)


var _synchronization_queued: bool = false
var _is_synchronizing: bool = false


func _ready() -> void:
	if not CampaignState.campaign_changed.is_connected(_on_campaign_changed):
		CampaignState.campaign_changed.connect(_on_campaign_changed)

	if not ContentRegistry.registry_rebuilt.is_connected(_on_registry_rebuilt):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)

	_queue_installation_synchronization()


func is_installed(app_id: String) -> bool:
	var clean_id: String = app_id.strip_edges()
	return not clean_id.is_empty() and CampaignState.installed_app_ids.has(clean_id)


func can_install(
	app_id: String,
	context: GameEffectContext = null
) -> bool:
	var app: AppResource = ContentRegistry.get_app(app_id)

	if app == null or not CampaignState.has_campaign():
		return false

	return is_installed(app.app_id) or app.can_install(context)


func install_app(
	app_id: String,
	context: GameEffectContext = null,
	show_notification: bool = true,
	apply_installation_effects: bool = true
) -> bool:
	var clean_id: String = app_id.strip_edges()
	var app: AppResource = ContentRegistry.get_app(clean_id)

	if app == null:
		_reject(clean_id, "App is not registered in ContentRegistry.")
		return false

	if not CampaignState.has_campaign():
		_reject(clean_id, "An active campaign is required.")
		return false

	if is_installed(clean_id):
		return true

	if not app.can_install(context):
		_reject(clean_id, "Unlock conditions are not met.")
		return false

	if context == null:
		context = GameEffectContext.create("app.installation.%s" % clean_id)

	if not CampaignState.install_app(clean_id):
		_reject(clean_id, "CampaignState rejected the installation.")
		return false

	if apply_installation_effects:
		var failed_effects: PackedStringArray = GameEffectData.apply_all(
			app.installation_effects,
			context
		)

		for effect_id: String in failed_effects:
			push_error(
				"App installation '%s' failed effect '%s'."
				% [clean_id, effect_id]
			)

	if show_notification:
		_push_installation_notification(app)

	installation_succeeded.emit(clean_id)
	return true


func _queue_installation_synchronization() -> void:
	if _synchronization_queued or _is_synchronizing:
		return

	_synchronization_queued = true
	call_deferred("_synchronize_installations")


func _synchronize_installations() -> void:
	_synchronization_queued = false

	if _is_synchronizing or not CampaignState.has_campaign():
		return

	var catalog: AppCatalog = ContentRegistry.get_app_catalog()

	if catalog == null:
		return

	_is_synchronizing = true

	for app: AppResource in catalog.get_ordered_apps():
		if app == null or is_installed(app.app_id):
			continue

		if app.installed_by_default:
			install_app(app.app_id, null, false, true)
			continue

		if not app.auto_install_when_unlocked:
			continue

		var context := GameEffectContext.create(
			"app.auto_install.%s" % app.app_id,
			"",
			CampaignState.current_location_id,
			"",
			"app_installation_sync"
		)

		if app.can_install(context):
			install_app(app.app_id, context, true, true)

	_is_synchronizing = false


func _push_installation_notification(app: AppResource) -> void:
	if app == null or app.notification_data == null:
		return

	var data: KubuNotificationData = app.notification_data
	var source_app_id: String = data.source_app_id.strip_edges()

	if source_app_id.is_empty():
		source_app_id = app.app_id.strip_edges()

	UniversalNotifications.push_data(
		data.title,
		data.message,
		data.notification_type,
		data.target_url,
		source_app_id,
		data.source_thread_id,
		data.priority,
		data.icon if data.icon != null else app.app_icon
	)


func _reject(app_id: String, reason: String) -> void:
	installation_rejected.emit(app_id, reason)


func _on_campaign_changed(_section: StringName) -> void:
	_queue_installation_synchronization()


func _on_registry_rebuilt() -> void:
	_queue_installation_synchronization()
