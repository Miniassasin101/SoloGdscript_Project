class_name Unit
extends Node3D

## Unit base class that contains functionality general to all units in combat.
@onready var level_grid: LevelGrid = $"../LevelGrid"

var grid_position: GridPosition
@onready var move_action: MoveAction = $MoveAction

func _ready() -> void:
	grid_position = level_grid.get_grid_position(global_transform.origin)
	level_grid.set_unit_at_grid_position(grid_position, self)


# Called every frame. 'delta' is the time passed since the previous frame
func _process(delta: float) -> void:
	var new_grid_position = level_grid.get_grid_position(global_transform.origin)
	if new_grid_position != grid_position:
		level_grid.unit_moved_grid_position(self, grid_position, new_grid_position)
		grid_position = new_grid_position
		pass

func _to_string() -> String:
	return self.name

func get_move_action():
	return move_action

func get_animation_tree() -> AnimationTree:
	# Look for an AnimationTree node within this unit's children
	for child in get_children():
		if child is AnimationTree:
			return child
	
	# Return null if no AnimationTree was found
	return null

func get_grid_position():
	return grid_position

func get_level_grid() -> LevelGrid:
	return level_grid
