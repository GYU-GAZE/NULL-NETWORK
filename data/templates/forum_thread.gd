extends Resource
class_name ForumThread

@export var board_name: String = "General"
@export var thread_title: String = "Novo Tópico"
# Aqui mora a magia relacional: Um array de posts dentro da thread!
@export var posts: Array[ForumPost] = []
