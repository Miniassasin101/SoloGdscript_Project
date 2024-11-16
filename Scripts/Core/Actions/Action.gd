class_name Action
extends Node

var is_active: bool
var unit: Unit
var on_action_complete: Callable = Callable()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit = get_parent()


func take_action(grid_position: GridPosition) -> void:
	print_debug("Take action on base Action class was called")
	return

# Converts a list of GridPosition to a list of their string representations.
func position_list_to_strings(pos_list: Array) -> Array:
	var return_list = []
	for pos in pos_list:
		return_list.append(pos.to_str())
	return return_list

# Checks if the grid position is valid for movement.
func is_valid_action_grid_position(grid_position: GridPosition) -> bool:
	var valid_grid_position_list = get_valid_action_grid_position_list()
	var gridpos_str = grid_position.to_str()
	var valid_positions_str_list = position_list_to_strings(valid_grid_position_list)
	# Check if the grid position is in the list of valid positions.
	return valid_positions_str_list.has(gridpos_str)

# Gets a list of valid grid positions for movement.
func get_valid_action_grid_position_list() -> Array:
	print_debug("get valid action grid position list on base Action class was called")
	return []

func get_action_name() -> String:
	return ""

func get_action_points_cost() -> int:
	return 1
