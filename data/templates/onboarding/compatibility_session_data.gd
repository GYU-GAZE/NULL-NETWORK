extends Resource
class_name CompatibilitySessionData

@export var first_answer_by_question: Dictionary = {}
@export var final_answer_by_question: Dictionary = {}
@export var answer_change_count_by_question: Dictionary = {}
@export var visited_questions: Dictionary = {}
@export var revisited_questions: Dictionary = {}
@export var revisited_and_kept: Dictionary = {}
@export var revisited_and_changed: Dictionary = {}
@export var visual_answer_order_by_question: Dictionary = {}
@export var selected_visual_position_by_question: Dictionary = {}
@export var recalibration_count: int = 0

func reset_answers() -> void:
	first_answer_by_question.clear()
	final_answer_by_question.clear()
	answer_change_count_by_question.clear()
	visited_questions.clear()
	revisited_questions.clear()
	revisited_and_kept.clear()
	revisited_and_changed.clear()
	visual_answer_order_by_question.clear()
	selected_visual_position_by_question.clear()

func note_question_visit(question_id: String) -> void:
	var id := question_id.strip_edges().to_upper()
	if id.is_empty():
		return
	if bool(visited_questions.get(id, false)):
		revisited_questions[id] = true
		# Merely returning to an answered question and leaving its final answer
		# untouched is canonical REVISITED_KEPT behavior. If the player changes it
		# afterward, record_answer() converts this state to REVISITED_CHANGED.
		if final_answer_by_question.has(id):
			revisited_and_kept[id] = true
	visited_questions[id] = true

func set_visual_order(question_id: String, order: PackedStringArray) -> void:
	visual_answer_order_by_question[question_id.strip_edges().to_upper()] = Array(order)

func get_visual_order(question_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in visual_answer_order_by_question.get(question_id.strip_edges().to_upper(), []):
		result.append(str(value))
	return result

func record_answer(question_id: String, answer_id: String, visual_position: int) -> void:
	var qid := question_id.strip_edges().to_upper()
	var aid := answer_id.strip_edges().to_upper()
	if qid.is_empty() or aid.is_empty():
		return
	var previous := str(final_answer_by_question.get(qid, ""))
	if not first_answer_by_question.has(qid):
		first_answer_by_question[qid] = aid
	elif not previous.is_empty() and previous != aid:
		answer_change_count_by_question[qid] = int(answer_change_count_by_question.get(qid, 0)) + 1
		if bool(revisited_questions.get(qid, false)):
			revisited_and_changed[qid] = true
			revisited_and_kept.erase(qid)
	final_answer_by_question[qid] = aid
	selected_visual_position_by_question[qid] = visual_position
	if (
		bool(revisited_questions.get(qid, false))
		and previous == aid
		and not bool(revisited_and_changed.get(qid, false))
	):
		revisited_and_kept[qid] = true

func is_complete(question_count: int) -> bool:
	return final_answer_by_question.size() >= question_count

func to_save_data() -> Dictionary:
	return {
		"first_answer_by_question": first_answer_by_question.duplicate(true),
		"final_answer_by_question": final_answer_by_question.duplicate(true),
		"answer_change_count_by_question": answer_change_count_by_question.duplicate(true),
		"visited_questions": visited_questions.duplicate(true),
		"revisited_questions": revisited_questions.duplicate(true),
		"revisited_and_kept": revisited_and_kept.duplicate(true),
		"revisited_and_changed": revisited_and_changed.duplicate(true),
		"visual_answer_order_by_question": visual_answer_order_by_question.duplicate(true),
		"selected_visual_position_by_question": selected_visual_position_by_question.duplicate(true),
		"recalibration_count": recalibration_count
	}

func load_save_data(data: Dictionary) -> void:
	first_answer_by_question = _dict(data.get("first_answer_by_question", {}))
	final_answer_by_question = _dict(data.get("final_answer_by_question", {}))
	answer_change_count_by_question = _dict(data.get("answer_change_count_by_question", {}))
	visited_questions = _dict(data.get("visited_questions", {}))
	revisited_questions = _dict(data.get("revisited_questions", {}))
	revisited_and_kept = _dict(data.get("revisited_and_kept", {}))
	revisited_and_changed = _dict(data.get("revisited_and_changed", {}))
	visual_answer_order_by_question = _dict(data.get("visual_answer_order_by_question", {}))
	selected_visual_position_by_question = _dict(data.get("selected_visual_position_by_question", {}))
	recalibration_count = int(data.get("recalibration_count", 0))

func _dict(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}
