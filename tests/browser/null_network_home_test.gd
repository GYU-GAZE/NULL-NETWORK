extends Node

const HOME_SCENE: PackedScene = preload("res://data/content/sites/null network/nnw_homepage.tscn")
const SILVER_BASE_SIZE: int = 19
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

	home.size = Vector2(1000, 700)
	add_child(home)
	await get_tree().process_frame

	_check(home.theme != null and home.theme.default_font_size == SILVER_BASE_SIZE, "Null Network home must keep Silver on its native 19 px grid.")

	var title := home.find_child("NullChannelTitle", true, false) as Label
	_check(title != null and title.get_theme_font_size(&"font_size") == 38, "Null Network home title must use the 38 px Silver multiple.")

	var guest_card := home.find_child("GuestCard", true, false) as PanelContainer
	_check(guest_card != null, "Logged-out user placeholder card is missing.")
	if guest_card != null:
		_check(guest_card.custom_minimum_size == Vector2(128, 72), "Guest card must match the Null Channel user block footprint.")

	var avatar := home.find_child("GuestAvatar", true, false) as PanelContainer
	_check(avatar != null and avatar.custom_minimum_size == Vector2(32, 32), "Guest avatar placeholder must match the Null Channel avatar size.")

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
	_finish_test()

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
