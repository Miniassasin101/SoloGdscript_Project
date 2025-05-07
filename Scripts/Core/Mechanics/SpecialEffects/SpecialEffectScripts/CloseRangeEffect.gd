extends SpecialEffect
class_name CloseRangeEffect

func can_activate(event: ActivationEvent) -> bool:
	if !super.can_activate(event):
		return false
	# Must be engaged at longer reach against this unit’s weapon
	var eng: Engagement = CombatSystem.instance.engagement_system.get_engagement(event.unit, event.target_unit)
	if eng == null:
		return false
	# Choose the relevant weapon (attacker or defender)
	var w: Weapon = event.defender_weapon if event.winning_unit == event.target_unit else event.weapon
	if not w:
		return false
	# Only if unit’s weapon is too long for the engagement by 2 steps or more
	if not eng.is_fighting_at_shorter_range(w):
		return false
	return true

func apply(event: ActivationEvent) -> void:
	super.apply(event)
	var winner: Unit = event.winning_unit
	var loser: Unit  = event.losing_unit
	var eng: Engagement = CombatSystem.instance.engagement_system.get_engagement(winner, loser)
	if eng:
		var w: Weapon = event.defender_weapon if winner == event.target_unit else event.weapon
		if w:
			# Close range to this weapon’s reach
			eng.force_reach(w.reach)
