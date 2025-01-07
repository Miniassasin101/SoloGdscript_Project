class_name Unit
extends Node3D

# Reference to the LevelGrid node.

var action_system: UnitActionSystem

@export_category("References")
@export var skeleton: Skeleton3D
@export var animator: UnitAnimator
@export var body: Body #abstract of stats and health of each limb
@export var inventory: Inventory
@export var equipment: Equipment

@export_category("Sockets")
@export var right_hand_socket: Node3D
@export var shoot_point: Node3D

@export_category("Head Look")
@export var neck_target: Marker3D
@export var look_target: Node3D
var new_rotation: Quaternion
## Should stay between 0 and 180 usually
@export var max_horizontal_angle: int = 90
@export var max_vertical_angle: int = 20
var bone_smooth_rot




@export_category("")
var ability_container: AbilityContainer
var attribute_map: GameplayAttributeMap
var unit_manager: UnitManager = get_parent()
# The grid position of this unit.
var grid_position: GridPosition
var is_holding: bool = false
var unit_name: String = "null"
# Reference to the action array node attached to this unit.
@onready var action_array: Array[Action]
var target_unit: Unit

@export var action_points_max: int = 2
@onready var action_points: int = action_points_max

@export var is_enemy: bool = false

# Replace with string of weapon group later or a check if holding weapon to determine what anim to use
@export var holding_weapon: bool = true

@export var death_vfx_scene: PackedScene

@export var shoulder_height: float = 1.7

var facing: int = 2

var target: Unit = null

var testbool: bool = false

func _ready() -> void:
	unit_manager = get_parent()
	action_system = unit_manager.unit_action_system
	# Initialize the unit's grid position based on its current world position.
	grid_position = LevelGrid.get_grid_position(global_transform.origin)
	# Register this unit at its grid position in the level grid.
	LevelGrid.set_unit_at_grid_position(grid_position, self)
	set_facing()
	action_array = []
	for child in get_children():
		if child is Action:
			action_array.append(child)
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
	SignalBus.on_turn_changed.connect(on_turn_changed)
	SignalBus.on_round_changed.connect(on_round_changed)
	SignalBus.add_unit.emit(self)




func _process(delta: float) -> void:
	# Update the unit's grid position if it has moved to a new grid cell.
	var new_grid_position: GridPosition = LevelGrid.get_grid_position(global_transform.origin)
	if new_grid_position != grid_position:
		# Notify the level grid that the unit has moved.
		LevelGrid.unit_moved_grid_position(self, grid_position, new_grid_position)
		grid_position = new_grid_position
	if testbool:
		look_at_object(delta)


func look_at_target(target: Node3D, bone_name: String = "DEF_neck.001", clamp_angle: float = 55.0, interpolation_time: float = 0.2) -> void:
	"""
	Makes the specified bone (default: Head) look at the target node.
	Parameters:
		- target: The node to look at (Node3D).
		- bone_name: The name of the bone to rotate (default: "Head").
		- clamp_angle: The maximum angle the head can turn (in degrees).
		- interpolation_time: The time (in seconds) for smooth rotation.
	"""
	if not is_instance_valid(target) or skeleton == null:
		print_debug("Invalid target or missing skeleton.")
		return

	# Get the current position of the bone in world space
	var bone_global_transform = skeleton.get_bone_global_pose(skeleton.find_bone(bone_name))
	var bone_world_position = bone_global_transform.origin

	# Get the target's world position
	var target_position = target.global_transform.origin

	# Calculate the direction vector to the target
	var look_direction = (target_position - bone_world_position).normalized()

	# Calculate the current bone's forward direction
	var current_bone_forward = bone_global_transform.basis.z.normalized()

	# Calculate the angle between the current direction and the look direction
	var angle_to_target = rad_to_deg(acos(current_bone_forward.dot(look_direction)))

	# Clamp the rotation angle to the maximum allowed (clamp_angle)
	if angle_to_target > clamp_angle:
		print_debug("Clamping head rotation.")
		var axis_of_rotation = current_bone_forward.cross(look_direction).normalized()
		look_direction = current_bone_forward.rotated(axis_of_rotation, deg_to_rad(clamp_angle))

	# Compute the desired rotation
	var look_at_transform = Transform3D()
	look_at_transform.origin = bone_world_position
	look_at_transform.basis = Basis().looking_at(look_direction, Vector3.UP)

	# Apply interpolation for smooth rotation
	var interpolated_basis = bone_global_transform.basis.slerp(look_at_transform.basis, clamp(1.0 / interpolation_time, 0, 1))
	var bonename: String = skeleton.get_bone_name(skeleton.find_bone(bone_name))
	# Apply the new rotation to the bone
	bone_global_transform.basis = interpolated_basis
	skeleton.set_bone_global_pose(skeleton.find_bone(bone_name), bone_global_transform)

func look_at_object(delta: float):
	var neck_bone = skeleton.find_bone("DEF_neck.001")
	neck_target.look_at(look_target.global_position, Vector3.UP, true)
	new_rotation = Quaternion.from_euler(neck_target.rotation)
	skeleton.set_bone_pose_rotation(neck_bone, new_rotation)


func update_weapon_anims() -> void:
	animator.weapon_setup(holding_weapon)


func try_spend_action_points_to_take_action(action: Action) -> bool:
	if can_spend_action_points_to_take_action(action):
		spend_action_points(action.get_action_points_cost())
		return true
	return false

func try_spend_ability_points_to_use_ability(ability: Ability) -> bool:
	if can_spend_ability_points_to_use_ability(ability):
		spend_ability_points(ability.ap_cost)
		return true
	return false

func can_spend_action_points_to_take_action(action: Action) -> bool:
	if action_points >= action.get_action_points_cost():
		return true
	else:
		return false

func can_spend_ability_points_to_use_ability(ability: Ability) -> bool:
	var ap_remain: int = int(attribute_map.get_attribute_by_name("action_points").current_value)
	# Replace action points with ability points later
	if ap_remain >= ability.ap_cost:
		return true
	else:
		return false


func spend_action_points(amount: int) -> void:

	action_points -= amount
	SignalBus.emit_signal("action_points_changed")
	SignalBus.emit_signal("update_stat_bars")

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

# Will probably have to swap turn with round later
func on_turn_changed() -> void:
	if is_enemy and !TurnSystem.instance.is_player_turn or !is_enemy and TurnSystem.instance.is_player_turn:
		action_points = action_points_max
		
		SignalBus.emit_signal("action_points_changed")
		SignalBus.emit_signal("update_stat_bars")

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

func get_action_array() -> Array[Action]:
	# Return the array of actions attached to the unit.
	return action_array

func get_action_points() -> int:
	# Return the unit's action points.
	return action_points

func get_action(action_name: String) -> Action:
	for action in action_array:
		if action.get_action_name() == action_name:
			return action
	return null  # Return null if action not found

func get_target_position_with_offset(height_offset: float) -> Vector3:
	var target_position = global_position
	target_position.y += height_offset
	return target_position


func set_facing() -> void:
	"""
	Sets the facing variable based on the unit's current rotation.
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
