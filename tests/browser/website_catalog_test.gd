extends Node

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_check(SimulatedDNS.website_catalog != null, "SimulatedDNS must use WebsiteCatalog as its route source.")
	if SimulatedDNS.website_catalog != null:
		var errors := SimulatedDNS.website_catalog.validate_data()
		_check(errors.is_empty(), "WebsiteCatalog validation failed: %s" % [errors])
		_check(SimulatedDNS.website_catalog.pages.size() >= 10, "WebsiteCatalog unexpectedly lost registered Browser routes.")
	_check(SimulatedDNS.fetch_page("null.net") != null, "WebsiteCatalog no longer resolves null.net.")
	_check(SimulatedDNS.fetch_page("null.net/register") != null, "WebsiteCatalog no longer resolves registration.")
	_check(SimulatedDNS.fetch_page("kubuchan.net") != null, "WebsiteCatalog no longer resolves Kubuchan.")
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("WEBSITE_CATALOG_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("WEBSITE_CATALOG_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
