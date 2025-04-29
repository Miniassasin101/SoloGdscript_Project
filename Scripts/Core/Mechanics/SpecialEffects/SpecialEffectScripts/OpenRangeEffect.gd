extends SpecialEffect
class_name OpenRangeEffect



func can_activate(event: ActivationEvent) -> bool:
	if !super.can_activate(event):
		return false
	# must be engaged
	var eng: Engagement = CombatSystem.instance.engagement_system.get_engagement(event.unit, event.target_unit)
	if eng == null:
		return false
	# only trigger if currently at SHORT reach
	if eng.reach_state != eng.ReachState.SHORT:
		return false
	return true

func apply(event: ActivationEvent) -> void:
	super.apply(event)
	# identify winner vs loser
	var winner: Unit = event.winning_unit
	var loser: Unit = event.losing_unit
	var eng: Engagement = CombatSystem.instance.engagement_system.get_engagement(winner, loser)
	if eng:
		eng.force_longer_reach()
