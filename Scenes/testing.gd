class_name Testing
extends Node3D

@export var unit: Unit
@onready var unit_action_system: UnitActionSystem = $"../UnitActionSystem"
@onready var unit_ai: UnitAI = $"../UnitAI"
@onready var pathfinding: Pathfinding = $"../Pathfinding"
@onready var camera = unit_action_system.camera
@onready var mouse_world: MouseWorld = $"../MouseWorld"
@onready var unit_stats_ui: UnitStatsUI = $"../UILayer/UnitStatsUI"

# Called every frame
func _process(_delta: float) -> void:
	test_pathfinding()
	handle_right_mouse_click()
	test_n()

# Testing function to visualize the path when a test key is pressed.
func test_pathfinding() -> void:
	if Input.is_action_just_pressed("testkey"):
		pathfinding.update_astar_walkable()
		# Get the grid position that the mouse is hovering over.
		var result = mouse_world.get_mouse_raycast_result("position")
		
		if result:
			var hovered_grid_position = pathfinding.pathfinding_grid_system.get_grid_position(result)
			
			if hovered_grid_position != null:
				# Find path from (0, 0) to the hovered grid position.
				var start_grid_position: GridPosition
				if unit_action_system.selected_unit:
					start_grid_position = unit_action_system.selected_unit.get_grid_position()
				elif start_grid_position == null:
					start_grid_position = pathfinding.pathfinding_grid_system.get_grid_position_from_coords(0, 0)
				var path = pathfinding.find_path(start_grid_position, hovered_grid_position)
				var cost = pathfinding.get_path_cost(start_grid_position, hovered_grid_position)
				# Print the path as a list of grid positions.
				for grid_position in path:
					pass
				print("Size: " + str(path.size()))
				print("Cost: " + str(cost))
				
				# Update the grid visual to show the path.
				GridSystemVisual.instance.update_grid_visual_pathfinding(path)

# Handles right mouse button click to disable grid object walkability and update pathfinding.
func handle_right_mouse_click() -> void:
	if Input.is_action_just_pressed("right_mouse"):
		# Get the grid position that the mouse is hovering over.
		var result = mouse_world.get_mouse_raycast_result("position")
		
		if result:
			var hovered_grid_position = pathfinding.pathfinding_grid_system.get_grid_position(result)
			
			if hovered_grid_position != null:
				# Get the grid object at the hovered position.
				var grid_object = pathfinding.pathfinding_grid_system.get_grid_object(hovered_grid_position)
				if grid_object:
					# Set the grid object to not walkable.
					grid_object.is_walkable = false
					
					# Update the AStar points in the pathfinding system.
					pathfinding.update_astar_walkable()
					print("Grid object at " + hovered_grid_position.to_str() + " is now not walkable.")

func test_n() -> void:
	if Input.is_action_just_pressed("testkey_n"):
		TurnSystem.instance.start_combat()



func apply_effect(att_name: String) -> void:
	# creating a new [GameplayEffect] resource
	var effect = GameplayEffect.new()
	# creating a new [AttributeEffect] resource
	var health_effect = AttributeEffect.new()
	
	health_effect.attribute_name = att_name
	health_effect.minimum_value = -2
	health_effect.maximum_value = -2

	
	effect.attributes_affected.append(health_effect)
	
	unit_action_system.selected_unit.add_child(effect)
