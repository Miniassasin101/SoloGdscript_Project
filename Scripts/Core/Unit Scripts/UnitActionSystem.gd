class_name UnitActionSystem
extends Node

# Reference to the currently selected unit
@export var selected_unit: Unit

@onready var selected_action: Action
# Reference to the LevelGrid node
@onready var level_grid: LevelGrid = LevelGrid

# Reference to the MouseWorld instance (set in the editor)
@export var mouse_world: MouseWorld

# Reference to the RayCast3D node (set in the editor)
@export var raycast: RayCast3D

# Self-reference for signal emission
@onready var unit_action_system: UnitActionSystem = self



# Reference to the active Camera3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()

var is_busy: bool

static var instance: UnitActionSystem = null


func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitActionSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	if selected_unit:
		set_selected_unit(selected_unit)
	
	SignalBus.selected_action_changed.connect(set_selected_action)
	SignalBus.action_complete.connect(clear_busy)



func _process(delta: float) -> void:
	if is_busy:
		return

	# Check if the mouse is over a specific UI element
	var hovered_control = get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		return

	if Input.is_action_just_pressed("left_mouse"):
		# Attempt to select a unit
		if try_handle_unit_selection():
			return
		else:
			handle_selected_action()


func handle_selected_action() -> void:
	if selected_unit and selected_action:
		var mouse_grid_position = mouse_world.get_mouse_raycast_result("position")
		if mouse_grid_position:
			var grid_position: GridPosition = level_grid.get_grid_position(mouse_grid_position)
			if selected_action.is_valid_action_grid_position(grid_position):
				selected_action.take_action(grid_position)
				set_busy()

# Handles unit selection via mouse click
func try_handle_unit_selection() -> bool:
	# Get the mouse position in screen coordinates
	var mouse_position: Vector2 = get_viewport().get_mouse_position()

	# Perform raycast to detect units
	var collider = mouse_world.get_mouse_raycast_result("collider")

	# Check if the raycast hit something
	if collider != null:
		var unit = collider.get_parent()
		if unit is Unit and unit != selected_unit:
			# Select the unit
			set_selected_unit(unit)
			return true
		else:
			return false
	else:
		return false


func set_busy() -> void:
	is_busy = true

func clear_busy() -> void:
	print("clearbusy")
	is_busy = false

# Sets the selected unit and emits a signal
func set_selected_unit(unit: Unit) -> void:
	selected_unit = unit
	set_selected_action(unit.get_move_action())
	SignalBus.selected_unit_changed.emit(unit)

func set_selected_action(action: Action) -> void:
	print_debug(action.get_action_name())
	selected_action = action
	
# Retrieves the currently selected unit
func get_selected_unit() -> Unit:
	return selected_unit

#Retrieves current selected action
func get_selected_action() -> Action:
	return selected_action
