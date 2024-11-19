class_name Unit
extends Node3D

# Reference to the LevelGrid node.

@onready var action_system = $"../UnitActionSystem"

# The grid position of this unit.
var grid_position: GridPosition

# Reference to the action array node attached to this unit.
@onready var action_array: Array[Action]

const action_points_max: int = 2
@onready var action_points: int = action_points_max

@export var is_enemy: bool = false

@export var chest_point: Node3D

func _ready() -> void:
	# Initialize the unit's grid position based on its current world position.
	grid_position = LevelGrid.get_grid_position(global_transform.origin)
	# Register this unit at its grid position in the level grid.
	LevelGrid.set_unit_at_grid_position(grid_position, self)
	action_array = []
	for child in get_children():
		if child is Action:
			action_array.append(child)
	SignalBus.on_turn_changed.connect(on_turn_changed)

func _process(delta: float) -> void:
	# Update the unit's grid position if it has moved to a new grid cell.
	var new_grid_position = LevelGrid.get_grid_position(global_transform.origin)
	if new_grid_position != grid_position:
		# Notify the level grid that the unit has moved.
		LevelGrid.unit_moved_grid_position(self, grid_position, new_grid_position)
		grid_position = new_grid_position

func try_spend_action_points_to_take_action(action: Action) -> bool:
	if can_spend_action_points_to_take_action(action):
		spend_action_points(action.get_action_points_cost())
		return true
	return false

func can_spend_action_points_to_take_action(action: Action) -> bool:
	if action_points >= action.get_action_points_cost():
		return true
	else:
		return false

func spend_action_points(amount: int) -> void:
	action_points -= amount
	SignalBus.emit_signal("action_points_changed")

func damage() -> void:
	print_debug(self.get_name() + " damaged!")



# Will probably have to swap turn with round later
func on_turn_changed() -> void:
	if is_enemy and !TurnSystem.instance.is_player_turn or !is_enemy and TurnSystem.instance.is_player_turn:
		action_points = action_points_max
		SignalBus.emit_signal("action_points_changed")

# Setters and Getters
func _to_string() -> String:
	# Return the unit's name as a string representation.
	return self.name

func has_action(action_name: String) -> bool:
	for action in action_array:
		if action.get_action_name() == action_name:
			return true
	return false  # Return null if action not found

func get_animation_tree() -> AnimationTree:
	# Search for an AnimationTree node among the unit's children.
	for child in get_children():
		if child is AnimationTree:
			return child
	# Return null if no AnimationTree was found.
	return null

func get_grid_position() -> GridPosition:
	# Return the unit's current grid position.
	return grid_position

func get_world_position() -> Vector3:
	return global_position

func get_action_system() -> UnitActionSystem:
	# Return the UnitActionSystem reference.
	return action_system

func get_action_array() -> Array[Action]:
	# Return the array of actions attached to the unit.
	return action_array

func get_action_points() -> int:
	# Return the unit's action points.
	return action_points

func get_action(action_name: String) -> Action:
	for action in action_array:
		if action.get_action_name() == action_name:
			return action
	return null  # Return null if action not found

func get_target_position_with_offset(height_offset: float) -> Vector3:
	var target_position = global_position
	target_position.y += height_offset
	return target_position
