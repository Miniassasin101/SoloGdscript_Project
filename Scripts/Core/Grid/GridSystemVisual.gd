class_name GridSystemVisual
extends Node3D

# The prefab for each grid cell's visual representation.
#const GRID_CELL_VISUAL: PackedScene = preload("res://Hero_Game/Prefabs/GridCellVisual.tscn")
@export var GRID_CELL_VISUAL: PackedScene
# 2D array to hold the visual instances of grid cells.
var grid_visuals: Array = []  # Array of Arrays of Node3D instances.

var highlighted_path: Array[GridSystemVisualSingle]

var selected_ability: Ability
# Singleton instance of GridSystemVisual.
static var instance: GridSystemVisual = null


# This variable will hold the currently hovered grid position (if any).
var currently_hovered: GridPosition = null


func _ready() -> void:
	# Ensure only one instance exists (singleton pattern).
	if instance != null:
		push_error("There's more than one GridSystemVisual! " + str(transform) + " - " + str(instance))
		queue_free()
		return
	instance = self
	SignalBus.update_grid_visual.connect(update_grid_visual)
	SignalBus.selected_unit_changed.connect(on_selected_unit_changed)
	initialize_grid_visuals()



func initialize_grid_visuals() -> void:
	# Ensure LevelGrid singleton is properly loaded.
	if not LevelGrid:
		push_error("LevelGrid singleton not found.")
		return

	# Get grid dimensions from LevelGrid.
	var grid_width: int = LevelGrid.get_width()
	var grid_height: int = LevelGrid.get_height()

	# Initialize the 2D array to match the dimensions of LevelGrid.
	grid_visuals.resize(grid_width)

	# Loop through the width and height of the grid.
	for x in range(grid_width):
		grid_visuals[x] = []  # Initialize each row as an empty array.
		for z in range(grid_height):
			# Create a new GridPosition based on x and z.
			var grid_position: GridPosition = GridPosition.new(x, z)

			# Instantiate the visual prefab.
			var cell_instance: GridSystemVisualSingle = GRID_CELL_VISUAL.instantiate()

			# Set the position of the cell in the world.
			cell_instance.transform.origin = LevelGrid.get_world_position(grid_position)

			# Add the instance as a child of this node.
			add_child(cell_instance)

			# Store the instance in the 2D array at position (x, z).
			grid_visuals[x].append(cell_instance)
			# Update visual for difficult terrain
			var grid_object = LevelGrid.grid_system.get_grid_object(grid_position)
			if grid_object.is_difficult_terrain:
				cell_instance.set_difficult_terrain(true)
			else:
				cell_instance.set_difficult_terrain(false)

func _process(_delta: float) -> void:
	pass



func set_hovered_cell(grid_position: GridPosition) -> void:
	if grid_position.equals(currently_hovered):
		return
	# Retrieve the cell instance from the grid_visuals 2D array.
	var cell: GridSystemVisualSingle = grid_visuals[grid_position.x][grid_position.z]
	if cell.is_hovered or !cell.visible:
		return
	if cell:
		var grid_object: GridObject = LevelGrid.get_grid_object(grid_position)
		var unit: Unit = grid_object.get_unit()
		var current_unit_turn: Unit = TurnSystem.instance.current_unit_turn
		if unit and current_unit_turn:
			if unit.is_enemy != current_unit_turn.is_enemy:
				cell._on_mouse_enter(Color.FIREBRICK)
			elif unit == TurnSystem.instance.current_unit_turn:
				cell._on_mouse_enter(Color.FOREST_GREEN)
			else:
				cell._on_mouse_enter(Color.AQUA)
		else:
			# Optionally, call the cell's on-mouse-enter behavior.
			cell._on_mouse_enter()
	# Also update the internal tracking variable if desired.
	currently_hovered = grid_position

func clear_hovered_cell(grid_position: GridPosition) -> void:

	var cell: GridSystemVisualSingle = grid_visuals[grid_position.x][grid_position.z]
	if cell:
		# Optionally, call the cell's on-mouse-exit behavior.
		cell._on_mouse_exit()
	currently_hovered = null


func cell_at_pos_is_visible(grid_position: GridPosition) -> bool:
	var vis_cell: GridSystemVisualSingle = get_cell_visual_from_gridpos(grid_position)
	return vis_cell.visible


func get_cell_visual_from_gridpos(grid_position: GridPosition) -> GridSystemVisualSingle:
	var x: int = grid_position.x
	var z: int = grid_position.z
	var grid_vis: GridSystemVisualSingle = grid_visuals[x][z]
	return grid_vis

func highlight_path(grid_positions: Array[GridPosition]) -> void:
	# First, clear any previous highlight.
	clear_highlights()
	
	var enemy_engagement_positions: Array[GridPosition] = (
		UnitManager.instance.get_enemy_adjacent_positions
		(TurnSystem.instance.current_unit_turn))
	
	var encounters_engagement: bool = false
	for grid_position in grid_positions:
		if !encounters_engagement:
			if enemy_engagement_positions.has(grid_position):
				encounters_engagement = true
		var x: int = grid_position.x
		var z: int = grid_position.z
		# Check bounds.
		if x >= 0 and x < LevelGrid.get_width() and z >= 0 and z < LevelGrid.get_height():
			var cell: GridSystemVisualSingle = grid_visuals[x][z]
			if cell:
				# If the movement would encounter an engagement make it red
				if encounters_engagement:
					cell.highlight(Color.RED)
					highlighted_path.append(cell)
					break
				# Set the cell color to light blue.
				else:
					cell.highlight()
					highlighted_path.append(cell)

func clear_highlights() -> void:
	for visual in highlighted_path:
		if visual.is_highlighted:
			visual.remove_highlight()



func on_selected_unit_changed(_unit: Unit) -> void:
	update_grid_visual()


func mark_red(grid_positions: Array[GridPosition]) -> void:
	# Iterate over all grid positions
	for grid_position in grid_positions:
		var x: int = grid_position.x
		var z: int = grid_position.z

		# Check if the grid position is within bounds
		if x >= 0 and x < LevelGrid.get_width() and z >= 0 and z < LevelGrid.get_height():
			var cell: GridSystemVisualSingle = grid_visuals[x][z]
			if cell != null:
				cell.update_visual(true)  # Mark the cell as red

func unmark_red(grid_positions: Array[GridPosition]) -> void:
	# Iterate over all grid positions
	for grid_position in grid_positions:
		var x: int = grid_position.x
		var z: int = grid_position.z

		# Check if the grid position is within bounds
		if x >= 0 and x < LevelGrid.get_width() and z >= 0 and z < LevelGrid.get_height():
			var cell: GridSystemVisualSingle = grid_visuals[x][z]
			if cell != null:
				cell.update_visual(false)  # Mark the cell as red

func hide_all_grid_positions() -> void:
	# Hide all grid cell visuals.
	for row in grid_visuals:
		for cell: GridSystemVisualSingle in row:
			cell.visible = false

func show_grid_positions(grid_positions: Array) -> void:
	# Show specified grid cell visuals.
	for grid_position in grid_positions:
		var x: int = grid_position.x
		var z: int = grid_position.z
		# Check if the position is within grid bounds.
		if x >= 0 and x < LevelGrid.get_width() and z >= 0 and z < LevelGrid.get_height():
			grid_visuals[x][z].visible = true

func hide_grid_positions(grid_positions: Array) -> void:
	# Show specified grid cell visuals.
	for grid_position in grid_positions:
		var x: int = grid_position.x
		var z: int = grid_position.z
		# Check if the position is within grid bounds.
		if x >= 0 and x < LevelGrid.get_width() and z >= 0 and z < LevelGrid.get_height():
			grid_visuals[x][z].visible = false




func update_grid_visual_pathfinding(grid_list: Array[GridPosition]):
	if !grid_list.is_empty():
		hide_all_grid_positions()
		show_grid_positions(grid_list)
		

func update_grid_visual() -> void:

	hide_all_grid_positions()
	
	var unit: Unit

	selected_ability = UnitActionSystem.instance.get_selected_ability()
	if selected_ability != null:
		"""
		if selected_ability.tags_type.has("reaction"):
			unit = CombatSystem.instance.current_event.target_unit
			#show_grid_positions(selected_ability.get_valid_ability_target_grid_position_list())
		else:
			unit = UnitActionSystem.instance.selected_unit
		"""
		if UnitActionSystem.instance.is_reacting:
			unit = CombatSystem.instance.current_event.target_unit
		else:
			unit = UnitActionSystem.instance.selected_unit

		if unit != null:
			show_grid_positions(unit.ability_container.
			get_valid_ability_target_grid_position_list(selected_ability))
