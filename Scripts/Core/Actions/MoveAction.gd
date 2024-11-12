class_name MoveAction
extends Node

# Target position is a Vector3, not a Basis
var target_position: Vector3
@export var max_move_distance: int = 3
@onready var mouse_world: MouseWorld = $"../MouseWorld"
@onready var unit = get_parent()
@onready var unit_transform = get_parent().global_transform
@onready var level_grid: LevelGrid = unit.get_level_grid()
@onready var animation_tree: AnimationTree = get_parent().get_animation_tree()

# Movement speed of the unit
const MOVE_SPEED: float = 4.0
# Distance threshold to stop moving when close to the target
const STOPPING_DISTANCE: float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target_position = unit_transform.origin  # Initialize target position to the unit's current position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move towards the target position if the unit is far enough
	move_towards_target(delta)
	unit_transform = get_parent().global_transform

# Moves the unit towards the target position
func move_towards_target(delta: float) -> void:
	# Only move if the unit is farther than the stopping distance from the target
	var current_position = unit.global_transform.origin
	if current_position.distance_to(target_position) > STOPPING_DISTANCE:
		# Calculate the movement direction
		var move_direction: Vector3 = (target_position - current_position).normalized()

		# Move towards the target by updating the position
		current_position += move_direction * MOVE_SPEED * delta
		unit.global_transform.origin = current_position  # Update the unit's position

		# Smoothly rotate the unit towards the movement direction
		var target_rotation = Basis.looking_at(-move_direction, Vector3.UP)
		var rotate_speed: float = 8.0
		unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)

		# Set the walking animation condition
		animation_tree.set("parameters/conditions/IsWalking", true)
	else:
		# If not moving, set the walking condition to false
		animation_tree.set("parameters/conditions/IsWalking", false)

# Updates the target position based on the raycast from the mouse click
func update_target_position() -> void:
	# Perform raycast by calling the non-static function in the MouseWorld instance
	var result: Dictionary = mouse_world.get_mouse_position()
	
	# If raycast hit an object, update the unit's target position
	if result.size() > 0 and result.has("position"):
		move(result["position"])

# Sets a new target position for the unit
func move(grid_position: GridPosition) -> void:
	print("testing123")
	self.target_position = level_grid.get_world_position(grid_position)

func is_valid_action_grid_position(grid_position: GridPosition) -> bool:
	var valid_grid_position_list = get_valid_action_grid_position_list()
	if valid_grid_position_list.has(grid_position):
		return true
	else:
		return false
	


func get_valid_action_grid_position_list() -> Array:
	var valid_grid_position_list: Array[GridPosition] = []  # Initialize an empty array for valid grid positions
	var unit_grid_position: GridPosition = unit.get_grid_position()
	level_grid = unit.get_level_grid()
	# Loop through the x and z ranges based on maxMoveDistance
	for x in range(-max_move_distance, max_move_distance + 1):
		for z in range(-max_move_distance, max_move_distance + 1):
			# Create a new GridPosition with the current x and z values
			var offset_grid_position = GridPosition.new(x, z)
			var test_grid_position: GridPosition = unit_grid_position.add(offset_grid_position)
			
			if not level_grid.is_valid_grid_position(test_grid_position):
				continue
			
			if unit_grid_position.equals(test_grid_position):
				#same grid position that its already at
				continue
			
			if (level_grid.has_any_unit_on_grid_position(test_grid_position)):
				#Grid Position already occupied
				continue
				
			valid_grid_position_list.append(test_grid_position)
	
	return valid_grid_position_list
