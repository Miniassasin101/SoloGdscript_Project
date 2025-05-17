# EngagementSystem.gd
extends Node
class_name EngagementSystem

## Tracks all current Engagement instances.
var engagements: Array[Engagement] = []

func _ready() -> void:
	engagements.clear()
	
	SignalBus.on_unit_removed.connect(_on_unit_removed)


## Generate engagements for every opposing, adjacent pair.
func generate_engagements() -> void:
	engagements.clear()
	var all_units = UnitManager.instance.get_all_units()
	
	for i in range(all_units.size()):
		for j in range(i + 1, all_units.size()):
			var unit_a = all_units[i]
			var unit_b = all_units[j]
			
			# Only engage if they’re on opposite sides
			if unit_a.is_enemy == unit_b.is_enemy:
				continue
				
			# Diagonal adjacency check
			var adjacent = Utilities.get_adjacent_tiles_with_diagonal(unit_a)
			if adjacent.has(unit_b.grid_position):
				add_engagement(unit_a, unit_b)


## True if there’s an Engagement pairing these two (in either order).
func are_units_engaged(unit_a: Unit, unit_b: Unit) -> bool:
	for engagement in engagements:
		if (engagement.unit_1 == unit_a and engagement.unit_2 == unit_b)\
		or  (engagement.unit_1 == unit_b and engagement.unit_2 == unit_a):
			return true
	return false


## Return the Engagement for these two units (or null).
func get_engagement(unit_a: Unit, unit_b: Unit) -> Engagement:
	for engagement in engagements:
		if (engagement.unit_1 == unit_a and engagement.unit_2 == unit_b)\
		or  (engagement.unit_1 == unit_b and engagement.unit_2 == unit_a):
			return engagement
	return null


## Returns a list of opponents engaged with `unit`.
func get_engaged_opponents(unit: Unit) -> Array[Unit]:
	var ret: Array[Unit] = []
	for engagement in engagements:
		if engagement.unit_1 == unit:
			ret.append(engagement.unit_2)
		elif engagement.unit_2 == unit:
			ret.append(engagement.unit_1)
	return ret

func get_engagements(unit: Unit) -> Array[Engagement]:
	var ret: Array[Engagement] = []
	for engagement in engagements:
		if engagement.unit_1 == unit:
			ret.append(engagement)
		elif engagement.unit_2 == unit:
			ret.append(engagement)
	return ret

## Add a new Engagement if none exists already.
func add_engagement(unit_a: Unit, unit_b: Unit) -> void:
	if not are_units_engaged(unit_a, unit_b):
		var e = Engagement.new(unit_a, unit_b)
		e.initialize_line(self)
		engagements.append(e)

		Utilities.spawn_text_line(unit_a, "Engaged")
		Utilities.spawn_text_line(unit_b, "Engaged")
		unit_a.animator.enable_head_look(unit_b.body.get_part_marker("head"))
		unit_b.animator.enable_head_look(unit_a.body.get_part_marker("head"))
		SignalBus.on_ui_update.emit()


## Remove and clean up an existing Engagement.
func remove_engagement(unit_a: Unit, unit_b: Unit) -> void:
	var e = get_engagement(unit_a, unit_b)
	if e:
		e.remove_engagement()
		engagements.erase(e)
		SignalBus.on_ui_update.emit()

func remove_engagement_by_engagement(engagement: Engagement) -> void:
	for eng in engagements:
		if engagement == eng:
			eng.remove_engagement()
			engagements.erase(eng)
			SignalBus.on_ui_update.emit()


## Returns true if `unit` is in any Engagement.
func is_unit_engaged(unit: Unit) -> bool:
	for engagement in engagements:
		if engagement.unit_1 == unit or engagement.unit_2 == unit:
			return true
	return false


## Re-evaluate adjacency for a single unit and add/remove engagements.
func update_engagements_for_unit(changed_unit: Unit) -> void:
	return
	var opponents = UnitManager.instance.get_player_units()\
		if changed_unit.is_enemy\
		else UnitManager.instance.get_enemy_units()
	var adjacent = Utilities.get_adjacent_tiles_with_diagonal(changed_unit)
	
	for other in opponents:
		if adjacent.has(other.grid_position):
			add_engagement(changed_unit, other)
		else:
			remove_engagement(changed_unit, other)


func _on_unit_removed(unit: Unit) -> void:
	if !is_unit_engaged(unit):
		return
	
	var unit_engagements: Array[Engagement] = get_engagements(unit)
	
	for engagement in unit_engagements:
		remove_engagement_by_engagement(engagement)



#region Reach Queries

## True if `unit` holds the LONG reach advantage in any Engagement.
func is_at_longer_reach(unit: Unit) -> bool:
	for engagement in engagements:
		if (engagement.unit_1 == unit or engagement.unit_2 == unit)\
		and engagement.is_at_longer_reach(unit):
			return true
	return false


## True if `unit` holds the SHORT reach advantage in any Engagement.
func is_at_shorter_reach(unit: Unit) -> bool:
	for engagement in engagements:
		if (engagement.unit_1 == unit or engagement.unit_2 == unit)\
		and engagement.is_at_shorter_reach(unit):
			return true
	return false


## True if unit_a is at LONG reach vs. unit_b.
func is_unit_at_longer_reach_against(unit_a: Unit, unit_b: Unit) -> bool:
	var e = get_engagement(unit_a, unit_b)
	return e and e.is_at_longer_reach(unit_a)


## True if unit_a is at SHORT reach vs. unit_b.
func is_unit_at_shorter_reach_against(unit_a: Unit, unit_b: Unit) -> bool:
	var e = get_engagement(unit_a, unit_b)
	return e and e.is_at_shorter_reach(unit_a)

#endregion
