extends Resource
class_name ForumThread

@export var thread_id: String = ""

@export var board_name: String = "General"
@export var thread_title: String = "Novo Tópico"

@export var posts: Array[ForumPost] = []