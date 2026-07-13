extends PanelContainer
class_name BrowserTabButton

signal tab_selected(tab_index: int)
signal tab_close_requested(tab_index: int)

const TAB_HEIGHT: float = 18.0
const FAVICON_SIZE: float = 12.0
const CLOSE_WIDTH: float = 16.0

const COLOR_TAB_ACTIVE: Color = Color(0.0588235, 0.0745098, 0.12549, 1.0)
const COLOR_TAB_IDLE: Color = Color(0.0235294, 0.0313725, 0.054902, 1.0)
const COLOR_BORDER_ACTIVE: Color = Color(0.576471, 0.407843, 1.0, 1.0)
const COLOR_BORDER_IDLE: Color = Color(0.133333, 0.164706, 0.243137, 1.0)
const COLOR_TEXT_ACTIVE: Color = Color(0.913725, 0.901961, 0.980392, 1.0)
const COLOR_TEXT_IDLE: Color = Color(0.537255, 0.564706, 0.662745, 1.0)
const COLOR_TEXT_HOVER: Color = Color(0.729412, 0.658824, 1.0, 1.0)
const COLOR_CLOSE_HOVER: Color = Color(1.0, 0.352941, 0.45098, 1.0)

@onready var favicon_rect: TextureRect = %FaviconRect
@onready var title_button: Button = %TitleButton
@onready var close_button: Button = %CloseButton

var tab_index: int = -1
var is_active: bool = false


func _ready() -> void:
	title_button.pressed.connect(_on_title_pressed)
	close_button.pressed.connect(_on_close_pressed)


func setup(
	index: int,
	title: String,
	icon: Texture2D,
	active: bool,
	can_close: bool,
	tab_width: float
) -> void:
	tab_index = index
	is_active = active

	custom_minimum_size = Vector2(tab_width, TAB_HEIGHT)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_theme_stylebox_override("panel", _make_tab_style(active))

	favicon_rect.texture = icon
	favicon_rect.visible = icon != null
	favicon_rect.custom_minimum_size = Vector2(FAVICON_SIZE, FAVICON_SIZE)
	favicon_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	favicon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	favicon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	favicon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	title_button.text = title
	title_button.tooltip_text = title
	title_button.disabled = false
	title_button.flat = true
	title_button.focus_mode = Control.FOCUS_NONE
	title_button.clip_text = true
	title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_button.add_theme_color_override(
		"font_color",
		COLOR_TEXT_ACTIVE if active else COLOR_TEXT_IDLE
	)
	title_button.add_theme_color_override("font_hover_color", COLOR_TEXT_HOVER)
	title_button.add_theme_color_override("font_pressed_color", COLOR_TEXT_ACTIVE)

	close_button.text = "x"
	close_button.tooltip_text = "Close tab"
	close_button.visible = can_close and active
	close_button.disabled = not can_close
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(CLOSE_WIDTH, TAB_HEIGHT)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.add_theme_color_override("font_color", COLOR_TEXT_IDLE)
	close_button.add_theme_color_override("font_hover_color", COLOR_CLOSE_HOVER)
	close_button.add_theme_color_override("font_pressed_color", COLOR_CLOSE_HOVER)

	modulate = Color.WHITE


func _make_tab_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_TAB_ACTIVE if active else COLOR_TAB_IDLE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = COLOR_BORDER_ACTIVE if active else COLOR_BORDER_IDLE
	style.content_margin_left = 3.0
	style.content_margin_top = 0.0
	style.content_margin_right = 2.0
	style.content_margin_bottom = 0.0
	return style


func _on_title_pressed() -> void:
	tab_selected.emit(tab_index)


func _on_close_pressed() -> void:
	tab_close_requested.emit(tab_index)
