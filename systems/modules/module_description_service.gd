extends RefCounted
class_name ModuleDescriptionService

static func build_tooltip(module: ModuleData) -> String:
	if module == null:
		return "NO MODULE DATA"
	var lines := PackedStringArray()
	lines.append(module.module_name)
	if not module.classification.is_empty():
		lines.append("[%s]" % str(module.classification).to_upper())
	if not module.description.strip_edges().is_empty():
		lines.append("")
		lines.append(module.description.strip_edges())
	if module.module_kind == ModuleData.ModuleKind.ACTIVE:
		lines.append("")
		lines.append("STABILITY COST: %d" % module.stability_cost)
		lines.append("ACCURACY: %d%%" % roundi(module.accuracy * 100.0))
		if module.execution_count > 1:
			lines.append("EXECUTIONS: %d" % module.execution_count)
	var effects := module.describe_effects()
	if not effects.is_empty():
		lines.append("")
		for effect_line: String in effects:
			lines.append(effect_line)
	return "\n".join(lines)
