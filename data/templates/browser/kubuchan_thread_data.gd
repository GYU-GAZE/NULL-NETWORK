extends Resource
class_name KubuchanThreadData


@export_category("Board")
@export var board_code: String = "/kg/"
@export var board_name: String = "Kubu Gaming"
@export var board_tagline: String = "Games, software toys and network play on KubuOS"

@export_category("Thread")
@export var thread_title: String = ""
@export var thread_id: int = 0
@export var archived_notice: String = ""
@export var posts: Array[KubuchanPostData] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if board_code.strip_edges().is_empty():
		errors.append("board_code cannot be empty.")
	if board_name.strip_edges().is_empty():
		errors.append("board_name cannot be empty.")
	if thread_title.strip_edges().is_empty():
		errors.append("thread_title cannot be empty.")
	if posts.is_empty():
		errors.append("posts cannot be empty.")

	for index in range(posts.size()):
		if posts[index] == null:
			errors.append("posts[%d] cannot be null." % index)

	return errors
