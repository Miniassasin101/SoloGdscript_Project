extends RefCounted
class_name Engagement


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



## Current reach state (MEDIUM by default).
var reach: int = Reach.MEDIUM

## Color of the engagement line.
var line_color: Color = Color.RED


# A simple warm→cool palette so each band is visually distinct
const REACH_COLORS = {
	Reach.TOUCH:     Color(1.0, 0.0, 0.0),   # red
	Reach.SHORT:     Color(1.0, 0.5, 0.0),   # orange
	Reach.MEDIUM:    Color(1.0, 1.0, 0.0),   # yellow
	Reach.LONG:      Color(0.0, 1.0, 0.0),   # green
	Reach.VERY_LONG: Color(0.0, 0.0, 1.0),   # blue
}


## Initialize engagement and set initial reach based on weapon difference.
func _init(_unit1: Unit, _unit2: Unit) -> void:
	unit_1 = _unit1
	unit_2 = _unit2
	initialize_reach()



# Pick the longest reach among *all* weapons both units have
func initialize_reach() -> void:
	var reaches1: Array = unit_1.get_equipped_weapons().map(func(weapon) -> int: return weapon.reach)
	var reaches2: Array = unit_2.get_equipped_weapons().map(func(weapon) -> int: return weapon.reach)

	if reaches1.is_empty() or reaches2.is_empty():
		reach = Reach.TOUCH
	else:
		reach = maxi(reaches1.max(), reaches2.max())
	_update_visuals()


# Force to a specific reach value
func force_reach(to_reach: int) -> void:
	reach = to_reach
	_update_visuals()

# Force to whatever reach a single weapon has
func force_reach_with_weapon(w: Weapon) -> void:
	reach = w.reach
	_update_visuals()

# Common redraw + text label
func _update_visuals() -> void:
	var col: Color = REACH_COLORS.get(reach, Color(1,1,1))
	if line_fx:
		line_fx.set_color(col)
	var label_text: String = ""
	match reach:
		Reach.TOUCH:     label_text = "Touch-Reach"
		Reach.SHORT:     label_text = "Short-Reach"
		Reach.MEDIUM:    label_text = "Medium-Reach"
		Reach.LONG:      label_text = "Long-Reach"
		Reach.VERY_LONG: label_text = "Very-Long-Reach"
		_:               label_text = ""
	Utilities.spawn_text_line(unit_1, label_text)
	Utilities.spawn_text_line(unit_2, label_text)

#func get_unit_with_longer_reach() -> Unit:
#	var w1: Weapon = unit_1.get_equipped_weapon()
#	var w2: Weapon = unit_2.get_equipped_weapon()

# General query: are they fighting at this exact reach band?
func is_fighting_at_range(r: int) -> bool:
	return reach == r

# Convenience sugar:
func is_fighting_at_touch()       -> bool: return is_fighting_at_range(Reach.TOUCH)
func is_fighting_at_short()       -> bool: return is_fighting_at_range(Reach.SHORT)
func is_fighting_at_medium()      -> bool: return is_fighting_at_range(Reach.MEDIUM)
func is_fighting_at_long()        -> bool: return is_fighting_at_range(Reach.LONG)
func is_fighting_at_very_long()   -> bool: return is_fighting_at_range(Reach.VERY_LONG)






# “Is this weapon wielded at too long of a range?”
func is_fighting_at_longer_range(w: Weapon) -> bool:
	if not w:
		return false
	return (w.reach - reach) >= 2

# “Is this weapon wielded at too short of a range?”
func is_fighting_at_shorter_range(w: Weapon) -> bool:
	if not w:
		return false
	return (reach - w.reach) >= 2



## Visual setup/cleanup
func initialize_line(engagement_system: Node) -> void:
	line_fx = EngagementLineFX.new(unit_1.chest_marker, unit_2.chest_marker)
	engagement_system.add_child(line_fx)
	line_fx.attach_to()
	line_fx.is_active = true
	var col: Color = REACH_COLORS.get(reach, Color(1,1,1))
	line_fx.set_color(col)
	#reevaluate_reach()

func remove_engagement() -> void:
	line_fx.is_active = false
	line_fx.remove()
