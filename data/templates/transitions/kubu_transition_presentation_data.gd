extends Resource
class_name KubuTransitionPresentationData


enum ScreenStartCorner {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

@export_category("Screen Block Transition")
@export var screen_block_texture: Texture2D
@export var screen_block_fallback_color: Color = Color(0.035, 0.045, 0.07, 1.0)
@export_range(4, 40, 1) var screen_grid_columns: int = 14
@export_range(3, 30, 1) var screen_grid_rows: int = 8
@export_range(0.0, 8.0, 0.5) var screen_block_overlap_pixels: float = 1.0
@export_range(0.01, 1.0, 0.01) var screen_block_grow_seconds: float = 0.13
@export_range(0.0, 0.1, 0.001) var screen_diagonal_stagger_seconds: float = 0.016
@export_range(0.0, 1.0, 0.01) var screen_covered_hold_seconds: float = 0.06
@export_range(0.01, 1.0, 0.01) var screen_block_shrink_seconds: float = 0.12
@export var screen_start_corner: ScreenStartCorner = ScreenStartCorner.TOP_LEFT

@export_category("Time Transition Branding")
@export var kubuos_logo_texture: Texture2D
@export var kubuos_fallback_text: String = "KubuOS"
@export var day_symbol_texture: Texture2D
@export var night_symbol_texture: Texture2D
@export var day_symbol_fallback: String = "SUN"
@export var night_symbol_fallback: String = "MOON"

@export_category("Time Transition Palette")
@export var day_background_color: Color = Color(0.09, 0.18, 0.30, 1.0)
@export var day_foreground_color: Color = Color(0.82, 0.92, 1.0, 1.0)
@export var night_background_color: Color = Color(0.10, 0.075, 0.16, 1.0)
@export var night_foreground_color: Color = Color(0.90, 0.85, 0.97, 1.0)
@export var countdown_color: Color = Color(1.0, 0.18, 0.22, 1.0)
@export var trail_inactive_color: Color = Color(0.48, 0.5, 0.6, 0.9)
@export var trail_active_color: Color = Color(0.68, 0.48, 0.86, 1.0)
@export var trail_completed_color: Color = Color(0.42, 0.72, 0.68, 1.0)
@export var weekend_color: Color = Color(0.95, 0.2, 0.24, 1.0)

@export_category("Time Transition Timing")
@export_range(0.05, 2.0, 0.01) var time_intro_seconds: float = 0.28
@export_range(0.0, 2.0, 0.01) var time_pre_period_pause_seconds: float = 0.22
@export_range(0.05, 2.0, 0.01) var time_background_seconds: float = 0.72
@export_range(0.05, 2.0, 0.01) var time_symbol_seconds: float = 0.62
@export_range(0.05, 2.0, 0.01) var time_label_seconds: float = 0.58
@export_range(0.0, 2.0, 0.01) var time_post_period_pause_seconds: float = 0.22
@export_range(0.05, 2.0, 0.01) var time_progress_seconds: float = 0.56
@export_range(0.0, 3.0, 0.01) var time_hold_seconds: float = 0.65
@export_range(0.05, 2.0, 0.01) var time_outro_seconds: float = 0.28
@export_range(0.5, 1.5, 0.01) var countdown_pulse_scale: float = 1.06

@export_category("Day Change Audio")
@export var day_change_tick_stream: AudioStream
@export_range(-40.0, 12.0, 0.5) var day_change_tick_volume_db: float = 0.0
