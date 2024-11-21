class_name Testing
extends Node3D

@export var unit: Unit
@onready var unit_action_system: UnitActionSystem = $"../UnitActionSystem"
@onready var unit_ai: UnitAI = $"../UnitAI"
@onready var pathfinding: Pathfinding = $"../Pathfinding"
@onready var camera = unit_action_system.camera
@onready var mouse_world: MouseWorld = $"../MouseWorld"

# Called when the node enters the scene tree for the first time.
func _process(_delta: float) -> void:
	test_pathfinding()
# Testing function to visualize the path when a test key is pressed.
func test_pathfinding() -> void:
	if Input.is_action_just_pressed("testkey"):
		# Get the grid position that the mouse is hovering over.
		var result = mouse_world.get_mouse_raycast_result("position")
		
		if result:
			var hovered_grid_position = pathfinding.pathfinding_grid_system.get_grid_position(result)
			
			if hovered_grid_position != null:
				# Find path from (0, 0) to the hovered grid position.
				#var start_grid_position = pathfinding.pathfinding_grid_system.get_grid_position_from_coords(0, 0)
				var start_grid_position: GridPosition
				if unit_action_system.selected_unit:
					start_grid_position = unit_action_system.selected_unit.get_grid_position()
				elif start_grid_position == null:
					start_grid_position = pathfinding.pathfinding_grid_system.get_grid_position_from_coords(0, 0)
				var path = pathfinding.find_path(start_grid_position, hovered_grid_position)
				var cost = pathfinding.get_path_cost(start_grid_position, hovered_grid_position)
				# Print the path as a list of grid positions.
				for grid_position in path:
					#print(grid_position.to_str())
					pass
				print("Size: " + str(path.size()))
				print("Cost: " + str(cost))
				
				# Update the grid visual to show the path.
				GridSystemVisual.instance.update_grid_visual_pathfinding(path)
