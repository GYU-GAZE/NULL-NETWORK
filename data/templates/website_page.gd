extends Resource
class_name WebsitePage

enum HeaderType {
	NONE,
	TEXT,
	IMAGE
}

@export var url: String = "www.site.com"
@export var page_title: String = "Nova Página"

@export_category("Template Components")
@export var header_type: HeaderType = HeaderType.IMAGE
@export var header_text: String = ""
@export var header_image: Texture2D
@export var navbar_links: Dictionary = {}
@export var content_blocks: Array[PageBlock] = []

@export_category("Custom Injection")
@export var custom_site_scene: PackedScene
