@tool
extends RefCounted
class_name BrowserRoute

## One identity rule for DNS, history, validation and the authoring plugin.
static func normalize(raw_url: String) -> String:
	var value := raw_url.strip_edges().to_lower()
	value = value.trim_prefix("https://").trim_prefix("http://").trim_prefix("www.")
	while value.ends_with("/"):
		value = value.trim_suffix("/")
	return value


static func validate(raw_url: String) -> String:
	var value := normalize(raw_url)
	if value.is_empty():
		return "URL cannot be empty."
	if " " in value or "\n" in value or "\\" in value or value.begins_with("/"):
		return "URL must contain a domain and an optional path, without spaces."
	if "://" in value and not value.begins_with("kubus://"):
		return "Only http, https and internal kubus routes are supported."
	return ""


static func matches_prefix(url: String, prefix: String) -> bool:
	var target := normalize(url)
	var base := normalize(prefix)
	return not base.is_empty() and (target == base or target.begins_with(base + "/"))
