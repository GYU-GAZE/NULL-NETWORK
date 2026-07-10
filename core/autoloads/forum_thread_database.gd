extends Node

const DEFAULT_CONTENT_CATALOG: ForumContentCatalog = preload(
	"res://data/content/forum/forum_content_catalog.tres"
)

@export var content_catalog: ForumContentCatalog = DEFAULT_CONTENT_CATALOG

var loaded_thread_data: Array[ThreadButtonData] = []
var threads_by_id: Dictionary = {}


func _ready() -> void:
	reload_threads()


func reload_threads() -> void:
	loaded_thread_data.clear()
	threads_by_id.clear()

	if content_catalog == null:
		push_error("ForumThreadDatabase: content_catalog não configurado.")
		return

	for folder_path in content_catalog.get_valid_thread_data_folders():
		_load_threads_from_folder(folder_path)

	_rebuild_thread_index()


func _load_threads_from_folder(folder_path: String) -> void:
	var dir: DirAccess = DirAccess.open(folder_path)

	if dir == null:
		push_warning("ForumThreadDatabase: pasta não encontrada: %s" % folder_path)
		return

	dir.list_dir_begin()

	while true:
		var file_name: String = dir.get_next()

		if file_name.is_empty():
			break
		if file_name.begins_with("."):
			continue

		var full_path: String = "%s/%s" % [folder_path, file_name]

		if dir.current_is_dir():
			_load_threads_from_folder(full_path)
			continue

		if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
			continue

		_try_load_thread_resource(full_path)

	dir.list_dir_end()


func _try_load_thread_resource(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)

	if resource == null:
		push_warning("ForumThreadDatabase: falha ao carregar %s" % path)
		return

	if resource is ThreadButtonData:
		var data: ThreadButtonData = resource as ThreadButtonData

		if data.thread_ref == null:
			push_warning("ForumThreadDatabase: ThreadButtonData sem thread_ref em %s" % path)
			return

		loaded_thread_data.append(data)
		return

	if resource is ForumThread:
		var generated_data := ThreadButtonData.new()
		generated_data.thread_ref = resource as ForumThread
		loaded_thread_data.append(generated_data)


func _rebuild_thread_index() -> void:
	threads_by_id.clear()
	var unique_thread_data: Array[ThreadButtonData] = []

	for data in loaded_thread_data:
		if data == null or data.thread_ref == null:
			continue

		var thread_id: String = data.thread_ref.thread_id.strip_edges()

		if thread_id.is_empty():
			unique_thread_data.append(data)
			continue

		if threads_by_id.has(thread_id):
			push_warning(
				"ForumThreadDatabase: thread_id duplicado ignorado: %s" % thread_id
			)
			continue

		threads_by_id[thread_id] = data.thread_ref
		unique_thread_data.append(data)

	loaded_thread_data = unique_thread_data


func get_all_thread_data() -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []

	for data in loaded_thread_data:
		if data != null:
			result.append(data)

	return result


func get_thread_by_id(thread_id: String) -> ForumThread:
	var clean_thread_id: String = thread_id.strip_edges()

	if clean_thread_id.is_empty():
		return null

	return threads_by_id.get(clean_thread_id, null) as ForumThread


func get_threads_started_by_user(
	user: NetworkUserData,
	visible_only: bool = true
) -> Array[ThreadButtonData]:
	var result: Array[ThreadButtonData] = []

	if user == null:
		return result

	for data in loaded_thread_data:
		if data == null or data.thread_ref == null:
			continue
		if visible_only and not data.is_visible():
			continue

		var author_post: ForumPost = data.thread_ref.get_author_post()

		if author_post == null or author_post.author == null:
			continue

		if author_post.author.user_id == user.user_id:
			result.append(data)

	result.sort_custom(_sort_thread_data)
	return result


func _sort_thread_data(a: ThreadButtonData, b: ThreadButtonData) -> bool:
	if a == null or a.thread_ref == null:
		return false
	if b == null or b.thread_ref == null:
		return true
	if a.is_pinned() != b.is_pinned():
		return a.is_pinned()
	if a.thread_ref.popularity_score != b.thread_ref.popularity_score:
		return a.thread_ref.popularity_score > b.thread_ref.popularity_score

	return a.get_release_action_index() > b.get_release_action_index()
