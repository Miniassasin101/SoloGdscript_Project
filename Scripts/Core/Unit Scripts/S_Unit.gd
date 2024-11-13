# Unit.gd
# Base class for all units in combat.

class_name Unit
extends Node3D

# Reference to the LevelGrid node.
@onready var level_grid: LevelGrid = LevelGrid#$"../LevelGrid"
@onready var action_system: UnitActionSystem = $"../UnitActionSystem"

# The grid position of this unit.
var grid_position: GridPosition

# Reference to the MoveAction node attached to this unit.
@onready var move_action: MoveAction = $MoveAction


func _ready() -> void:
	# Initialize the unit's grid position based on its current world position.
	grid_position = level_grid.get_grid_position(global_transform.origin)
	# Register this unit at its grid position in the level grid.
	level_grid.set_unit_at_grid_position(grid_position, self)


func _process(delta: float) -> void:
	# Update the unit's grid position if it has moved to a new grid cell.
	var new_grid_position = level_grid.get_grid_position(global_transform.origin)
	if new_grid_position != grid_position:
		# Notify the level grid that the unit has moved.
		level_grid.unit_moved_grid_position(self, grid_position, new_grid_position)
		grid_position = new_grid_position

func _to_string() -> String:
	# Return the unit's name as a string representation.
	return self.name

func get_move_action() -> MoveAction:
	# Return the unit's MoveAction component.
	return move_action

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

func get_level_grid() -> LevelGrid:
	# Return the LevelGrid reference.
	return level_grid

func get_action_system() -> UnitActionSystem:
	return action_system
