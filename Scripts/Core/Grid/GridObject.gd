# GridObject.gd
# Represents a cell in the grid and contains units located at that grid position.

class_name GridObject
extends RefCounted

# Reference to the GridSystem.
var grid_system: GridSystem

# The grid position of this GridObject.
var grid_position: GridPosition

var is_walkable: bool = true

# Whether this grid cell is difficult terrain.
var is_difficult_terrain: bool = false  # New property

# List of units on this grid cell.
var unit_list: Array[Unit] = []

var item_list: Array[Item] = []

func _init(ingrid_system: GridSystem, ingrid_position: GridPosition) -> void:
	grid_system = ingrid_system
	grid_position = ingrid_position


func get_grid_position() -> GridPosition:
	return grid_position

func set_difficult_terrain(difficult: bool) -> void:
	is_difficult_terrain = difficult

func get_movement_cost() -> int:
	return 2 if is_difficult_terrain else 1  # Double cost for difficult terrain

func add_item(item: Item) -> void:
	item_list.append(item)

func remove_item(item: Item) -> void:
	item_list.erase(item)

func get_first_item() -> Item:
	if item_list.is_empty():
		return null
	return item_list[0]

func has_any_item() -> bool:
	if item_list.size() > 0:
		return true
	return false

# Adds a unit to this grid cell.
func add_unit(unit: Unit) -> void:
	self.unit_list.append(unit)

# Removes a unit from this grid cell.
func remove_unit(unit: Unit) -> void:
	unit_list.erase(unit)

# Returns the list of units on this grid cell.
func get_unit_list() -> Array:
	return unit_list

# Checks if there is any unit on this grid cell.
func has_any_unit() -> bool:
	return unit_list.size() > 0

func get_unit() -> Unit:
	if has_any_unit():
		return unit_list[0]
	else:
		return null

# Returns a string representation of the grid position and units.
func to_str() -> String:
	var result = grid_position.to_str()
	if unit_list.size() > 0:
		for unit in unit_list:
			result += "\n" + unit.ui_name
		return result
	return result
