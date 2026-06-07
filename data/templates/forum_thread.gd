extends Resource
class_name ForumThread

enum ThreadCategory {
	GUIDE,
	RUMOR,
	HELP,
	SOCIAL
}

@export_category("Identity")
@export var thread_id: String = ""
@export var thread_title: String = "Novo Tópico"
@export var thread_label: String = ""
@export var thread_category: ThreadCategory = ThreadCategory.SOCIAL
@export var thread_tags: Array[String] = []

@export_category("Legacy Compatibility")
@export var board_name: String = "General"

@export_category("Fallback Author")
@export var thread_author: String = "Anonymous"
@export var author_rank: String = "Newbie"
@export var author_title: String = ""

@export_category("Thread State")
@export var is_pinned: bool = false
@export var is_locked: bool = false
@export var is_archived: bool = false
@export var popularity_score: int = 0

@export_category("Activity Fallback")
@export var reply_count: int = 0
@export var last_reply_author: String = ""
@export var last_reply_time_label: String = ""

@export_category("Preview")
@export_multiline var thread_preview: String = ""

@export_category("Content")
@export var posts: Array[ForumPost] = []


func get_category_label() -> String:
	match thread_category:
		ThreadCategory.GUIDE:
			return "GUIDE"
		ThreadCategory.RUMOR:
			return "RUMOR"
		ThreadCategory.HELP:
			return "HELP"
		ThreadCategory.SOCIAL:
			return "SOCIAL"

	return "SOCIAL"


func get_category_icon_text() -> String:
	match thread_category:
		ThreadCategory.GUIDE:
			return "GDE"
		ThreadCategory.RUMOR:
			return "RMR"
		ThreadCategory.HELP:
			return "HLP"
		ThreadCategory.SOCIAL:
			return "SOC"

	return "SOC"


func get_thread_label_text() -> String:
	var clean_label: String = thread_label.strip_edges()

	if clean_label.is_empty():
		return ""

	return "[%s]" % clean_label


func get_visible_posts() -> Array[ForumPost]:
	var result: Array[ForumPost] = []

	for post in posts:
		if post == null:
			continue

		if post.is_visible():
			result.append(post)

	return result


func get_author_post() -> ForumPost:
	var visible_posts: Array[ForumPost] = get_visible_posts()

	for post in visible_posts:
		if post.is_op:
			return post

	if not visible_posts.is_empty():
		return visible_posts[0]

	return null


func get_last_post() -> ForumPost:
	var visible_posts: Array[ForumPost] = get_visible_posts()

	if visible_posts.is_empty():
		return null

	return visible_posts[visible_posts.size() - 1]


func get_thread_author() -> String:
	var author_post: ForumPost = get_author_post()

	if author_post != null:
		return author_post.username

	return thread_author


func get_thread_author_title() -> String:
	var author_post: ForumPost = get_author_post()

	if author_post != null:
		return author_post.get_display_title()

	if author_title.is_empty():
		return author_rank

	return "%s | %s" % [author_rank, author_title]


func get_reply_count() -> int:
	var visible_posts: Array[ForumPost] = get_visible_posts()

	if not visible_posts.is_empty():
		return max(0, visible_posts.size() - 1)

	if reply_count > 0:
		return reply_count

	return 0


func get_last_reply_author() -> String:
	var last_post: ForumPost = get_last_post()

	if last_post != null:
		return last_post.username

	if not last_reply_author.is_empty():
		return last_reply_author

	return get_thread_author()


func get_last_reply_time_label() -> String:
	var last_post: ForumPost = get_last_post()

	if last_post != null and not last_post.time_label.is_empty():
		return last_post.time_label

	if not last_reply_time_label.is_empty():
		return last_reply_time_label

	return ""


func get_preview_text() -> String:
	if not thread_preview.is_empty():
		return thread_preview.strip_edges()

	var visible_posts: Array[ForumPost] = get_visible_posts()

	for post in visible_posts:
		if not post.text_content.is_empty():
			return post.text_content.strip_edges()

	return ""


func has_unread_content() -> bool:
	if thread_id.is_empty():
		return false

	return not GameState.has_read_thread(thread_id)


func get_visibility_signature() -> String:
	var visible_posts: Array[ForumPost] = get_visible_posts()
	var parts: Array[String] = []

	for i in range(visible_posts.size()):
		var post: ForumPost = visible_posts[i]

		if post.post_id.is_empty():
			parts.append("idx_%d" % i)
		else:
			parts.append(post.post_id)

	return "|".join(parts)


func matches_search(query: String) -> bool:
	var normalized_query: String = query.strip_edges().to_lower()

	if normalized_query.is_empty():
		return true

	if thread_title.to_lower().contains(normalized_query):
		return true

	if thread_label.to_lower().contains(normalized_query):
		return true

	if get_category_label().to_lower().contains(normalized_query):
		return true

	if board_name.to_lower().contains(normalized_query):
		return true

	if get_thread_author().to_lower().contains(normalized_query):
		return true

	for tag in thread_tags:
		if tag.to_lower().contains(normalized_query):
			return true

	for post in get_visible_posts():
		if post.matches_search(normalized_query):
			return true

	return false


func get_sort_score() -> int:
	var score: int = popularity_score

	if is_pinned:
		score += 100000

	return score
