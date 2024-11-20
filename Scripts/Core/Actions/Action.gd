class_name Action
extends Node

var is_active: bool
var unit: Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit = get_parent()


func take_action(_grid_position: GridPosition) -> void:
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
	for x in valid_grid_position_list:
		if x._equals(grid_position):
			return true
	return false


func action_start() -> void:
	is_active = true

func action_complete() -> void:
	is_active = false
	SignalBus.action_complete.emit()



# Gets a list of valid grid positions for movement.
func get_valid_action_grid_position_list() -> Array[GridPosition]:
	print_debug("get valid action grid position list on base Action class was called")
	return []

func get_action_name() -> String:
	return ""

func get_action_points_cost() -> int:
	return 1

func get_best_enemy_ai_action() -> EnemyAIAction:
	var enemy_ai_action_list: Array[EnemyAIAction] = []
	var valid_action_grid_position_list: Array[GridPosition] = get_valid_action_grid_position_list()
	for grid_position: GridPosition in valid_action_grid_position_list:
		var enemy_ai_action: EnemyAIAction = get_enemy_ai_action(grid_position)
		enemy_ai_action_list.append(enemy_ai_action)
	if !enemy_ai_action_list.is_empty():
		enemy_ai_action_list.sort_custom(func(a: EnemyAIAction, b: EnemyAIAction): return b.action_value - a.action_value)
		return enemy_ai_action_list[0]
	else:
		# No possible Enemy AI Actions
		return null

func get_enemy_ai_action(_grid_position: GridPosition) -> EnemyAIAction:
	push_error("get_enemy_ai_action on base Action class was called")
	return null
	


	
