class_name GridObject
extends RefCounted

var grid_system: GridSystem
var grid_position: GridPosition
var unitList: Array = []
# Called when the node enters the scene tree for the first time.
func _init(grid_system: GridSystem, grid_position: GridPosition) -> void:
	self.grid_system = grid_system
	self.grid_position = grid_position

func add_unit(inunit: Unit) -> void:
	self.unitList.append(inunit)

func remove_unit(inunit: Unit) -> void:
	if inunit in unitList:
		unitList.erase(inunit)

func get_unit_list():
	return unitList

func has_any_unit():
	return unitList.size() > 0



# Returns a string representation of the grid position and all units
func to_str() -> String:
	var result = grid_position.to_str()
	if unitList.size() > 0:
		for unit in unitList:
			result += "\n" + unit.to_string()
	return result
