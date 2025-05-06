extends RefCounted
class_name Engagement

## Possible reach states for this engagement.
enum ReachState {
	## No advantage.
	NONE,
	## Long-range advantage (longer-weapon holder).
	LONG,
	## Short-range advantage (shorter-weapon holder).
	SHORT,
	
}

enum Reach {
	TOUCH, # Fists, Gauntlets, Spells that require direct contact
	SHORT, # Daggers, Hatchets, Shortswords, all Shields
	MEDIUM, # Broadswords, Battleaxes, Flails
	LONG, # Longswords, Shortspears, "Great" class weapons (Ex: Greatsword)
	VERY_LONG, # Halberds, Longspears, Pikes, Reels
}

## Engaged units.
var unit_1: Unit = null
var unit_2: Unit = null

## Visual line effect between units.
var line_fx: EngagementLineFX = null

## Current reach state (NONE by default).
var reach_state: int = ReachState.NONE

## Current reach state (MEDIUM by default).
var reach: int = Reach.MEDIUM

## Color of the engagement line.
var line_color: Color = Color.RED

## Initialize engagement and set initial reach based on weapon difference.
func _init(_unit1: Unit, _unit2: Unit) -> void:
	unit_1 = _unit1
	unit_2 = _unit2
	reevaluate_reach()

## Manually force long-range state.
func force_longer_reach() -> void:
	reach_state = ReachState.LONG
	reevaluate_reach()

## Manually force short-range state.
func force_shorter_reach() -> void:
	reach_state = ReachState.SHORT
	reevaluate_reach()

## Reset to no advantage (NONE).
func reset_reach() -> void:
	reach_state = ReachState.NONE
	reevaluate_reach()

func initialize_reach() -> void:
	var u_weapons
	
	var w1: Weapon = unit_1.equipment.get_equipped_weapon()
	var w2: Weapon = unit_2.equipment.get_equipped_weapon()
	if not (w1 and w2):
		return

	var diff: int = absi(w1.reach - w2.reach)
	
	if diff < 2:
		reach_state
	
	
	

#func get_unit_with_longer_reach() -> Unit:
#	var w1: Weapon = unit_1.get_equipped_weapon()
#	var w2: Weapon = unit_2.get_equipped_weapon()


## Recalculate reach: initial or forced, update visuals and text.
func reevaluate_reach() -> void:
	var w1: Weapon = unit_1.equipment.get_equipped_weapon()
	var w2: Weapon = unit_2.equipment.get_equipped_weapon()
	if not (w1 and w2):
		return

	var diff: int = absi(w1.reach - w2.reach)


	if diff < 2:
		# Weapons too similar: no advantage
		reach_state = ReachState.NONE
		line_color = Color.RED
	elif reach_state == ReachState.SHORT:
		# Explicit short-range override
		line_color = Color.FOREST_GREEN
		if _base_shorter_reach(unit_1):
			Utilities.spawn_text_line(unit_1, "Close‑Range")
		else:
			Utilities.spawn_text_line(unit_2, "Close‑Range")
	else:
		# Either initial diff>=2 or forced long-range
		reach_state = ReachState.LONG
		line_color = Color.BLUE
		if _base_longer_reach(unit_1):
			Utilities.spawn_text_line(unit_1, "Long Reach")
		else:
			Utilities.spawn_text_line(unit_2, "Long Reach")

	# Apply line color
	if line_fx:
		line_fx.set_color(line_color)

## Query helpers
func is_at_longer_reach(unit: Unit) -> bool:
	return reach_state == ReachState.LONG and _base_longer_reach(unit)

func is_at_shorter_reach(unit: Unit) -> bool:
	return reach_state == ReachState.SHORT and _base_shorter_reach(unit)

func is_fighting_at_longer_range() -> bool:
	var w1: Weapon = unit_1.equipment.get_equipped_weapon()
	var w2: Weapon = unit_2.equipment.get_equipped_weapon()
	if not (w1 and w2) or absi(w1.reach - w2.reach) < 2:
		return false
	return reach_state == ReachState.LONG

func is_fighting_at_shorter_range() -> bool:
	var w1: Weapon = unit_1.equipment.get_equipped_weapon()
	var w2: Weapon = unit_2.equipment.get_equipped_weapon()
	if not (w1 and w2) or absi(w1.reach - w2.reach) < 2:
		return false
	return reach_state == ReachState.SHORT

## Internal base comparisons ignoring state.
func _base_longer_reach(unit: Unit) -> bool:
	var w1 = unit_1.equipment.get_equipped_weapon()
	var w2 = unit_2.equipment.get_equipped_weapon()
	if not (w1 and w2) or absi(w1.reach - w2.reach) < 2:
		return false
	if unit == unit_1:
		return w1.reach > w2.reach
	return w2.reach > w1.reach

func _base_shorter_reach(unit: Unit) -> bool:
	var w1 = unit_1.equipment.get_equipped_weapon()
	var w2 = unit_2.equipment.get_equipped_weapon()
	if not (w1 and w2) or absi(w1.reach - w2.reach) < 2:
		return false
	if unit == unit_1:
		return w1.reach < w2.reach
	return w2.reach < w1.reach

## Visual setup/cleanup
func initialize_line(engagement_system: Node) -> void:
	line_fx = EngagementLineFX.new(unit_1.chest_marker, unit_2.chest_marker)
	engagement_system.add_child(line_fx)
	line_fx.attach_to()
	line_fx.is_active = true
	reevaluate_reach()

func remove_engagement() -> void:
	line_fx.is_active = false
	line_fx.remove()
