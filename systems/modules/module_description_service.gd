extends RefCounted
class_name ModuleDescriptionService

## Shared, context-free Module description used by Combat, registration,
## inventories and any future Module browser. Combat can append live preview
## values after this base description without duplicating authored metadata.
static func build_tooltip(module: ModuleData) -> String:
	if module == null:
		return "EMPTY"

	var lines := PackedStringArray([
		"[%s]" % module.module_name
	])

	if not module.description.strip_edges().is_empty():
		lines.append(module.description)

	lines.append("Cost: %d STB" % module.stability_cost)

	if module.execution_count > 1:
		lines.append("Executions: %d" % module.execution_count)

	if not module.classification.is_empty():
		lines.append("Classification: %s" % module.classification)

	lines.append_array(module.describe_effects())
	return "\n".join(lines)
