extends RefCounted
class_name FieldResponseEvaluator

## Participation is independent of perception/pursuit. Pure, seeded evaluation
## over actual actor/world facts; no new ecological or world authority.
static func evaluate(profile: FieldBehaviorProfileData, behavior: int, context: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for rule: FieldCallResponseRule in profile.response_rules:
		if rule != null and rule.matches(context):
			if rng.randf() > rule.probability:
				return _result(FieldCallResponseRule.Response.IGNORE)
			return {"response": int(rule.response), "join": rule.response in [FieldCallResponseRule.Response.JOIN, FieldCallResponseRule.Response.INTERCEPT], "delay": rule.hesitation_seconds if rule.response == FieldCallResponseRule.Response.HESITATE else 0.0}
	if rng.randf() > profile.response_probability:
		return _result(FieldCallResponseRule.Response.IGNORE)
	match behavior:
		FieldBehaviorProfileData.Behavior.AGGRESSIVE, FieldBehaviorProfileData.Behavior.SWARM:
			return _result(FieldCallResponseRule.Response.JOIN)
		FieldBehaviorProfileData.Behavior.PACK:
			return _result(FieldCallResponseRule.Response.JOIN if bool(context.get("same_species", false)) else FieldCallResponseRule.Response.IGNORE)
		FieldBehaviorProfileData.Behavior.PROTECTIVE:
			return _result(FieldCallResponseRule.Response.INTERCEPT if bool(context.get("same_species", false)) or bool(context.get("caller_protected", false)) else FieldCallResponseRule.Response.OBSERVE)
		FieldBehaviorProfileData.Behavior.TERRITORIAL:
			return _result(FieldCallResponseRule.Response.INTERCEPT if bool(context.get("caller_in_territory", false)) else FieldCallResponseRule.Response.IGNORE)
		FieldBehaviorProfileData.Behavior.CAUTIOUS, FieldBehaviorProfileData.Behavior.COWARDLY:
			return _result(FieldCallResponseRule.Response.FLEE)
		FieldBehaviorProfileData.Behavior.CURIOUS:
			return _result(FieldCallResponseRule.Response.OBSERVE)
		FieldBehaviorProfileData.Behavior.OPPORTUNIST:
			if float(context.get("player_hp_fraction", 1.0)) <= profile.opportunist_hp_threshold:
				return _result(FieldCallResponseRule.Response.JOIN)
			return _result(FieldCallResponseRule.Response.HESITATE)
	return _result(FieldCallResponseRule.Response.IGNORE)

static func _result(response: int) -> Dictionary:
	return {"response": response, "join": response in [FieldCallResponseRule.Response.JOIN, FieldCallResponseRule.Response.INTERCEPT], "delay": 0.0}
