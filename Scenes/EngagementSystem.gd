# EngagementSystem.gd
extends Node
class_name EngagementSystem

# This array will track all current engagements
var engagements: Array = []

func _ready() -> void:
	engagements.clear()

# Generates engagements by checking all unit pairs
func generate_engagements() -> void:
	engagements.clear()
	var all_units = UnitManager.instance.get_all_units()
	
	for i in range(all_units.size()):
		for j in range(i + 1, all_units.size()):
			var unit_a = all_units[i]
			var unit_b = all_units[j]
			
			# Only engage if units are on opposing sides
			if unit_a.is_enemy == unit_b.is_enemy:
				continue
				
			# Check if unit_b is adjacent to unit_a (using diagonal adjacency)
			var adjacent_tiles = Utilities.get_adjacent_tiles_with_diagonal(unit_a)
			if adjacent_tiles.has(unit_b.grid_position):
				add_engagement(unit_a, unit_b)

# Returns true if an engagement already exists between the given units
func engagement_exists(unit_a: Unit, unit_b: Unit) -> bool:
	for engagement in engagements:
		if engagement.units.has(unit_a) and engagement.units.has(unit_b):
			return true
	return false

# Retrieve an existing engagement between two units (or null if none exists)
func get_engagement(unit_a: Unit, unit_b: Unit) -> Engagement:
	for engagement in engagements:
		if engagement.units.has(unit_a) and engagement.units.has(unit_b):
			return engagement
	return null

# Returns an array of opponents that are engaged with the given unit
func get_engaged_opponents(unit: Unit) -> Array:
	var ret_array: Array = []
	for engagement in engagements:
		if engagement.units.has(unit):
			for other_unit in engagement.units:
				if other_unit != unit and not ret_array.has(other_unit):
					ret_array.append(other_unit)
	return ret_array

# Adds an engagement if one does not already exist between unit_a and unit_b
func add_engagement(unit_a: Unit, unit_b: Unit) -> void:
	if not engagement_exists(unit_a, unit_b):
		var new_engagement = Engagement.new(unit_a, unit_b)
		# Pass "self" so the engagement can reference this node if needed.
		new_engagement.initialize_line(self)
		engagements.append(new_engagement)
		
		Utilities.spawn_text_line(unit_a, "Engaged")
		Utilities.spawn_text_line(unit_b, "Engaged")
		
		unit_a.animator.enable_head_look(unit_b.body.get_part_marker("head"))
		unit_b.animator.enable_head_look(unit_a.body.get_part_marker("head"))
		
		SignalBus.on_ui_update.emit()

# Removes an existing engagement between two units
func remove_engagement(unit_a: Unit, unit_b: Unit) -> void:
	var engagement: Engagement = get_engagement(unit_a, unit_b)
	if engagement:
		engagement.remove_engagement()
		engagements.erase(engagement)
		SignalBus.on_ui_update.emit()

# Checks if the specified unit is currently in any engagement
func is_unit_engaged(unit: Unit) -> bool:
	for engagement in engagements:
		if engagement.units.has(unit):
			return true
	return false

# Updates engagements when a unit changes grid position
func update_engagements_for_unit(changed_unit: Unit) -> void:
	var opposing_units: Array = []
	if changed_unit.is_enemy:
		opposing_units = UnitManager.instance.get_player_units()
	else:
		opposing_units = UnitManager.instance.get_enemy_units()
	
	var adjacent_tiles = Utilities.get_adjacent_tiles_with_diagonal(changed_unit)
	
	for other_unit in opposing_units:
		if adjacent_tiles.has(other_unit.grid_position):
			add_engagement(changed_unit, other_unit)
		else:
			remove_engagement(changed_unit, other_unit)
