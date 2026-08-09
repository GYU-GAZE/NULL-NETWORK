extends Node
class_name AdaptiveBrowserPageLayout


const DEFAULT_SITE_THEME: Theme = preload(
	"res://data/assets/themes/browser_site_theme.tres"
)


@export var page_path: NodePath = NodePath("..")
@export var apply_site_theme: bool = true
@export var site_theme: Theme = DEFAULT_SITE_THEME


func _ready() -> void:
	call_deferred("_apply_adaptive_layout")


func _apply_adaptive_layout() -> void:
	var page := get_node_or_null(page_path) as Control

	if page == null:
		push_warning(
			"AdaptiveBrowserPageLayout: page_path must resolve to a Control."
		)
		return

	# BrowserApp now owns full-rect responsive sizing for every WebsitePage.
	# This compatibility helper remains on older Forum/Updates scenes only to
	# apply their optional site theme; it no longer performs a second layout pass.
	if apply_site_theme and site_theme != null:
		page.theme = site_theme
