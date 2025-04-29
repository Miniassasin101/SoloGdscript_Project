extends SpecialEffect
class_name CloseRangeEffect


func can_activate(event: ActivationEvent) -> bool:
	if !super.can_activate(event):
		return false
	# make sure attacker & defender are engaged
	var eng: Engagement = CombatSystem.instance.engagement_system.get_engagement(event.unit, event.target_unit)
	if eng == null:
		return false
	
	if eng.reach_state != eng.ReachState.LONG:
		return false
	
	return eng != null

func apply(event: ActivationEvent) -> void:
	super.apply(event)
	# figure out who won & who lost
	var winner: Unit = event.winning_unit
	var loser: Unit = event.losing_unit
	var eng = CombatSystem.instance.engagement_system.get_engagement(winner, loser)
	if eng:
		eng.force_shorter_reach()
