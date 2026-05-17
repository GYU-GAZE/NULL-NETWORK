extends Resource
class_name WebsitePage

enum HeaderType {
	NONE,
	TEXT,
	IMAGE
}

@export var url: String = "www.site.com"

@export_category("Template Components")
@export var header_type: HeaderType = HeaderType.IMAGE
@export var header_text: String = ""
@export var header_image: Texture2D
@export var navbar_links: Dictionary = {} # Key: "Home", Value: "www.site.com"
@export var content_blocks: Array[PageBlock] = []

@export_category("Custom Injection")
# Se este campo for preenchido, o Browser ignora os blocos e carrega o App inteiro.
@export var custom_site_scene: PackedScene