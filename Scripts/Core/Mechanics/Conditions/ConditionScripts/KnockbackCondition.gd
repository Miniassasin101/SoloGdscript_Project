extends Condition
class_name KnockbackCondition

@export var knockback_distance: int = 1  # Number of grid tiles to push back

@export var staggered_condition: StaggeredCondition = null

var knockback_direction = -1


func apply(unit: Unit) -> void:
	# Determine the knockback direction.
	# Here we use the unit’s facing: we assume that knockback pushes the unit backward relative to its facing.
	# (Alternatively, you could calculate a direction vector based on the attacker’s position.)
	var knock_dir: Vector2 = Vector2.ZERO
	if knockback_direction == -1:
		match unit.facing:
			0: knock_dir = Vector2(0, 1)   # Facing North: knock back toward South (increase z)
			1: knock_dir = Vector2(-1, 0)  # Facing East: knock back toward West (decrease x)
			2: knock_dir = Vector2(0, -1)  # Facing South: knock back toward North (decrease z)
			3: knock_dir = Vector2(1, 0)   # Facing West: knock back toward East (increase x)
	else:
		match knockback_direction:
			2: knock_dir = Vector2(0, 1)
			3: knock_dir = Vector2(-1, 0)
			0: knock_dir = Vector2(0, -1)  
			1: knock_dir = Vector2(1, 0)   
	# Calculate the target grid position based on knockback distance.
	var current_grid = unit.get_grid_position()
	var target_grid = GridPosition.new(
		current_grid.x + int(knock_dir.x * knockback_distance),
		current_grid.z + int(knock_dir.y * knockback_distance)
	)
	
	# Check if the target grid is valid and not occupied by an impassable obstacle.
	#if !LevelGrid.is_valid_grid_position(target_grid) or \
	#LevelGrid.has_any_unit_on_grid_position(target_grid):
	#	# If blocked, you might want the unit to fall prone instead.
	#	Utilities.spawn_text_line(unit, "Fell Prone", Color.FIREBRICK)
	#	# (Insert prone-handling logic here, e.g. unit.fall_prone())
	#	unit.conditions_manager.remove_condition(self)
	#	return
	
	
	var path: Array[GridPosition] = Pathfinding.instance.find_path_ignoring_obstacles(current_grid, target_grid)
	path.remove_at(0)
	var previous_gridpos: GridPosition = current_grid
	
	if path.is_empty():
		var stag_cond: StaggeredCondition = staggered_condition.duplicate()
		unit.conditions_manager.add_condition(stag_cond)
		Utilities.spawn_text_line(unit, "Staggered", Color.FIREBRICK)
		unit.conditions_manager.remove_condition(self)
		return
	
	for gridpos in path:
		# FIXME: Add wall logic here later
		if !Pathfinding.instance.is_walkable(gridpos) or LevelGrid.has_any_unit_on_grid_position(gridpos):
			target_grid = previous_gridpos
			var stag_cond: StaggeredCondition = staggered_condition.duplicate()
			unit.conditions_manager.add_condition(stag_cond)
			Utilities.spawn_text_line(unit, "Staggered", Color.FIREBRICK)
			break
		else:
			previous_gridpos = gridpos
			#target_grid = previous_gridpos
		
	if target_grid.equals(current_grid):
		Utilities.spawn_text_line(unit, "Knocked Back", Color.FIREBRICK)
		unit.conditions_manager.remove_condition(self)
		return
	
	# Get the target world position from the grid coordinates.
	var target_world_pos = LevelGrid.get_world_position(previous_gridpos)
	
	# Create a tween to animate the unit’s movement.
	var tween = unit.get_tree().create_tween()
	tween.tween_property(unit, "global_position", target_world_pos, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_completed.bind(unit, target_grid))
	
	# Optionally, show a knockback message.
	Utilities.spawn_text_line(unit, "Knocked Back", Color.FIREBRICK)
	
func _on_tween_completed(unit: Unit, _target_grid: GridPosition) -> void:
	# Update the unit’s grid position if needed.
	#unit.grid_position = target_grid
	# Remove this condition once the tween is finished.
	unit.conditions_manager.remove_condition(self)
