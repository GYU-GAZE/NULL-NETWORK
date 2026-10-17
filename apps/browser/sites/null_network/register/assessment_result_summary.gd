extends VBoxContainer
class_name AssessmentResultSummary


@export var tendency_row_scene: PackedScene

@onready var tendency_title: Label = %TendencyTitle
@onready var tendency_rows: VBoxContainer = %TendencyRows
@onready var context_panel: PanelContainer = %ContextPanel
@onready var context_label: Label = %ContextLabel
@onready var assignment_intro: Label = %AssignmentIntro
@onready var assigned_species: Label = %AssignedSpecies

var _rows: Array[AssessmentResultTendencyRow] = []


func render(
	tendencies: Dictionary,
	catalog: TendencyCatalogData,
	order: Array[String]
) -> void:
	_clear_rows()
	if catalog == null:
		_reset_context()
		return

	for tendency_id: String in order:
		var definition := catalog.get_definition(tendency_id)
		if definition == null:
			continue

		var row := _instantiate_row()
		if row == null:
			continue

		row.setup(definition, int(tendencies.get(tendency_id, 0)))
		row.mouse_entered.connect(_show_context.bind(definition))
		row.mouse_exited.connect(_reset_context)
		row.focus_entered.connect(_show_context.bind(definition))
		row.focus_exited.connect(_reset_context)
		tendency_rows.add_child(row)
		_rows.append(row)

	_reset_context()


func set_assigned_species(display_name: String) -> void:
	assigned_species.text = (
		display_name.strip_edges()
		if not display_name.strip_edges().is_empty()
		else "UNRESOLVED"
	)


func set_reveal_state(settled: bool) -> void:
	tendency_title.visible = settled
	context_panel.visible = settled
	assignment_intro.visible = settled
	assigned_species.visible = settled
	for row: AssessmentResultTendencyRow in _rows:
		row.visible = settled


func get_tendency_rows() -> Array[Control]:
	var result: Array[Control] = []
	for row: AssessmentResultTendencyRow in _rows:
		result.append(row)
	return result


func reset_context() -> void:
	_reset_context()


func _instantiate_row() -> AssessmentResultTendencyRow:
	if tendency_row_scene == null:
		push_error("AssessmentResultSummary requires tendency_row_scene.")
		return null

	var instance := tendency_row_scene.instantiate() as AssessmentResultTendencyRow
	if instance == null:
		push_error(
			"AssessmentResultSummary tendency_row_scene must instantiate AssessmentResultTendencyRow."
		)
	return instance


func _show_context(definition: TendencyDefinitionData) -> void:
	if definition == null:
		return
	context_label.text = "%s // %s" % [
		definition.display_name,
		definition.description
	]
	context_label.add_theme_color_override(
		"font_color",
		definition.accent_color.lightened(0.28)
	)


func _reset_context() -> void:
	context_label.text = "HOVER A TENDENCY FOR CONTEXT."
	context_label.add_theme_color_override(
		"font_color",
		Color(0.48, 0.64, 0.74, 1.0)
	)


func _clear_rows() -> void:
	_rows.clear()
	for child: Node in tendency_rows.get_children():
		tendency_rows.remove_child(child)
		child.queue_free()
