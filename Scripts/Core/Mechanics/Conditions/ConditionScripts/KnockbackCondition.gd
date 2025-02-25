extends Condition
class_name KnockbackCondition

@export var knockback_distance: int = 1  # Number of grid tiles to push back

func apply(unit: Unit) -> void:
	# Determine the knockback direction.
	# Here we use the unit’s facing: we assume that knockback pushes the unit backward relative to its facing.
	# (Alternatively, you could calculate a direction vector based on the attacker’s position.)
	var knock_dir: Vector2 = Vector2.ZERO
	match unit.facing:
		0: knock_dir = Vector2(0, 1)   # Facing North: knock back toward South (increase z)
		1: knock_dir = Vector2(-1, 0)  # Facing East: knock back toward West (decrease x)
		2: knock_dir = Vector2(0, -1)  # Facing South: knock back toward North (decrease z)
		3: knock_dir = Vector2(1, 0)   # Facing West: knock back toward East (increase x)
	
	# Calculate the target grid position based on knockback distance.
	var current_grid = unit.get_grid_position()
	var target_grid = GridPosition.new(
		current_grid.x + int(knock_dir.x * knockback_distance),
		current_grid.z + int(knock_dir.y * knockback_distance)
	)
	
	# Check if the target grid is valid and not occupied by an impassable obstacle.
	if !LevelGrid.is_valid_grid_position(target_grid) or \
	LevelGrid.has_any_unit_on_grid_position(target_grid) or\
	!Pathfinding.instance.is_path_available(current_grid, target_grid):
		# If blocked, you might want the unit to fall prone instead.
		Utilities.spawn_text_line(unit, "Fell Prone", Color.FIREBRICK)
		# (Insert prone-handling logic here, e.g. unit.fall_prone())
		unit.conditions_manager.remove_condition(self)
		return
	
	# Get the target world position from the grid coordinates.
	var target_world_pos = LevelGrid.get_world_position(target_grid)
	
	# Create a tween to animate the unit’s movement.
	var tween = unit.get_tree().create_tween()
	tween.tween_property(unit, "global_position", target_world_pos, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_completed.bind(unit, target_grid))
	
	# Optionally, show a knockback message.
	Utilities.spawn_text_line(unit, "Knocked Back", Color.FIREBRICK)
	
func _on_tween_completed(unit: Unit, target_grid: GridPosition) -> void:
	# Update the unit’s grid position if needed.
	unit.grid_position = target_grid
	# Remove this condition once the tween is finished.
	unit.conditions_manager.remove_condition(self)
