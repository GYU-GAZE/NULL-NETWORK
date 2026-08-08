@tool
extends Resource
class_name StartupPresentationData


@export_category("Custom Splashes")
@export var splashes: Array[StartupSplashData] = []
@export_range(1.0, 30.0, 0.5) var skip_speed_multiplier: float = 10.0

@export_category("KubuOS Boot")
@export var kubuos_logo_texture: Texture2D
@export var kubuos_fallback_text: String = "KubuOS"
@export_range(0.01, 2.0, 0.01) var logo_ignite_seconds: float = 0.18
@export_range(0.0, 2.0, 0.01) var logo_hold_seconds: float = 0.22
@export_range(0.01, 2.0, 0.01) var screen_power_seconds: float = 0.12
@export_range(0.01, 3.0, 0.01) var reveal_seconds: float = 0.72
@export_range(0.0, 0.45, 0.01) var logo_target_screen_y_ratio: float = 0.16
@export_range(0.25, 1.0, 0.01) var logo_target_scale: float = 0.72
@export_range(0.0, 0.75, 0.01) var background_intro_pan_ratio: float = 0.22

@export_category("Backdrop")
@export var day_background_texture: Texture2D
@export var night_background_texture: Texture2D
@export var day_background_color: Color = Color(0.055, 0.18, 0.27, 1.0)
@export var night_background_color: Color = Color(0.012, 0.025, 0.075, 1.0)
@export_range(0.0, 160.0, 1.0) var backdrop_overscan_pixels: float = 72.0
@export var mouse_parallax_pixels: Vector2 = Vector2(18.0, 10.0)
@export_range(1.0, 20.0, 0.5) var parallax_follow_speed: float = 6.0

@export_category("Placeholder Styling")
@export var splash_text_color: Color = Color(0.9, 0.94, 1.0, 1.0)
@export var kubuos_text_color: Color = Color(0.72, 0.94, 1.0, 1.0)
@export var power_line_color: Color = Color(0.82, 0.96, 1.0, 1.0)
