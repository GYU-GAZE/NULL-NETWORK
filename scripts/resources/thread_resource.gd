extends Resource
class_name ThreadResource

@export_category("Thread Metadata")
@export var title: String = "Novo Tópico"
@export var author: String = "Anonymous"

# O hint @export_enum cria um menu Dropdown bonitinho no Inspector!
@export_enum("Noise", "News", "Quest", "Tutorial") var thread_type: String = "Noise"

@export_category("Thread Content")
# @export_multiline transforma a caixinha de texto numa caixa grande no Inspector
@export_multiline var content: String = ""
