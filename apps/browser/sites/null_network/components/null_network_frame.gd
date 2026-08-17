@tool
extends PanelContainer
class_name NullNetworkFrame

## Reusable stepped-corner frame used by every NULL NETWORK web page.
## The frame is drawn at native Godot canvas resolution so borders remain a
## crisp single pixel before KubuOS applies its fixed 2x presentation scale.

enum FrameTone {
	QUIET,
	STANDARD,
	BRIGHT,
	SELECTED,
	FOOTER,
}

@export var tone: FrameTone = FrameTone.STANDARD:
	set(value):
		tone = value
		queue_redraw()
@export_range(2, 12, 1) var corner_cut: int = 6:
	set(value):
		corner_cut = value
		queue_redraw()
@export var draw_inner_border: bool = true:
	set(value):
		draw_inner_border = value
		queue_redraw()
@export var draw_corner_marks: bool = true:
	set(value):
		draw_corner_marks = value
		queue_redraw()
@export var draw_scanlines: bool = false:
	set(value):
		draw_scanlines = value
		queue_redraw()
@export var accent_override: Color = Color(0.0, 0.0, 0.0, 0.0):
	set(value):
		accent_override = value
		queue_redraw()


func _ready() -> void:
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return

	var palette := _palette_for_tone()
	var background: Color = palette.background
	var border: Color = palette.border
	var accent: Color = palette.accent
	var glow: Color = palette.glow
	var cut := float(min(corner_cut, int(min(size.x, size.y) * 0.25)))
	var outer_points := _frame_points(Rect2(Vector2.ZERO, size), cut)

	# A pair of translucent outlines reproduces the electric bloom without
	# introducing filtered textures or non-integer geometry.
	if glow.a > 0.0:
		for spread in range(3, 0, -1):
			var glow_rect := Rect2(
				Vector2(float(spread), float(spread)),
				size - Vector2(float(spread * 2), float(spread * 2))
			)
			if glow_rect.size.x > 2.0 and glow_rect.size.y > 2.0:
				draw_polyline(
					_frame_points(glow_rect, max(1.0, cut - float(spread))),
					Color(glow, glow.a / float(spread + 1)),
					1.0,
					false
				)

	var fill_points := PackedVector2Array()
	for point_index: int in range(outer_points.size() - 1):
		fill_points.append(outer_points[point_index])
	draw_colored_polygon(fill_points, background)
	draw_polyline(outer_points, border, 1.0, false)

	if draw_inner_border and size.x > 12.0 and size.y > 12.0:
		var inner_rect := Rect2(Vector2(4.0, 4.0), size - Vector2(8.0, 8.0))
		draw_polyline(
			_frame_points(inner_rect, max(2.0, cut - 2.0)),
			Color(border, border.a * 0.42),
			1.0,
			false
		)

	if draw_scanlines:
		var scanline_color := Color(accent, 0.025)
		for y in range(5, int(size.y) - 4, 4):
			draw_line(Vector2(5.0, float(y)), Vector2(size.x - 5.0, float(y)), scanline_color, 1.0)

	if draw_corner_marks:
		_draw_corner_marks(accent, cut)


func _frame_points(rect: Rect2, cut: float) -> PackedVector2Array:
	var left := rect.position.x
	var top := rect.position.y
	var right := rect.end.x - 1.0
	var bottom := rect.end.y - 1.0
	return PackedVector2Array([
		Vector2(left + cut, top),
		Vector2(right - cut, top),
		Vector2(right, top + cut),
		Vector2(right, bottom - cut),
		Vector2(right - cut, bottom),
		Vector2(left + cut, bottom),
		Vector2(left, bottom - cut),
		Vector2(left, top + cut),
		Vector2(left + cut, top),
	])


func _draw_corner_marks(color: Color, cut: float) -> void:
	var mark: float = maxf(3.0, cut - 1.0)
	var inset: float = 3.0
	var right: float = size.x - inset
	var bottom: float = size.y - inset
	var mark_color := Color(color, minf(1.0, color.a * 1.15))

	draw_line(Vector2(inset, inset + mark), Vector2(inset, inset), mark_color, 1.0)
	draw_line(Vector2(inset, inset), Vector2(inset + mark, inset), mark_color, 1.0)
	draw_line(Vector2(right - mark, inset), Vector2(right, inset), mark_color, 1.0)
	draw_line(Vector2(right, inset), Vector2(right, inset + mark), mark_color, 1.0)
	draw_line(Vector2(inset, bottom - mark), Vector2(inset, bottom), mark_color, 1.0)
	draw_line(Vector2(inset, bottom), Vector2(inset + mark, bottom), mark_color, 1.0)
	draw_line(Vector2(right - mark, bottom), Vector2(right, bottom), mark_color, 1.0)
	draw_line(Vector2(right, bottom), Vector2(right, bottom - mark), mark_color, 1.0)


func _palette_for_tone() -> Dictionary:
	if accent_override.a > 0.0:
		var strength: float = 1.0 if tone == FrameTone.SELECTED else 0.72
		return {
			"background": Color(
				accent_override.r * 0.055,
				accent_override.g * 0.09,
				accent_override.b * 0.12,
				0.95
			),
			"border": Color(accent_override, 0.92 * strength),
			"accent": Color(accent_override, 1.0),
			"glow": Color(accent_override, 0.38 if tone == FrameTone.SELECTED else 0.12),
		}
	match tone:
		FrameTone.QUIET:
			return {
				"background": Color("06121fe6"),
				"border": Color("2b6d9bb6"),
				"accent": Color("3b91c7c7"),
				"glow": Color("1c8fd000"),
			}
		FrameTone.BRIGHT:
			return {
				"background": Color("0a2034f2"),
				"border": Color("1599dfef"),
				"accent": Color("54d6ffff"),
				"glow": Color("008ee84a"),
			}
		FrameTone.SELECTED:
			return {
				"background": Color("123656f0"),
				"border": Color("66e8ffff"),
				"accent": Color("ffffffff"),
				"glow": Color("00aaff8a"),
			}
		FrameTone.FOOTER:
			return {
				"background": Color("041422f8"),
				"border": Color("1e628fb2"),
				"accent": Color("348fc5d6"),
				"glow": Color("1c8fd000"),
			}
		_:
			return {
				"background": Color("071b2dec"),
				"border": Color("3c93c7e7"),
				"accent": Color("42c7fffa"),
				"glow": Color("008ee82f"),
			}
