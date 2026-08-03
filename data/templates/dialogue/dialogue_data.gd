extends Resource
class_name DialogueData


@export_category("Identity")
@export var dialogue_id: String = ""
@export var initial_node_id: String = ""

@export_category("Content")
@export var speakers: Array[DialogueSpeakerData] = []
@export var nodes: Array[DialogueNodeData] = []


func get_display_id() -> String:
	return dialogue_id.strip_edges()


func get_speaker(speaker_id: String) -> DialogueSpeakerData:
	var clean_id: String = speaker_id.strip_edges()

	for speaker: DialogueSpeakerData in speakers:
		if speaker != null and speaker.get_display_id() == clean_id:
			return speaker

	return null


func get_node_data(node_id: String) -> DialogueNodeData:
	var clean_id: String = node_id.strip_edges()

	for node: DialogueNodeData in nodes:
		if node != null and node.get_display_id() == clean_id:
			return node

	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var speaker_ids: Dictionary = {}
	var node_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("dialogue_id cannot be empty.")

	if initial_node_id.strip_edges().is_empty():
		errors.append("initial_node_id cannot be empty.")

	for index: int in range(speakers.size()):
		var speaker: DialogueSpeakerData = speakers[index]

		if speaker == null:
			errors.append("Speaker %d is null." % index)
			continue

		var speaker_id: String = speaker.get_display_id()

		if not speaker_id.is_empty() and speaker_ids.has(speaker_id):
			errors.append("Duplicate speaker_id '%s'." % speaker_id)
		else:
			speaker_ids[speaker_id] = true

		for error: String in speaker.validate_data():
			errors.append("Speaker %d: %s" % [index, error])

	for index: int in range(nodes.size()):
		var node: DialogueNodeData = nodes[index]

		if node == null:
			errors.append("Node %d is null." % index)
			continue

		var node_id: String = node.get_display_id()

		if not node_id.is_empty() and node_ids.has(node_id):
			errors.append("Duplicate node_id '%s'." % node_id)
		else:
			node_ids[node_id] = true

		for error: String in node.validate_data():
			errors.append("Node %d: %s" % [index, error])

	if not initial_node_id.strip_edges().is_empty() \
		and not node_ids.has(initial_node_id.strip_edges()):
		errors.append("initial_node_id does not resolve inside this dialogue.")

	for node: DialogueNodeData in nodes:
		if node == null:
			continue

		if not speaker_ids.has(node.speaker_id.strip_edges()):
			errors.append(
				"Node '%s' references unknown speaker_id '%s'."
				% [node.get_display_id(), node.speaker_id]
			)

		for state: DialoguePortraitState in node.portrait_states:
			if state != null and not speaker_ids.has(state.speaker_id.strip_edges()):
				errors.append(
					"Node '%s' portrait references unknown speaker_id '%s'."
					% [node.get_display_id(), state.speaker_id]
				)

		_validate_node_reference(errors, node.get_display_id(), node.next_node_id, node_ids)

		for choice: DialogueChoiceData in node.choices:
			if choice != null:
				_validate_node_reference(
					errors,
					"%s/%s" % [node.get_display_id(), choice.get_display_id()],
					choice.next_node_id,
					node_ids
				)

	return errors


func _validate_node_reference(
	errors: PackedStringArray,
	source_id: String,
	raw_target_id: String,
	known_node_ids: Dictionary
) -> void:
	var target_id: String = raw_target_id.strip_edges()

	if not target_id.is_empty() and not known_node_ids.has(target_id):
		errors.append(
			"'%s' references unknown next_node_id '%s'."
			% [source_id, target_id]
		)
