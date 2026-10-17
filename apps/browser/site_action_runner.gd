extends RefCounted
class_name SiteActionRunner

## Shared execution for buttons, rich links, cards and list controls. Effects
## are not transactional: a failed effect stops success feedback/navigation;
## earlier effects retain the semantics of the existing GameEffectData pipeline.
static func execute(action: SiteActionData, source: Node) -> Dictionary:
	if action == null:
		return {"status": "missing_action"}
	var page := BrowserPageContext.find(source)
	if page != null and not page.enabled:
		return {"status": "inactive_page"}
	var context := create_context(source, action)
	if not action.is_available(context):
		if action.show_failed_alert:
			UniversalAlerts.show_alert(action.failed_alert_title, action.failed_alert_message, action.failed_alert_animation)
		return {"status": "blocked"}
	var failures := action.apply_effects(context)
	if not failures.is_empty():
		return {"status": "failed", "failed_effects": failures}
	if action.notification != null:
		UniversalNotifications.push_resource(action.notification, "browser", page.url if page != null else "")
	elif action.show_notification:
		UniversalNotifications.push_data(action.notification_title, action.notification_message, KubuNotificationData.NotificationType.SYSTEM, "", "browser")
	if action.show_alert:
		UniversalAlerts.show_alert(action.alert_title, action.alert_message, action.alert_animation)
	var url := action.target_url.strip_edges()
	if not url.is_empty():
		if page != null:
			page.request_navigation(url)
		elif source.has_signal(&"browser_navigation_requested"):
			source.emit_signal(&"browser_navigation_requested", url)
	return {"status": "success"}


static func create_context(source: Node, action: SiteActionData) -> GameEffectContext:
	return GameEffectContext.create("site_action:%s" % source.name, action.target_url, CampaignState.current_location_id)
