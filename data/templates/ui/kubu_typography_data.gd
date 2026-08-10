@tool
extends Resource
class_name KubuTypographyData


@export_category("Font Source")
## Exact source font bytes encoded as Base64 so the typography remains a normal
## text Resource in version control while still producing a real FontFile at runtime.
@export_multiline var embedded_font_base64: String = ""
@export var fallback_font: Font

@export_category("Pixel Rendering")
## Native design size of the typeface. Unstyled text uses this exact size.
@export_range(1, 64, 1) var font_size: int = 6
## Explicit display sizes are snapped to integer multiples of the design size,
## preserving visual hierarchy without introducing fractional pixel geometry.
@export var preserve_explicit_size_hierarchy: bool = true
@export var oversampling: float = 1.0

var _cached_font: FontVariation


func get_font() -> Font:
	if _cached_font != null:
		return _cached_font

	if embedded_font_base64.strip_edges().is_empty():
		return fallback_font

	var source_bytes: PackedByteArray = Marshalls.base64_to_raw(
		embedded_font_base64.strip_edges()
	)

	if source_bytes.is_empty():
		push_error("KubuTypographyData: embedded font data could not be decoded.")
		return fallback_font

	var source_font := FontFile.new()
	source_font.data = source_bytes

	# This typeface is authored on an exact 6 px grid. These settings deliberately
	# disable every smoothing path that can introduce fractional coverage or glyph
	# positions. Project canvas filtering is already Nearest, so integer display
	# scaling keeps the raster completely hard-edged.
	source_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	source_font.hinting = TextServer.HINTING_NONE
	source_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	source_font.multichannel_signed_distance_field = false
	source_font.generate_mipmaps = false
	source_font.oversampling = maxf(1.0, oversampling)
	source_font.allow_system_fallback = false

	var variation := FontVariation.new()
	variation.base_font = source_font

	# KubuOS Micro only carries the compact Latin/ASCII face. Silver remains the
	# explicit fallback for any glyph the system font does not contain, preventing
	# arbitrary host-OS fonts from entering the game's presentation.
	if fallback_font != null:
		var fallback_list: Array[Font] = []
		fallback_list.append(fallback_font)
		variation.fallbacks = fallback_list

	_cached_font = variation
	return _cached_font


func get_pixel_aligned_size(requested_size: int) -> int:
	var design_size: int = maxi(1, font_size)

	if not preserve_explicit_size_hierarchy or requested_size <= design_size:
		return design_size

	var scale: int = maxi(1, roundi(float(requested_size) / float(design_size)))
	return design_size * scale


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if embedded_font_base64.strip_edges().is_empty():
		errors.append("embedded_font_base64 cannot be empty.")

	if font_size <= 0:
		errors.append("font_size must be greater than zero.")

	if oversampling < 1.0:
		errors.append("oversampling must be at least 1.0 for pixel typography.")

	return errors
