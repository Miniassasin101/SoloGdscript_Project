class_name Unit
extends Node3D


# Signals
signal facing_changed(new_facing: int)



# Variables
var action_system: UnitActionSystem

@export_category("References")
@export var skeleton: Skeleton3D
@export var animator: UnitAnimator
@export var body: Body #abstract of stats and health of each limb
@export var inventory: Inventory
@export var equipment: Equipment
@export var color_marker: ColorMarker

@export_category("Sockets")
@export var right_hand_socket: Node3D
@export var shoot_point: Node3D




@export_category("")
var ability_container: AbilityContainer
var attribute_map: GameplayAttributeMap
var unit_manager: UnitManager = get_parent()
# The grid position of this unit.
var grid_position: GridPosition:
	set(val):
		print_debug("New Grid Position: ", val.to_str())
		grid_position = val
var is_holding: bool = false
@export var unit_name: String = "null"
# Reference to the action array node attached to this unit.
var target_unit: Unit


@export var is_enemy: bool = false

# Replace with string of weapon group later or a check if holding weapon to determine what anim to use
@export var holding_weapon: bool = true
@export var death_vfx_scene: PackedScene
@export var shoulder_height: float = 1.7
var facing: int = 2:
	set(val):
		facing = val
		facing_changed.emit(facing)
var target: Unit = null
var testbool: bool = false


# Movement Variables
var current_gait: int = Utilities.MovementGait.HOLD_GROUND
var distance_moved_this_turn: float = 0.0
var movement_done_in_first_cycle: bool = false
var movement_done_in_second_cycle: bool = false

# Ability Variables
## Is the first ability used in the round. Determines possible movement gaits for the rest of the round
var previous_ability: Ability = null



# Methods

func _ready() -> void:
	unit_manager = get_parent()
	action_system = unit_manager.unit_action_system
	# Initialize the unit's grid position based on its current world position.
	grid_position = LevelGrid.get_grid_position(global_transform.origin)
	# Register this unit at its grid position in the level grid.
	LevelGrid.set_unit_at_grid_position(grid_position, self)
	set_facing()

	for child in get_children():
		if child is AbilityContainer:
			ability_container = child
		if child is GameplayAttributeMap:
			attribute_map = child
		if child is Inventory:
			inventory = child
		if child is Equipment:
			equipment = child
	attribute_map.attribute_changed.connect(on_attribute_changed)
	animator.weapon_setup(holding_weapon)
	SignalBus.on_round_changed.connect(on_round_changed)
	SignalBus.on_cycle_changed.connect(on_reset_distance_moved)
	SignalBus.add_unit.emit(self)




func _process(delta: float) -> void:
	# Update the unit's grid position if it has moved to a new grid cell.
	var new_grid_position: GridPosition = LevelGrid.get_grid_position(global_transform.origin)
	if new_grid_position != grid_position:
		# Notify the level grid that the unit has moved.
		LevelGrid.unit_moved_grid_position(self, grid_position, new_grid_position)
		grid_position = new_grid_position


func update_weapon_anims() -> void:
	animator.weapon_setup(holding_weapon)


func try_spend_ability_points_to_use_ability(ability: Ability) -> bool:
	if can_spend_ability_points_to_use_ability(ability):
		spend_ability_points(ability.ap_cost)
		return true
	return false


func can_spend_ability_points_to_use_ability(ability: Ability) -> bool:
	var ap_remain: int = int(attribute_map.get_attribute_by_name("action_points").current_value)
	# Replace action points with ability points later
	if ap_remain >= ability.ap_cost:
		return true
	else:
		return false



func spend_ability_points(amount: int) -> void:
	attribute_map.get_attribute_by_name("action_points").current_value -= amount
	# Note: Change to ability points later
	SignalBus.emit_signal("action_points_changed")
	SignalBus.emit_signal("update_stat_bars")




func on_dead() -> void:
	var death_effect = death_vfx_scene.instantiate() as Node3D
	get_tree().root.add_child(death_effect)
	death_effect.global_transform.origin = self.global_position
	if death_effect.get_child_count() > 0 and death_effect.get_child(0) is GPUParticles3D:
		death_effect.get_child(0).emitting = true
	LevelGrid.remove_unit_at_grid_position(grid_position, self)
	SignalBus.remove_unit.emit(self)
	
	queue_free()

func on_attribute_changed(_attribute: AttributeSpec):
	SignalBus.emit_signal("update_stat_bars")
	if attribute_map.get_attribute_by_name("health").current_value <= 0:
		on_dead()

func on_reset_distance_moved() -> void:
	set_distance_moved(0.0)

func on_round_changed() -> void:
	attribute_map.get_attribute_by_name("action_points").current_value = attribute_map.get_attribute_by_name("action_points").maximum_value
	SignalBus.emit_signal("action_points_changed")
	SignalBus.emit_signal("update_stat_bars")

# Setters and Getters
func _to_string() -> String:
	# Return the unit's name as a string representation.
	return self.name


func has_ability(ability_name: StringName) -> bool:
	for ability: Ability in ability_container.granted_abilities:
		if ability.ui_name == ability_name:
			return true
	return false

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



func get_target_position_with_offset(height_offset: float) -> Vector3:
	var target_position = global_position
	target_position.y += height_offset
	return target_position

func get_movement_rate() -> float:
	return attribute_map.get_attribute_by_name("movement_rate").current_buffed_value

func get_max_move_left() -> float:
	var move_rate = attribute_map.get_attribute_by_name("movement_rate").current_buffed_value
	var speed_multiplier = Utilities.GAIT_SPEED_MULTIPLIER.get(current_gait)
	return ((move_rate * speed_multiplier)/2) - distance_moved_this_turn


func set_distance_moved(val: float) -> void:
	distance_moved_this_turn = val

func add_distance_moved(val: float) -> void:
	distance_moved_this_turn += val
	

func set_gait(gait: int) -> void:
	current_gait = gait

func set_color_marker(color: StringName) -> void:
	color_marker.set_color(color)

func set_color_marker_visible(is_vis: bool) -> void:
	color_marker.set_visibility(is_vis)

func set_facing_then_rotate(in_facing: int) -> void:
	facing = in_facing
	animator.rotate_unit_towards_facing(in_facing)


func set_facing() -> void:
	"""
	Sets the facing variable based on the unit's current rotation.
	Values in parentheses assume unit is rotated 0 degrees.
	Facing values:
	- 0: 180 degrees (facing North(back))
	- 1: 90 degrees (facing East(left))
	- 2: 0 degrees (facing South(front))
	- 3: -90 degrees (facing West(right))
	"""
	# Get the unit's y-axis rotation in degrees
	var rotation_y = wrapf(rotation_degrees.y, 0.0, 360.0)

	# Map rotation to cardinal directions
	if rotation_y > 135.0 and rotation_y <= 225.0:
		facing = 0  # Facing backward
	elif rotation_y > 45.0 and rotation_y <= 135.0:
		facing = 1  # Facing right
	elif (rotation_y > 315.0 and rotation_y <= 360.0) or (rotation_y >= 0.0 and rotation_y <= 45.0):
		facing = 2  # Facing forward
	elif rotation_y > 225.0 and rotation_y <= 315.0:
		facing = 3  # Facing left

	print_debug("Unit facing direction set to: ", facing)
	facing_changed.emit(facing)
