extends Node
class_name BrowserPageContext

signal navigation_requested(url: String)

const META: StringName = &"browser_page_context"
var page: Control
var url: String = ""
var enabled: bool = true
var _legacy_connections: Array[Dictionary] = []
var _form_components: Array[int] = []


static func find(source: Node) -> BrowserPageContext:
	var cursor := source
	while is_instance_valid(cursor):
		if cursor.has_meta(META):
			var context := cursor.get_meta(META) as BrowserPageContext
			return context if is_instance_valid(context) else null
		cursor = cursor.get_parent()
	return null


static func navigate(source: Node, target: String) -> bool:
	var context := find(source)
	if context == null:
		return false
	context.request_navigation(target)
	return true


func request_navigation(target: String) -> void:
	if enabled and not target.strip_edges().is_empty():
		navigation_requested.emit(BrowserRoute.normalize(target))


func bind_page(root: Control) -> void:
	page = root
	root.set_meta(META, self)
	_bind_legacy(root)
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	enabled = false
	for connection: Dictionary in _legacy_connections:
		var source := instance_from_id(connection.id)
		if is_instance_valid(source) and source.is_connected(&"browser_navigation_requested", connection.callback):
			source.disconnect(&"browser_navigation_requested", connection.callback)
	_legacy_connections.clear()


func _on_node_added(node: Node) -> void:
	if is_instance_valid(page) and (node == page or page.is_ancestor_of(node)):
		_bind_legacy(node)


func _bind_legacy(node: Node) -> void:
	if node is BrowserFormState and node.get_instance_id() not in _form_components:
		_form_components.append(node.get_instance_id())
	# New controls route by ancestor context, including controls created later.
	# Existing page-level signals remain supported without an early root return.
	if node.has_signal(&"browser_navigation_requested") and not (node is SiteActionButton or node is SiteRichTextLabel):
		var callback := request_navigation
		if not node.is_connected(&"browser_navigation_requested", callback):
			node.connect(&"browser_navigation_requested", callback)
			_legacy_connections.append({"id": node.get_instance_id(), "callback": callback})
	for child: Node in node.get_children():
		_bind_legacy(child)


func capture_state() -> Dictionary:
	var state := {}
	if is_instance_valid(page) and page.has_method("get_browser_state"):
		var custom: Variant = page.call("get_browser_state")
		if custom is Dictionary:
			state = BrowserHistoryEntry.sanitize(custom)
	var forms := {}
	for id: int in _form_components:
		var form := instance_from_id(id) as BrowserFormState
		if is_instance_valid(form):
			forms[str(page.get_path_to(form))] = form.capture()
	if not forms.is_empty():
		state["_browser_forms"] = forms
	return state


func restore_state(state: Dictionary) -> void:
	if is_instance_valid(page) and page.has_method("restore_browser_state"):
		await page.call("restore_browser_state", state)
	var forms: Variant = state.get("_browser_forms", {})
	if forms is not Dictionary:
		return
	for id: int in _form_components:
		var form := instance_from_id(id) as BrowserFormState
		if is_instance_valid(form):
			var saved: Variant = forms.get(str(page.get_path_to(form)), {})
			if saved is Dictionary:
				form.restore(saved)
