extends Node
class_name BrowserChromeSkin

@export_category("Pixel Chrome Metrics")
@export var tab_bar_height: float = 20.0
@export var address_bar_height: float = 22.0
@export var tab_content_height: float = 18.0
@export var address_control_height: float = 18.0
@export var navigation_button_width: float = 18.0
@export var compact_side_margin: int = 3
@export var standard_side_margin: int = 4
@export var wide_side_margin: int = 6

var _browser: BrowserApp


func _ready() -> void:
	call_deferred("_bind_and_apply")


func _bind_and_apply() -> void:
	_browser = get_parent() as BrowserApp

	if _browser == null:
		push_error("BrowserChromeSkin must be a direct child of BrowserApp.")
		return

	if not _browser.resized.is_connected(_apply_chrome):
		_browser.resized.connect(_apply_chrome)

	_apply_chrome()


func _apply_chrome() -> void:
	if _browser == null or not is_instance_valid(_browser):
		return

	var side_margin: int = _resolve_side_margin()
	var tab_bar_margin := _browser.get_node_or_null("MainVBox/TabBarMargin") as MarginContainer
	var address_bar_margin := _browser.get_node_or_null("MainVBox/AddressBarMargin") as MarginContainer
	var tab_bar_hbox := _browser.get_node_or_null("MainVBox/TabBarMargin/TabBarHBox") as HBoxContainer
	var address_bar_hbox := _browser.get_node_or_null("MainVBox/AddressBarMargin/AddressBarHBox") as HBoxContainer

	if tab_bar_margin != null:
		tab_bar_margin.custom_minimum_size.y = tab_bar_height
		tab_bar_margin.add_theme_constant_override("margin_left", side_margin)
		tab_bar_margin.add_theme_constant_override("margin_top", 1)
		tab_bar_margin.add_theme_constant_override("margin_right", side_margin)
		tab_bar_margin.add_theme_constant_override("margin_bottom", 0)

	if address_bar_margin != null:
		address_bar_margin.custom_minimum_size.y = address_bar_height
		address_bar_margin.add_theme_constant_override("margin_left", side_margin)
		address_bar_margin.add_theme_constant_override("margin_top", 1)
		address_bar_margin.add_theme_constant_override("margin_right", side_margin)
		address_bar_margin.add_theme_constant_override("margin_bottom", 2)

	if tab_bar_hbox != null:
		tab_bar_hbox.add_theme_constant_override("separation", 2)

	if address_bar_hbox != null:
		address_bar_hbox.add_theme_constant_override("separation", 3)

	_apply_control_size(_browser.tab_scroll, Vector2(0.0, tab_content_height))
	_apply_control_size(_browser.new_tab_button_holder, Vector2(0.0, tab_content_height))
	_apply_control_size(_browser.browser_back_btn, Vector2(navigation_button_width, address_control_height))
	_apply_control_size(_browser.home_button, Vector2(navigation_button_width, address_control_height))
	_apply_control_size(_browser.go_button, Vector2(navigation_button_width, address_control_height))
	_apply_control_size(_browser.favorite_button, Vector2(navigation_button_width, address_control_height))
	_apply_control_size(_browser.url_line_edit, Vector2(0.0, address_control_height))

	_browser.browser_back_btn.text = "<"
	_browser.browser_back_btn.tooltip_text = "Back"
	_browser.home_button.text = "H"
	_browser.home_button.tooltip_text = "Home"
	_browser.go_button.text = ">"
	_browser.go_button.tooltip_text = "Go"
	_browser.favorite_button.tooltip_text = "Favorite"
	_browser.url_line_edit.placeholder_text = "ENTER ADDRESS"
	_browser.url_line_edit.caret_blink = true


func _resolve_side_margin() -> int:
	match _browser.current_responsive_mode:
		BrowserApp.ResponsiveMode.COMPACT:
			return compact_side_margin
		BrowserApp.ResponsiveMode.WIDE:
			return wide_side_margin

	return standard_side_margin


func _apply_control_size(control: Control, requested_size: Vector2) -> void:
	if control == null:
		return

	if requested_size.x > 0.0:
		control.custom_minimum_size.x = requested_size.x

	if requested_size.y > 0.0:
		control.custom_minimum_size.y = requested_size.y
