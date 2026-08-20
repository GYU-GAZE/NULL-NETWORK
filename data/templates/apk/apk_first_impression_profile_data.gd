@tool
extends Resource
class_name APKFirstImpressionProfileData


enum Reaction {
	POSITIVE,
	NEUTRAL,
	FRICTION
}

const REQUIRED_TRAIT_IDS := PackedStringArray([
	"reactive",
	"proactive",
	"improvisational",
	"structured",
	"independent",
	"collective",
	"reserved",
	"expressive",
	"detached",
	"attached",
	"familiar",
	"curious",
	"present_oriented",
	"aspiring"
])

@export var profile_id: String = ""
@export_multiline var fallback_line: String = ""
@export var reaction_by_trait: Dictionary = {}
@export var line_by_trait: Dictionary = {}


func get_line(trait_id: String) -> String:
	var clean_id := _normalize_trait_id(trait_id)
	var line := str(line_by_trait.get(clean_id, "")).strip_edges()
	return line if not line.is_empty() else fallback_line.strip_edges()


func get_reaction(trait_id: String) -> int:
	var clean_id := _normalize_trait_id(trait_id)
	return clampi(
		int(reaction_by_trait.get(clean_id, Reaction.NEUTRAL)),
		Reaction.POSITIVE,
		Reaction.FRICTION
	)


func has_complete_trait_coverage() -> bool:
	for trait_id: String in REQUIRED_TRAIT_IDS:
		if not line_by_trait.has(trait_id):
			return false
		if str(line_by_trait.get(trait_id, "")).strip_edges().is_empty():
			return false
		if not reaction_by_trait.has(trait_id):
			return false
	return true


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id.strip_edges().is_empty():
		errors.append("APK first-impression profile requires profile_id.")
	if fallback_line.strip_edges().is_empty():
		errors.append("APK first-impression profile '%s' requires fallback_line." % profile_id)

	for trait_id: String in REQUIRED_TRAIT_IDS:
		if not line_by_trait.has(trait_id) or str(line_by_trait.get(trait_id, "")).strip_edges().is_empty():
			errors.append("APK first-impression profile '%s' is missing dialogue for '%s'." % [profile_id, trait_id])
		if not reaction_by_trait.has(trait_id):
			errors.append("APK first-impression profile '%s' is missing reaction for '%s'." % [profile_id, trait_id])
			continue
		var reaction_value := int(reaction_by_trait.get(trait_id, -1))
		if reaction_value < Reaction.POSITIVE or reaction_value > Reaction.FRICTION:
			errors.append("APK first-impression profile '%s' has invalid reaction for '%s'." % [profile_id, trait_id])
	return errors


func _normalize_trait_id(trait_id: String) -> String:
	return trait_id.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
