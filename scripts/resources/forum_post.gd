extends Resource
class_name ForumPost

@export_category("User Profile")
@export var avatar: Texture2D
@export var username: String = "Anonymous"
@export var user_title: String = "Newbie"
@export var location: String = "Unknown"

@export_category("Content")
@export_multiline var text_content: String = ""
@export var image_content: Texture2D
