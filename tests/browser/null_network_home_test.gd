extends Node

const HOME_SCENE: PackedScene = preload("res://data/content/sites/null network/nnw_homepage.tscn")
const GET_STARTED_SCENE: PackedScene = preload("res://data/content/sites/null network/nnw_getstarted1.tscn")
const SILVER_BASE_SIZE: int = 11
const ACCOUNT_REQUIRED_MESSAGE: String = "You must have an account to access this area."

var _failures := PackedStringArray()

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var home := HOME_SCENE.instantiate() as Control
	_check(home != null, "Null Network home failed to instantiate.")
	if home == null:
		_finish_test()
		return

	home.set_anchors_preset(Control.PRESET_TOP_LEFT)
	home.size = Vector2(832, 393)
	add_child(home)
	await get_tree().process_frame

	_check(home.theme != null and home.theme.default_font_size == SILVER_BASE_SIZE, "Null Network home must keep the compact Silver portal scale.")

	var title := home.find_child("PortalTitle", true, false) as Label
	_check(title != null and title.text == "null NETWORK", "Null Network home lost its shared portal header title.")
	_check(title != null and title.get_theme_font_size(&"font_size") == 16, "Null Network portal header must use the reference-scaled Silver title size.")

	var background := home.find_child("Background", true, false) as ColorRect
	_check(background != null and background.material is ShaderMaterial, "Null Network home must use the shared scanline portal background.")

	var guest_card := home.find_child("GuestCard", true, false) as PanelContainer
	_check(guest_card != null, "Logged-out user placeholder card is missing.")
	if guest_card != null:
		_check(guest_card.custom_minimum_size == Vector2(218, 38), "Guest card must match the adapted NULL NETWORK reference footprint.")

	var avatar := home.find_child("GuestAvatar", true, false) as PanelContainer
	_check(avatar != null and avatar.custom_minimum_size == Vector2(28, 28), "Guest avatar placeholder must match the adapted portal header avatar size.")

	var hero_title := home.find_child("HeroTitle", true, false) as Label
	_check(hero_title != null and hero_title.text == "THE WORLD IS UNDER SIEGE.", "Null Network home lost the supplied hero headline.")
	_check(home.find_child("MainFrame", true, false) is NullNetworkFrame, "Null Network home must use the stepped reference frame renderer.")
	_check_footer_fits_canvas(home, "Null Network home")

	var login_button := home.find_child("LoginButton", true, false) as Button
	var sign_up_button := home.find_child("SignUpButton", true, false) as SiteActionButton
	_check(login_button != null, "Guest card must expose Login.")
	_check(sign_up_button != null, "Guest card must expose Sign Up.")
	if sign_up_button != null:
		_check(sign_up_button.target_url == "null.net/register", "Sign Up must route directly to operator registration.")

	_check(_button_target(home, "Get Started") == "null.net/getstarted", "Get Started route changed during visual revamp.")
	_check(_button_target(home, "UpdatesBtn") == "null.net/updates", "Changelog route changed during visual revamp.")
	_check(_button_target(home, "ThreadsBtn") == "null.net/forums", "Message Board route changed during visual revamp.")
	_check(_button_target(home, "RankingsBtn") == "null.net/playerrankings", "Player Rankings route changed during visual revamp.")

	_check_account_gate(home, "UpdatesBtn")
	_check_account_gate(home, "ThreadsBtn")
	_check_account_gate(home, "RankingsBtn")

	var description := home.find_child("DescriptionLabel", true, false) as Label
	_check(description != null, "Null Network home description was lost.")
	if description != null:
		_check(description.text.contains("In the lead-up to the devastating Y2K virus"), "Existing intro copy changed during visual-only revamp.")
		_check(description.text.contains("From the brilliant mind of Tarou Yamada."), "Existing creator credit changed during visual-only revamp.")
		_check(description.text.contains("コバルトブルー"), "Existing Japanese footer copy changed during visual-only revamp.")

	home.queue_free()
	var guide := GET_STARTED_SCENE.instantiate() as Control
	_check(guide != null, "NULL NETWORK Get Started failed to instantiate.")
	if guide != null:
		guide.set_anchors_preset(Control.PRESET_TOP_LEFT)
		guide.size = Vector2(832, 393)
		add_child(guide)
		await get_tree().process_frame
		_check(guide.theme != null and guide.theme.default_font_size == SILVER_BASE_SIZE, "Get Started must share the NULL NETWORK Silver portal theme.")
		_check(guide.find_child("PortalHeader", true, false) != null, "Get Started lost the shared portal header.")
		_check(guide.find_child("PathRail", true, false) != null, "Get Started lost its guided left navigation rail.")
		_check(guide.find_child("ArticlePanel", true, false) != null, "Get Started lost its framed article reader.")
		_check(guide.find_child("ContentFrame", true, false) is NullNetworkFrame, "Get Started must use the stepped reference frame renderer.")
		_check_footer_fits_canvas(guide, "Get Started")
		guide.queue_free()
	_finish_test()

func _check_footer_fits_canvas(page: Control, page_name: String) -> void:
	var footer := page.find_child("PortalFooter", true, false) as Control
	_check(footer != null, "%s lost its shared portal footer." % page_name)
	if footer == null:
		return
	_check(
		footer.position.y + footer.size.y <= page.size.y + 0.5,
		"%s overflows the canonical 832x393 browser canvas." % page_name
	)

func _check_account_gate(root: Node, node_name: String) -> void:
	var button := root.find_child(node_name, true, false) as SiteActionButton
	_check(button != null, "%s must use SiteActionButton." % node_name)
	if button == null:
		return
	_check(button.required_flag_name == "operator.registered", "%s must gate on operator.registered." % node_name)
	_check(button.required_flag_value, "%s must unlock when operator.registered is true." % node_name)
	_check(button.show_alert_on_failed_condition, "%s must pop an alert while the account gate fails." % node_name)
	_check(button.failed_alert_message == ACCOUNT_REQUIRED_MESSAGE, "%s account-required alert copy changed." % node_name)
	_check(button.failed_condition_behavior == SiteActionButton.FailedConditionBehavior.DO_NOTHING, "%s must stay clickable so its failed click can open the alert." % node_name)

func _button_target(root: Node, node_name: String) -> String:
	var button := root.find_child(node_name, true, false) as SiteActionButton
	return button.target_url if button != null else ""

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish_test() -> void:
	if _failures.is_empty():
		print("NULL_NETWORK_HOME_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("NULL_NETWORK_HOME_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
