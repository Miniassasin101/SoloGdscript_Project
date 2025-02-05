### UnitAnimator.gd
class_name UnitAnimator
extends Node

# Signals
signal rotation_completed
signal movement_completed
signal attack_completed
signal parry_reset
# Exported Variables
@export_category("References")
@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree
@export var fireball_projectile_prefab: PackedScene
@export var shoot_point: Node3D
@export var height_offset: float = 1.5  # Height offset to aim towards upper body


@export_category("Head Look Variables")
@export var skeleton: Skeleton3D
@export var neck_bone_name: String = "DEF_neck.001"
@export var neck_target: Marker3D
@export var neck_rot_speed: float = 2.0
@export var max_horizontal_angle: int = 90
@export var max_vertical_angle: int = 20
@export var head_look_vertical_offset: float = -3.0




@export_category("Body Location Variables")
@export var chest_point: Marker3D 
@export_category("Attack Variables")
@export var weapon_trail_length: int = 50
@export var general_hit_flash_mat: StandardMaterial3D
@export var white_hit_flash_mat: StandardMaterial3D
@export var red_hit_flash_mat: StandardMaterial3D
@export var hit_flash_time: float = 0.5


# Variables
@onready var unit: Unit = get_parent()
var fireball_instance: Projectile
var move_action: MoveAction
var shoot_action: ShootAction
var target_unit: Unit
var stored_damage: int
var projectile: Projectile

# Slowmo Variables
var is_slowed: bool = false
var timescale_multiplier: float = 1.0

# Neck Look Variables
var default_neck_transform: Transform3D
var head_look_override_weight: float = 0.0

var bone_smooth_rot: float = 0.0
var target_rotation: Quaternion
var is_looking: bool = false
var look_target: Node3D = null
# Neck look for being targeted
var is_being_targeted: bool = false


# Rotation Variables
var is_rotating: bool = false
var rotate_speed: float = 3.0
var facing_direction: Vector3

# Movement Variables
var is_moving: bool = false
var current_speed: float = 0.0
var acceleration_timer: float = 0.0
var rotation_acceleration_timer: float = 0.0
var curve_travel_offset: float = 0.0
var curve_length: float = 0.0
var movement_curve: Curve3D
var move_speed: float = 0.0
var move_rotate_speed: float = 0.0
var stopping_distance: float = 0.0

# Attack Variables:
var miss: bool = false
var weapon_trail_is_active: bool = false


# Ready Function - Called when the node enters the scene tree for the first time
func _ready() -> void:
	#call_deferred("connect_signals")
	SignalBus.equipment_changed.connect(equipment_anim_check)
	
	# Initialize the rest transform for the neck bone.
	var neck_idx = skeleton.find_bone(neck_bone_name)
	if neck_idx == -1:
		push_error("Neck bone '" + neck_bone_name + "' not found!")
		return
	default_neck_transform = skeleton.get_bone_rest(neck_idx)
	# Start with no override.
	head_look_override_weight = 0.0




# Physics Process - Called every frame to handle physics-related logic
func _physics_process(delta: float) -> void:
	if is_rotating:
		rotate_unit_towards_target_position_process(delta)
	if is_moving:
		move_along_curve_process(delta)
	if skeleton and look_target and is_looking:
		update_look_at(delta)


func get_character_mesh() -> Array[MeshInstance3D]:
	var ret_array: Array[MeshInstance3D] = []
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			ret_array.append(child as MeshInstance3D)
	
	return ret_array


## Function to be used to trigger and disable looking at a target. Just needs to be called with no arguments to turn off.
func look_at_toggle_dep(target: Node3D = null) -> void:
	if target == null:
		is_looking = false
	look_target = target
	is_looking = true

# When you want to control head-look via this script, call this function.
# Passing a valid target will smoothly blend in our override;
# passing null will smoothly drop the override, allowing your animations to take over.
func look_at_toggle(target: Node3D = null) -> void:
	look_target = target
	is_looking = (target != null)


func update_look_at(delta: float) -> void:
	"""
	Updates the neck bone to look at the assigned target.
	This ensures smooth and clamped rotation to prevent unnatural movements.
	"""
	var neck_bone = skeleton.find_bone(neck_bone_name)
	if neck_bone == -1:
		push_error("Neck Bone Not Found at ", self)
		return  # Bail out if the neck bone is not found

	# Get the parent bone's rotation
	var parent_bone = skeleton.get_bone_parent(neck_bone)
	var parent_global_pose: Transform3D = skeleton.get_bone_global_pose(parent_bone)
	var parent_rotation: Quaternion = parent_global_pose.basis.get_rotation_quaternion()
	var target_pos: Vector3 = look_target.get_global_position() + Vector3(0.0, head_look_vertical_offset, 0.0)
	
	# Calculate the neck's target rotation (look at target position)
	var _neck_target_pos: Vector3 = neck_target.get_global_position()
	neck_target.look_at(target_pos, Vector3.UP, true)
	var target_rotation_degrees: Vector3 = neck_target.rotation_degrees

	# Clamp the rotation to the desired range
	target_rotation_degrees.x = clamp(target_rotation_degrees.x, -max_vertical_angle, max_vertical_angle)
	target_rotation_degrees.y = clamp(target_rotation_degrees.y, -max_horizontal_angle, max_horizontal_angle)

	# Convert to radians and apply smoothing
	bone_smooth_rot = lerp_angle(bone_smooth_rot, deg_to_rad(target_rotation_degrees.y), neck_rot_speed * delta)
	var final_rotation: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(target_rotation_degrees.x), bone_smooth_rot, 0))

	# Remove the parent's rotation influence
	final_rotation = parent_rotation.inverse() * final_rotation

	# Apply the final rotation to the neck bone
	skeleton.set_bone_pose_rotation(neck_bone, final_rotation)


# Call this each frame (or in _physics_process) to update the neck bone.
func update_look_at_dep3(delta: float) -> void:
	var neck_idx = skeleton.find_bone(neck_bone_name)
	if neck_idx == -1:
		push_error("Neck bone '" + neck_bone_name + "' not found!")
		return

	# Determine the target override weight: if actively looking, we want full override (1.0); otherwise 0.
	var target_weight: float = 1.0 if is_looking else 0.0
	head_look_override_weight = lerp(head_look_override_weight, target_weight, neck_rot_speed * delta)
	
	# Retrieve the current pose as computed by animations.
	var current_pose: Transform3D = skeleton.get_bone_pose(neck_idx)
	var current_trans: Vector3 = current_pose.origin
	# Preserve the bone’s current scale.
	var current_scale: Vector3 = current_pose.basis.get_scale()
	# Get the current rotation (in local space).
	var current_rot: Quaternion = current_pose.basis.get_rotation_quaternion()

	# Compute the desired override rotation.
	var desired_rot: Quaternion
	if is_looking and look_target:
		# Determine a target position with a vertical offset.
		var target_pos: Vector3 = look_target.global_transform.origin + Vector3(0.0, head_look_vertical_offset, 0.0)
		# Use your temporary marker node to compute the needed rotation.
		neck_target.look_at(target_pos, Vector3.UP, true)
		var target_rot_deg: Vector3 = neck_target.rotation_degrees
		# Clamp the computed angles.
		target_rot_deg.x = clamp(target_rot_deg.x, -max_vertical_angle, max_vertical_angle)
		target_rot_deg.y = clamp(target_rot_deg.y, -max_horizontal_angle, max_horizontal_angle)
		desired_rot = Quaternion.from_euler(Vector3(deg_to_rad(target_rot_deg.x), deg_to_rad(target_rot_deg.y), 0))
	else:
		# If not looking, fall back to the rest rotation.
		desired_rot = default_neck_transform.basis.get_rotation_quaternion()
	
	# Blend from the current rotation toward the desired override.
	var blended_rot: Quaternion = current_rot.slerp(desired_rot, head_look_override_weight)
	var new_basis: Basis = Basis(blended_rot)
	# Reapply the current scale.
	new_basis = new_basis.scaled(current_scale)
	
	# Construct a new pose with the animation’s translation and our blended rotation.
	var new_pose: Transform3D = Transform3D(new_basis, current_trans)
	skeleton.set_bone_pose(neck_idx, new_pose)


func update_look_at_dep(delta: float) -> void:
	var neck_idx = skeleton.find_bone(neck_bone_name)
	if neck_idx == -1:
		push_error("Neck bone '" + neck_bone_name + "' not found!")
		return

	# Determine the target override weight: if actively looking, we want full override (1.0); otherwise 0.
	var target_weight: float = 1.0 if is_looking else 0.0
	head_look_override_weight = lerp(head_look_override_weight, target_weight, neck_rot_speed * delta)
	
	# Retrieve the current pose as computed by animations.
	var current_pose: Transform3D = skeleton.get_bone_pose(neck_idx)
	var current_trans: Vector3 = current_pose.origin
	# Preserve the bone’s current scale.
	var current_scale: Vector3 = current_pose.basis.get_scale()
	# Get the current rotation (in local space).
	var current_rot: Quaternion = current_pose.basis.get_rotation_quaternion()

	# Compute the desired override rotation.
	var desired_rot: Quaternion
	if is_looking and look_target:
		# Determine a target position with a vertical offset.
		var target_pos: Vector3 = look_target.global_transform.origin + Vector3(0.0, head_look_vertical_offset, 0.0)
		# Use the temporary marker node to compute the needed rotation.
		neck_target.look_at(target_pos, Vector3.UP, true)
		var target_rot_deg: Vector3 = neck_target.rotation_degrees
		# Clamp the computed angles.
		target_rot_deg.x = clamp(target_rot_deg.x, -max_vertical_angle, max_vertical_angle)
		target_rot_deg.y = clamp(target_rot_deg.y, -max_horizontal_angle, max_horizontal_angle)
		desired_rot = Quaternion.from_euler(Vector3(deg_to_rad(target_rot_deg.x), deg_to_rad(target_rot_deg.y), 0))
	else:
		# If not looking, fall back to the rest rotation but apply a 180° correction around Y.
		# Post-multiply the rest rotation so that the forward direction (-Z) is flipped to +Z,
		# while keeping the original X (pitch) and Y (yaw) intact.
		desired_rot = default_neck_transform.basis.get_rotation_quaternion() * Quaternion(Vector3.UP, PI)
	
	# Blend from the current rotation toward the desired override.
	var blended_rot: Quaternion = current_rot.slerp(desired_rot, head_look_override_weight)
	var new_basis: Basis = Basis(blended_rot)
	# Reapply the current scale.
	new_basis = new_basis.scaled(current_scale)
	
	# Construct a new pose with the animation’s translation and our blended rotation.
	var new_pose: Transform3D = Transform3D(new_basis, current_trans)
	skeleton.set_bone_pose(neck_idx, new_pose)




# Animate Movement Along Curve
# Handles setting up movement parameters and starting movement
func animate_movement_along_curve(move_speed_in: float, movement_curve_in: Curve3D, curve_length_in: float, acceleration_timer_in: float, rotation_acceleration_timer_in: float,  stopping_distance_in: float, rotate_speed_in: float) -> void:
	move_speed = move_speed_in
	movement_curve = movement_curve_in
	curve_length = curve_length_in
	acceleration_timer = acceleration_timer_in
	rotation_acceleration_timer = rotation_acceleration_timer_in
	stopping_distance = stopping_distance_in
	move_rotate_speed = rotate_speed_in
	current_speed = 0.1  # Initial movement speed
	curve_travel_offset = 0.0
	is_moving = true
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/conditions/IsWalking", true)

func equipment_anim_check(in_unit: Unit) -> void:
	if in_unit != unit:
		return
	if !unit.equipment.equipped_items.is_empty():
		weapon_setup(true)
		return
	weapon_setup(false)

func weapon_setup(weapon_type: bool) -> void:
	var tween: Tween = create_tween()
	if weapon_type:
		animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/GreatswordBlend/blend_amount", 1.0)
		tween.tween_property(animator_tree, "parameters/Main/AnimationNodeStateMachine/IdleBlend/GreatswordIdleBlend/blend_amount", 1.0, 0.7)
		#animator_tree.set("parameters/Main/AnimationNodeStateMachine/IdleBlend/GreatswordIdleBlend/blend_amount", 1.0)
		return
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/GreatswordBlend/blend_amount", 0.0)
	tween.tween_property(animator_tree, "parameters/Main/AnimationNodeStateMachine/IdleBlend/GreatswordIdleBlend/blend_amount", 0.0, 0.7)

func left_cast_anim(_in_animation: Animation, in_miss: bool = false) -> void:
	# Note: Later replace greatsword test with the animation library
	miss = in_miss

	animator_tree.set("parameters/Main/AnimationNodeStateMachine/IdleBlend/LeftArmBlend/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)# or enum 1


	await attack_completed#timer.timeout

	return
	# Always add call method tracks for resolving the damage
	
func play_animation_by_name(animation_name: String, _blend_time: float = 0.5) -> void:
	# Get the AnimationTree's state machine root
	var root: AnimationNodeStateMachine = animator_tree.tree_root as AnimationNodeStateMachine
	if root == null:
		push_error("AnimationTree does not have a valid StateMachine root.")
		return
	
	var main: AnimationNodeBlendTree = root.get_node("Main")
	
	var one_shot: AnimationNodeAnimation = main.get_node("OneShotAnimation")
	
	var anim_path: String = ("GreatSwordTest1/" + animation_name)
	
	one_shot.set_animation(anim_path)
	
	#one_shot_node.set("request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	animator_tree.set("parameters/Main/OneShotBlend/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	print("firing: ", anim_path)
	var anim: Animation = animator.get_animation(anim_path)
	await get_tree().create_timer(anim.length / timescale_multiplier).timeout
	print("done")
	return




	# NOTE: Always add call method tracks for resolving the damage
func melee_attack_anim(in_animation: Animation, in_miss: bool = false) -> void:
# Note: Later replace greatsword test with the animation library
	#look_at_toggle()

	miss = in_miss
	var root: AnimationNodeStateMachine = animator_tree.tree_root
	var main: AnimationNodeBlendTree = root.get_node("Main")
	var state_mach: AnimationNodeStateMachine = main.get_node("AnimationNodeStateMachine")
	var attack: AnimationNodeBlendTree = state_mach.get_node("Attack")
	var attack_anim: AnimationNodeAnimation = attack.get_node("AttackAnimation")
	var animation: StringName = attack_anim.get_animation()
	print_debug("Old Animation: ", animation)
	var anim_path: String = ("GreatSwordTest1/" + in_animation.resource_name)
	attack_anim.set_animation(anim_path)
	#GreatSwordTest1/Greatsword_Swing_001

	#var is_attacking: bool = animator_tree.get("parameters/conditions/IsAttacking")
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/conditions/IsAttacking", true)
	# Animation stand-in

	await attack_completed#timer.timeout
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/conditions/IsAttacking", false)
	look_at_toggle(look_target)

	return

func weapon_trail_toggle() -> void:
	var weapon: Weapon = unit.get_equipped_weapon()
	if !weapon or !unit.equipment.has_equipped_weapon():
		return
	var weapon_visual: ItemVisual = weapon.get_item_visual()
	if !weapon_visual:
		return
	if !weapon_trail_is_active:
		
		if weapon_visual.set_trail_visibility(true):
			weapon_trail_is_active = true
		return
	if weapon_visual.set_trail_visibility(false):
		weapon_trail_is_active = false

func attack_landed() -> void:
	attack_completed.emit()
	if miss:
		miss = false
		"""
		toggle_engine_slowdown(true)
		await get_tree().create_timer(1.0, true, false, true).timeout
		toggle_engine_slowdown()
		"""
		toggle_slowdown(0.1)
		await get_tree().create_timer(1.3).timeout
		toggle_slowdown()
		return
	trigger_camera_shake()
	toggle_slowdown()
	await get_tree().create_timer(0.4).timeout
	toggle_slowdown()


func toggle_slowdown(speed_scale: float = 0.0) -> void:

	if !is_slowed:
			set_timescales(speed_scale)
			# FIXME: Multiplier might be inverted, increases rather than decreases
			timescale_multiplier = speed_scale
			is_slowed = true

	else:
		set_timescales(1.0)
		timescale_multiplier = 1.0
		is_slowed = false



func toggle_engine_slowdown(_toggle: bool = false) -> void:
	#var speed: float = animator.get_speed_scale()
	if !is_slowed:
			Engine.set_time_scale(0.01)
			is_slowed = true

	else:
		Engine.set_time_scale(1.0)
		is_slowed = false

		return

func set_timescales(val: float) -> void:
	animator_tree.set("parameters/Main/TimeScale/scale", val)


func trigger_camera_shake() -> void:
	var strength = 0.15 # the maximum shake strength. The higher, the messier
	var shake_time = 0.4 # how much it will last
	var shake_frequency = 50 # will apply 250 shakes per `shake_time`

	CameraShake.instance.shake(strength, shake_time, shake_frequency)


func trigger_camera_shake_large() -> void:
	var strength = 0.3 # the maximum shake strength. The higher, the messier
	var shake_time = 0.4 # how much it will last
	var shake_frequency = 20 # will apply 250 shakes per `shake_time`

	CameraShake.instance.shake(strength, shake_time, shake_frequency)


func trigger_camera_shake_small() -> void:
	var strength = 0.04 # the maximum shake strength. The higher, the messier
	var shake_time = 0.1 # how much it will last
	var shake_frequency = 20 # will apply 250 shakes per `shake_time`

	CameraShake.instance.shake(strength, shake_time, shake_frequency)

func trigger_camera_shake_tiny() -> void:
	var strength = 0.02 # the maximum shake strength. The higher, the messier
	var shake_time = 0.07 # how much it will last
	var shake_frequency = 20 # will apply 250 shakes per `shake_time`

	CameraShake.instance.shake(strength, shake_time, shake_frequency)

func trigger_hit_fx(in_hit_fx: PackedScene, originator: Vector3) -> void:
	var hit_fx = in_hit_fx.instantiate() as Node3D
	#get_tree().root.add_child(hit_fx)
	unit.add_child(hit_fx)
	hit_fx.global_position = chest_point.global_position#unit.get_world_position() + Vector3(0.0, 1.0, 0.0)
	hit_fx.global_rotation = -originator#chest_point.global_rotation
	
	hit_fx.get_child(0).emitting = true
	


func testprint() -> void:
	print_debug("AnimTestPrint")

# Move Along Curve Process
# Handles the movement along the given curve in each frame
func move_along_curve_process(delta: float) -> void:
	if curve_travel_offset >= curve_length:
		on_stop_moving()
		return

	# Accelerate movement speed smoothly
	if acceleration_timer > 0.0:
		acceleration_timer -= delta
		var acceleration_progress: float = 1.0 - (acceleration_timer / 0.5)  # Interpolation factor from 0 to 1
		current_speed = lerp(0.0, move_speed, acceleration_progress)
	else:
		current_speed = move_speed

	# Get the current position on the curve
	var current_position = unit.global_transform.origin
	var next_position: Vector3 = movement_curve.sample_baked(curve_travel_offset)
	var move_direction: Vector3 = (next_position - current_position).normalized()

	# Move towards the next position with the current speed
	var distance_to_next_point = current_position.distance_to(next_position)
	if distance_to_next_point > stopping_distance:
		current_position += move_direction * current_speed * delta
		unit.global_transform.origin = current_position

		# Smoothly accelerate the rotation towards the movement direction
		if rotation_acceleration_timer > 0.0:
			rotation_acceleration_timer -= delta
			var rotation_progress: float = 1.0 - (rotation_acceleration_timer / 0.5)  # Interpolation factor from 0 to 1
			rotate_speed = lerp(move_rotate_speed - 3.0, move_rotate_speed, rotation_progress)
		else:
			rotate_speed = move_rotate_speed  # Default rotation speed

		# Smoothly rotate the unit towards the movement direction
		var tar_rot = Basis.looking_at(move_direction, Vector3.UP, true)
		unit.global_transform.basis = unit.global_transform.basis.slerp(tar_rot, delta * rotate_speed)
		unit.global_transform.basis = unit.global_transform.basis.orthonormalized()

	# Increment the travel offset along the curve
	curve_travel_offset += min(current_speed * delta, curve_length - curve_travel_offset)

# Rotation Functions
# Handles the start and process of rotating towards a target position
func rotate_unit_towards_target_position(grid_position: GridPosition) -> void:
	is_rotating = true
	facing_direction = (LevelGrid.get_world_position(grid_position) - unit.get_world_position()).normalized()

"""
Sets the facing variable based on the unit's current rotation.
Values in parentheses assume unit is rotated 0 degrees.
Facing values:
- 0: 180 degrees (facing North(back))
- 1: 90 degrees (facing East(left))
- 2: 0 degrees (facing South(front))
- 3: -90 degrees (facing West(right))
"""

func rotate_unit_towards_facing(in_facing: int = -1) -> void:
	var gridpos: GridPosition = unit.get_grid_position()
	var new_gridpos: GridPosition = GridPosition.new(gridpos.x, gridpos.z)
	var facing = in_facing if (in_facing >= 0) else unit.facing
	
	match facing:
		0:
			new_gridpos.z -= 1
			rotate_unit_towards_target_position(new_gridpos)

		1:
			new_gridpos.x += 1
			rotate_unit_towards_target_position(new_gridpos)

		2:
			new_gridpos.z += 1
			rotate_unit_towards_target_position(new_gridpos)

		3:
			new_gridpos.x -= 1
			rotate_unit_towards_target_position(new_gridpos)

func rotate_unit_towards_target_position_process(delta: float):
	var tar_rot = Basis.looking_at(facing_direction, Vector3.UP, true)
	unit.global_transform.basis = unit.global_transform.basis.slerp(tar_rot, delta * rotate_speed)
	unit.global_transform.basis = unit.global_transform.basis.orthonormalized()

	# Check if the rotation is close enough to stop rotating
	var current_direction = unit.global_transform.basis.z.normalized()
	if current_direction.dot(facing_direction) > 0.9999:
		is_rotating = false  # Stop rotating if we're almost facing the target
		rotation_completed.emit()


func flash_color(color: Color = Color.DEEP_SKY_BLUE, flash_time: float = hit_flash_time, flash_weapon: bool = true) -> void:
	var unit_meshes: Array[MeshInstance3D] = get_character_mesh()
	if flash_weapon:
		var weapon_mesh: MeshInstance3D = unit.get_equipped_weapon().get_object() as MeshInstance3D
		if weapon_mesh:
			unit_meshes.append(weapon_mesh)
	"""
	for mesh in unit_meshes:
		var mesh_mat: StandardMaterial3D = general_hit_flash_mat.duplicate(true)
		mesh_mat.set_albedo(color)
		mesh.set_material_overlay(mesh_mat)
	
	await get_tree().create_timer(flash_time).timeout
	
	for mesh in unit_meshes:
		mesh.set_material_overlay(null)
	"""
	Utilities.flash_color_on_meshes(unit_meshes, color, flash_time,)


func flash_white(flash_time: float = hit_flash_time) -> void:
	var unit_meshes: Array[MeshInstance3D] = get_character_mesh()
	for mesh in unit_meshes:
		mesh.set_material_overlay(white_hit_flash_mat)
	
	await get_tree().create_timer(flash_time).timeout
	
	for mesh in unit_meshes:
		mesh.set_material_overlay(null)


func flash_red(flash_time: float = hit_flash_time) -> void:
	var unit_meshes: Array[MeshInstance3D] = get_character_mesh()
	for mesh in unit_meshes:
		mesh.set_material_overlay(red_hit_flash_mat)
	
	await get_tree().create_timer(flash_time).timeout
	
	for mesh in unit_meshes:
		mesh.set_material_overlay(null)


# Targeting handlers
func on_is_being_targeted(by_unit: Unit) -> void:
	is_being_targeted = true
	look_at_toggle(by_unit.above_marker)


# function to cancel the head_look and smoothly return to normal
func on_stop_being_targeted() -> void:
	is_being_targeted = false
	look_at_toggle()

# Movement State Handlers
func on_start_moving() -> void:
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/conditions/IsWalking", true)

func on_stop_moving() -> void:
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/conditions/IsWalking", false)
	is_moving = false
	#await get_tree().create_timer(0.2).timeout
	movement_completed.emit()
