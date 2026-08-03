extends Node


signal installation_succeeded(app_id: String)
signal installation_rejected(app_id: String, reason: String)


func _ready() -> void:
	if not CampaignState.campaign_changed.is_connected(_on_campaign_changed):
		CampaignState.campaign_changed.connect(_on_campaign_changed)

	if not ContentRegistry.registry_rebuilt.is_connected(_on_registry_rebuilt):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)

	_ensure_default_installations()


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


func _ensure_default_installations() -> void:
	if not CampaignState.has_campaign():
		return

	var catalog: AppCatalog = ContentRegistry.get_app_catalog()

	if catalog == null:
		return

	for app_id: String in catalog.get_default_app_ids():
		install_app(app_id, null, false, true)


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


func _on_campaign_changed(section: StringName) -> void:
	if section == &"campaign":
		_ensure_default_installations()


func _on_registry_rebuilt() -> void:
	_ensure_default_installations()
