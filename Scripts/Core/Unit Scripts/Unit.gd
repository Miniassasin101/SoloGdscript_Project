class_name Unit
extends Node3D


# Signals
signal facing_changed(new_facing: int)
signal gait_changed(new_gait: int)



# Variables
var action_system: UnitActionSystem

@export var ui_name: String = "null"
@export_category("References")
@export var skeleton: Skeleton3D
@export var animator: UnitAnimator
@export var body: Body #abstract of stats and health of each limb
@export var inventory: Inventory
@export var equipment: Equipment
@export var color_marker: ColorMarker
@export var chest_marker: Marker3D
@export var above_marker: Marker3D
@export var conditions_manager: ConditionsManager

@export var hair_tufts: MeshInstance3D

@export_category("Sockets")
@export var left_hand_socket: Node3D
@export var right_hand_socket: Node3D
@export var shoot_point: Node3D




@export_category("")
@export var weapons_equip_combat_start: Array[Weapon] = []


var ability_container: AbilityContainer
var attribute_map: GameplayAttributeMap
var unit_manager: UnitManager = get_parent()
# The grid position of this unit.
var grid_position: GridPosition:
	set(val):
		if not val is GridPosition:
			return
		#print_debug("New Grid Position: ", val.to_str())
		grid_position = val

var turn_started: bool = false


var is_holding: bool = false
# Reference to the action array node attached to this unit.
var target_unit: Unit


@export var is_enemy: bool = false:
	set(variable):
		is_enemy = variable
		if CombatSystem.instance:
			CombatSystem.instance.engagement_system.update_engagements_for_unit(self)

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

# Combat Variables
var fatigue_left: int


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
			continue
		if child is GameplayAttributeMap:
			attribute_map = child
			continue
		if child is Inventory:
			inventory = child
			continue
		if child is Equipment:
			equipment = child
			continue
	
	attribute_map.attribute_changed.connect(on_attribute_changed)
	
	update_weapon_anims()
	
	SignalBus.on_round_changed.connect(on_round_changed)
	SignalBus.on_cycle_changed.connect(on_reset_distance_moved)
	SignalBus.rotate_unit_towards_facing.connect(on_rotate_unit_toward_facing)
	SignalBus.add_unit.emit(self)

	if is_enemy and hair_tufts:
		Utilities.set_color_on_mesh(hair_tufts, Color.RED)




func _process(_delta: float) -> void:
	update_grid_position()


func update_grid_position() -> void:
	# Update the unit's grid position if it has moved to a new grid cell.
	var new_grid_position: GridPosition = LevelGrid.get_grid_position(global_transform.origin)
	if new_grid_position != grid_position:
		# Notify the level grid that the unit has moved.
		LevelGrid.unit_moved_grid_position(self, grid_position, new_grid_position)
		grid_position = new_grid_position
		SignalBus.unit_moved_position.emit()
		CombatSystem.instance.engagement_system.update_engagements_for_unit(self)
		

func update_weapon_anims() -> void:
	animator.on_equipment_changed(self)
	pass


func try_spend_ability_points_to_use_ability(ability: Ability) -> bool:
	if can_spend_ability_points_to_use_ability(ability):
		spend_ability_points(ability.ap_cost)
		return true
	Utilities.spawn_text_line(self, "No AP", Color.GOLD, 0.9)
	return false


func can_spend_ability_points_to_use_ability(ability: Ability) -> bool:
	var ap_remain: int = int(attribute_map.get_attribute_by_name("action_points").current_value)
	# Replace action points with ability points later
	if ap_remain >= ability.ap_cost:
		return true
	else:
		return false

func get_ability_points() -> int:
	return int(attribute_map.get_attribute_by_name("action_points").current_value)

func spend_ability_points(amount: int) -> void:
	attribute_map.get_attribute_by_name("action_points").current_value -= amount
	# Note: Change to ability points later
	SignalBus.emit_signal("action_points_changed")
	SignalBus.emit_signal("update_stat_bars")


func spend_all_ability_points() -> void:
	spend_ability_points(int(attribute_map.get_attribute_by_name("action_points").current_value))


func reset_ability_points() -> void:
	var new_ap_value: float = attribute_map.get_attribute_by_name("action_points").maximum_value
	
	# Get the action points penalty
	var ap_penalty = conditions_manager.get_total_penalty("action_points_penalty")
	new_ap_value = max(0, new_ap_value + ap_penalty)  # Ensure it doesn't go below 0
	
	attribute_map.get_attribute_by_name("action_points").current_value = new_ap_value








func remove_self() -> void:
	LevelGrid.remove_unit_at_grid_position(grid_position, self)
	SignalBus.remove_unit.emit(self)
	
	queue_free()

func on_dead() -> void:
	var death_effect = death_vfx_scene.instantiate() as Node3D
	get_tree().root.add_child(death_effect)
	death_effect.global_transform.origin = self.global_position
	if death_effect.get_child_count() > 0 and death_effect.get_child(0) is GPUParticles3D:
		death_effect.get_child(0).emitting = true
	
	remove_self()

func on_attribute_changed(_attribute: AttributeSpec):
	SignalBus.emit_signal("update_stat_bars")
	if attribute_map.get_attribute_by_name("health").current_value <= 0:
		on_dead()

func on_reset_distance_moved() -> void:
	set_distance_moved(0.0)

func on_round_changed() -> void:
	reset_ability_points()
	
	SignalBus.emit_signal("action_points_changed")
	SignalBus.emit_signal("update_stat_bars")

func on_rotate_unit_toward_facing(in_unit: Unit) -> void:
	if self == in_unit:
		animator.rotate_unit_towards_facing()

# Setters and Getters
func _to_string() -> String:
	# Return the unit's name as a string representation.
	return self.name


func has_ability(ability_name: StringName) -> bool:
	for ability: Ability in ability_container.granted_abilities:
		if ability.ui_name == ability_name:
			return true
	return false


func get_attribute_by_name(attribute_name: String) -> AttributeSpec:
	return attribute_map.get_attribute_by_name(attribute_name)

func get_attribute_buffed_value_by_name(attribute_name: String) -> float:
	return attribute_map.get_attribute_by_name(attribute_name).current_buffed_value


## Gets the current buffed value of the attribute after applying the situational modifier
func get_attribute_after_sit_mod(attribute_name: String, sit_mod_change: int = 0) -> int:
	var attribute: AttributeSpec = attribute_map.get_attribute_by_name(attribute_name)
	if attribute == null:
		push_error("Cannot find attribute ", attribute_name)
		return 0
	var base_value: float = attribute.current_buffed_value
	
	# Get the highest situational modifier multiplier from conditions
	# FIXME: The sit mod change can bring outside the bounds of the multiplier dictionary
	var highest_modifier = conditions_manager.get_highest_situational_modifier(sit_mod_change)

	# Apply the multiplier
	return ceili(base_value * highest_modifier)


func get_situational_modifier_grade_name(sit_mod_change: int = 0) -> String:
	return conditions_manager.get_highest_situational_modifier_name(sit_mod_change)



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


func get_world_position_chest() -> Vector3:
	return chest_marker.get_global_position()

func get_world_position_above_marker() -> Vector3:
	return above_marker.get_global_position()

func get_target_position_with_offset(height_offset: float) -> Vector3:
	var target_position = global_position
	target_position.y += height_offset
	return target_position

func get_movement_rate() -> float:
	return attribute_map.get_attribute_by_name("movement_rate").current_buffed_value


func get_max_move_left() -> float:
	var move_rate = get_movement_rate()
	var speed_multiplier = Utilities.GAIT_SPEED_MULTIPLIER.get(current_gait)

	# Get the movement penalty from conditions
	var movement_penalty = conditions_manager.get_total_penalty("movement_penalty")

	# Apply the movement penalty (e.g., reduce movement by penalty percentage)
	if movement_penalty == -1.0:
		return 0.0  # "Immobile" condition
	elif movement_penalty == -0.5:
		move_rate *= 0.5  # Halve the movement rate
		return ((move_rate * speed_multiplier) / 2) - distance_moved_this_turn
	else:
		move_rate -= movement_penalty  # Subtract numeric penalties
	
	return max(((move_rate * speed_multiplier) / 2) - distance_moved_this_turn - movement_penalty, 0)


func get_random_hit_location() -> BodyPart:
	return body.roll_hit_location()


func get_combat_skill() -> float:
	return int(attribute_map.get_attribute_by_name("combat_skill").current_buffed_value)

func get_equipped_weapon() -> Weapon:
	return equipment.get_equipped_weapon()



func get_equipped_weapons() -> Array[Weapon]:
	return equipment.get_equipped_weapons()

func get_inventory_items() -> Array[Item]:
	return inventory.items


#func get_all_equipped_weapons() -> Array[Weapon]:
	

#func get_right_hand_weapon() -> Weapon:
	#pass

#func get_left_hand_weapon() -> Weapon:
	#pass

func set_distance_moved(val: float) -> void:
	distance_moved_this_turn = val
	SignalBus.update_stat_bars.emit()

func add_distance_moved(val: float) -> void:
	print_debug("Distance Moved: ", val)
	distance_moved_this_turn += val
	SignalBus.update_stat_bars.emit()
	

func set_gait(gait: int) -> void:
	current_gait = gait
	gait_changed.emit(current_gait)


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


func setup_fatigue_left() -> void:
	var endurance: float = attribute_map.get_attribute_by_name("endurance").current_buffed_value
	# FIXME: Add a check to see how many times the unit has passed the check to increase the difficulty of the roll and halve time
	var max_rounds: int = ceili(endurance/5) #maximum rounds before combat fatigue needs to be rolled against
	fatigue_left = max_rounds
	
func try_reduce_fatigue_left() -> bool:
	if fatigue_left > 0:
		fatigue_left -= 1
		Utilities.spawn_text_line(self, "-1 Fatigue")
		return true
	return false
