extends Resource
class_name ForumContentCatalog

@export_category("Thread Sources")
@export var thread_data_folders: Array[String] = []


func get_valid_thread_data_folders() -> Array[String]:
	var result: Array[String] = []
	var seen_paths: Dictionary = {}

	for folder_path in thread_data_folders:
		var clean_path: String = folder_path.strip_edges().trim_suffix("/")

		if clean_path.is_empty() or seen_paths.has(clean_path):
			continue

		seen_paths[clean_path] = true
		result.append(clean_path)

	return result
