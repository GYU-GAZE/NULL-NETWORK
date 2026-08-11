extends Resource
class_name KubuchanPostData


@export_category("Identity")
@export var post_number: int = 0
@export var subject: String = ""
@export var author_name: String = "Anonymous"
@export var uid: String = "000000"
@export var timestamp: String = ""

@export_category("Content")
@export_multiline var body_text: String = ""
@export var is_op: bool = false
@export var is_system_spam: bool = false

@export_category("Navigation")
@export var link_label: String = ""
@export var link_url: String = ""


func has_link() -> bool:
	return not link_label.strip_edges().is_empty() and not link_url.strip_edges().is_empty()
