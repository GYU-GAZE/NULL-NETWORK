extends Node


signal evolution_offered(branch: EvolutionBranchData)
signal evolution_completed(previous_apk_id: String, target_apk_id: String)
signal evolution_declined(branch_id: String)


var _pending_branch_id: String = ""


func find_valid_branch(
	log: CombatTendencyLog,
	completed_branch_ids: PackedStringArray,
	window_kind: EvolutionWindowData.WindowKind = EvolutionWindowData.WindowKind.END_OF_CYCLE
) -> EvolutionBranchData:
	var apk: APKData = APKProgressionService.get_current_apk()

	if apk == null:
		return null

	for branch: EvolutionBranchData in apk.evolution_branches:
		if branch == null \
			or not branch.combat_only \
			or not branch.supports_window(window_kind) \
			or (branch.once_per_battle and completed_branch_ids.has(branch.branch_id)):
			continue

		if branch.is_valid(CampaignState.partner, log):
			return branch

	return null


func offer(branch: EvolutionBranchData) -> bool:
	if branch == null or branch.branch_id.strip_edges().is_empty():
		return false

	_pending_branch_id = branch.branch_id
	evolution_offered.emit(branch)
	return true


func restore_offer(branch_id: String) -> EvolutionBranchData:
	_pending_branch_id = branch_id.strip_edges()
	var branch: EvolutionBranchData = get_pending_branch()

	if branch != null:
		_emit_pending_offer.call_deferred()

	return branch


func _emit_pending_offer() -> void:
	var branch: EvolutionBranchData = get_pending_branch()

	if branch != null:
		evolution_offered.emit(branch)


func get_pending_branch() -> EvolutionBranchData:
	var apk: APKData = APKProgressionService.get_current_apk()

	if apk == null:
		return null

	for branch: EvolutionBranchData in apk.evolution_branches:
		if branch != null and branch.branch_id == _pending_branch_id:
			return branch

	return null


func accept_pending() -> PackedStringArray:
	var branch: EvolutionBranchData = get_pending_branch()

	if branch == null:
		return PackedStringArray(["No evolution branch is pending."])

	var previous_apk_id: String = CampaignState.partner.apk_id
	var errors: PackedStringArray = APKProgressionService.evolve_partner(branch.target_apk_id)

	if errors.is_empty():
		_pending_branch_id = ""
		evolution_completed.emit(previous_apk_id, branch.target_apk_id)

	return errors


func decline_pending() -> String:
	var branch_id: String = _pending_branch_id
	_pending_branch_id = ""

	if not branch_id.is_empty():
		evolution_declined.emit(branch_id)

	return branch_id


func reset() -> void:
	_pending_branch_id = ""
