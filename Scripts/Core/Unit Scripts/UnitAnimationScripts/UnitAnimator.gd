### UnitAnimator.gd
class_name UnitAnimator
extends Node

# Signals
signal rotation_completed
signal movement_completed
signal attack_completed
@warning_ignore("unused_signal")
signal parry_reset
signal event_occured
signal prompt_dodge

enum AnimationMask {
	NONE  = -1,
	LEFT  = 0,
	RIGHT = 1,
	BOTH  = 2,
}


# Exported Variables
@export_category("References")
@export var animation_library: String = "HumanoidAnimLib01/"
@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree
@export var fireball_projectile_prefab: PackedScene
@export var shoot_point: Node3D
@export var look_at_modifier: LookAtModifier3D
@export var skeleton: Skeleton3D
@export var rig_root: Node3D







@export_category("Body Location Variables")
@export var chest_point: Marker3D
@export var height_offset: float = 1.5  # Height offset to aim towards upper body
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


# Root Motion Variables
var is_root_motion: bool = false


# Animation Tree Variables
var root: AnimationNodeStateMachine = null

var main: AnimationNodeBlendTree = null

var state_machine: AnimationNodeStateMachine = null

var one_shot_blend: AnimationNodeOneShot = null

var idleblend: AnimationNodeBlendTree = null

var runblend: AnimationNodeBlendTree = null

var one_shot: AnimationNodeAnimation = null

var base_idle: AnimationNodeAnimation = null

var buffer_idle: AnimationNodeAnimation = null

var left_idle_anim: AnimationNodeAnimation = null

var right_idle_anim: AnimationNodeAnimation = null

var left_run_anim: AnimationNodeAnimation = null

var right_run_anim: AnimationNodeAnimation = null



# Attack Variables:
var miss: bool = false
var weapon_trail_is_active: bool = false

# Idle blend variables
var idle_blend_tween: Tween = null
var is_blending: bool = false
var check_queued: bool = false

# ——— Cache all the property paths & their current values ———
var skeleton_node_path: String = "Rig_001/Skeleton3D"


var left_shoulder_bone_name: String = "DEF_shoulder.L.001"
var right_shoulder_bone_name: String = "DEF_shoulder.R.001"


var P_ONE_SHOT_BLEND_R: StringName = "parameters/Main/OneShotRightArmBlend/blend_amount"
var P_ONE_SHOT_BLEND_L: StringName = "parameters/Main/OneShotLeftArmBlend/blend_amount"
var P_ONE_SHOT_REQUEST: StringName = "parameters/Main/OneShotBlend/request"


var P_IDLE: String = "parameters/Main/AnimationNodeStateMachine/IdleBlend/BaseIdleBlend/blend_amount"
var P_IDLE_B: String = "parameters/Main/AnimationNodeStateMachine/IdleBlend/BufferIdleBlend/blend_amount"
var P_IDLE_R: String = "parameters/Main/AnimationNodeStateMachine/IdleBlend/RightArmIdleBlend/blend_amount"
var P_IDLE_L: String = "parameters/Main/AnimationNodeStateMachine/IdleBlend/LeftArmIdleBlend/blend_amount"

var P_RUN_R: String = "parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmBlend/blend_amount"
var P_RUN_L: String = "parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmBlend/blend_amount"

# Filtered Bone Paths
var filtered_one_shot_bones: Array[String] = []



# Ready Function - Called when the node enters the scene tree for the first time
func _ready() -> void:
	#call_deferred("connect_signals")
	SignalBus.equipment_changed.connect(on_equipment_changed)
	animator_tree_setup()






# Physics Process - Called every frame to handle physics-related logic
func _physics_process(delta: float) -> void:
	if is_rotating:
		rotate_unit_towards_target_position_process(delta)
	if is_moving:
		move_along_curve_process(delta)
	if is_root_motion:
		root_motion_process()


func get_character_mesh() -> Array[MeshInstance3D]:
	var ret_array: Array[MeshInstance3D] = []
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			ret_array.append(child as MeshInstance3D)

	return ret_array


#region Head Look Functions

# When you want to control head-look via this script, call this function.
# Passing a valid target will smoothly blend in our override;
# passing null will smoothly drop the override, allowing your animations to take over.
func look_at_toggle(_target: Node3D = null) -> void:
	return

# Enables head-look: sets the LookAtModifier3D target to the given node.
func enable_head_look(target: Node3D) -> void:
	if target:
		look_at_modifier.target_node = target.get_path()
		look_at_modifier.duration = 0.3  # adjust the interpolation duration as needed
		is_looking = true
		head_look_override_weight = 1.0
		print_debug("Head look enabled for target: ", target.name)
	else:
		disable_head_look()

# Disables head-look by clearing the target.
func disable_head_look() -> void:
	look_at_modifier.target_node = NodePath("")
	is_looking = false
	head_look_override_weight = 0.0
	print_debug("Head look disabled.")

# Toggles the head-look state: if already looking, disables it; otherwise enables toward the given target.
func toggle_head_look(target: Node3D) -> void:
	if is_looking:
		disable_head_look()
	else:
		enable_head_look(target)

# Updates the head-look target if different from the current one.
func update_head_look_target(new_target: Node3D) -> void:
	# Only update if the new target is different.
	if new_target and (look_at_modifier.target_node != new_target.get_path()):
		enable_head_look(new_target)
	else:
		print_debug("Head look target remains unchanged.")

# Checks if the current look target is within the LookAtModifier's limitations.
# If not, disable the head-look (or optionally, adjust parameters).
func check_head_look_limitation() -> void:
	if look_at_modifier.target_node != NodePath("") and not look_at_modifier.is_target_within_limitation():
		print_debug("Target outside angle limitations; disabling head look.")
		disable_head_look()
#endregion




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


func move_and_slide(target_pos: GridPosition, slide_duration: float = 0.8) -> void:
	var target_global_pos: Vector3 = LevelGrid.get_world_position(target_pos)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(unit, "global_position", target_global_pos, slide_duration)
	await tween.finished


func on_equipment_changed(in_unit: Unit) -> void:
	if in_unit != unit:
		return
	queue_equipment_check()





# This prevents any animation changes like weapon equips duplicating across instances
func make_tree_root_unique() -> void:
	animator_tree.set_tree_root(animator_tree.tree_root.duplicate(true))


func animator_tree_setup() -> void:
	make_tree_root_unique()

	set_animator_tree_properties()



# ------------------------------------------------------------
# Cache all the AnimationTree nodes we need for blending
# ------------------------------------------------------------
func set_animator_tree_properties() -> void:
	# Root of the state machine
	root = animator_tree.tree_root as AnimationNodeStateMachine
	if root == null:
		push_error("AnimationTree does not have a valid StateMachine root.")
		return

	# Main sub–state machine
	main = root.get_node("Main")
	state_machine = main.get_node("AnimationNodeStateMachine")

	# Blend nodes
	idleblend = state_machine.get_node("IdleBlend")
	idleblend.set_filter_path("UnitAnimator", true)
	runblend  = state_machine.get_node("RunCycleBlend")
	runblend.set_filter_path("UnitAnimator", true)
	

	# Individual animation nodes
	# Play Animation animations
	one_shot       = main.get_node("OneShotAnimation")
	one_shot_blend = main.get_node("OneShotBlend")
	one_shot_blend.set_filter_path("UnitAnimator", true)


	# Idle Animations
	base_idle       = idleblend.get_node("BaseIdleAnimation")
	buffer_idle     = idleblend.get_node("BufferIdleAnimation")
	right_idle_anim = idleblend.get_node("RightArmIdleAnimation")
	left_idle_anim  = idleblend.get_node("LeftArmIdleAnimation")

	# Run Animations
	left_run_anim  = runblend.get_node("LeftArmAnimation")
	right_run_anim = runblend.get_node("RightArmAnimation")



func queue_equipment_check() -> void:
	if check_queued:
		return

	if get_tree().process_frame.is_connected(equipment_anim_check):
		return

	get_tree().process_frame.connect(equipment_anim_check.bind(unit))

	check_queued = true



func equipment_anim_check(in_unit: Unit) -> void:
	if in_unit != unit:
		return



	if idle_blend_tween and idle_blend_tween.is_running():
		return

	if get_tree().process_frame.is_connected(equipment_anim_check):
		get_tree().process_frame.disconnect(equipment_anim_check)

	check_queued = false


	if !unit.equipment.equipped_items.is_empty():
		var idle_request: IdleBlendChangeRequest = create_idle_blend_request()

		weapon_idle_blend_setup(idle_request)
		return
	weapon_idle_blend_setup(null) # resets



func create_idle_blend_request() -> IdleBlendChangeRequest:
	var active_weapons: Array[Weapon] = unit.equipment.get_equipped_weapons()

	#if active_weapons.is_empty():
	#	return

	var right_weapon: Weapon = null
	var left_weapon: Weapon = null

	var iteration_num: int = 0
	for weapon in active_weapons:
		var active_weapon: Weapon = active_weapons[iteration_num]
		if active_weapon.tags.has("both") or active_weapon.hands == 2: # If is two handed weapon
			right_weapon = active_weapon
			left_weapon = active_weapon
			continue
		elif active_weapon.tags.has("right"):
			right_weapon = active_weapon
			#left_weapon = active_weapon
		elif active_weapon.tags.has("left"):
			#right_weapon = active_weapon
			left_weapon = active_weapon
		iteration_num += 1





	var idle_request: IdleBlendChangeRequest = IdleBlendChangeRequest.new(null
		,right_weapon.idle_animation if right_weapon else null
		,left_weapon.idle_animation if left_weapon else null
		,left_weapon != null
		,right_weapon != null
		,IdleBlendChangeRequest.BaseAnimBackup.Left)


	if !left_weapon and !right_weapon:
		idle_request.clear_all = true

	return idle_request



# ------------------------------------------------------------
# Tween between idle/run blends when equipping or unequipping
# ------------------------------------------------------------
func weapon_idle_blend_setup(blend_request: IdleBlendChangeRequest) -> void:
	# Ensure we have a request object
	if blend_request == null:
		blend_request = IdleBlendChangeRequest.new()
		blend_request.clear_all = true
	var b: IdleBlendChangeRequest = blend_request

	# Kill any running tween
	if idle_blend_tween and idle_blend_tween.is_running():
		idle_blend_tween.kill()

	# Start a fresh parallel tween
	idle_blend_tween = get_tree().create_tween()
	idle_blend_tween.set_parallel(true)

	# Read current blend parameters
	var cur_idle: float   = animator_tree.get(P_IDLE)
	var cur_idle_b: float = animator_tree.get(P_IDLE_B)
	var cur_idle_r: float = animator_tree.get(P_IDLE_R)
	var cur_idle_l: float = animator_tree.get(P_IDLE_L)
	var cur_run_r: float  = animator_tree.get(P_RUN_R)
	var cur_run_l: float  = animator_tree.get(P_RUN_L)

	# “Lock in” those values before tweening
	animator_tree.set(P_IDLE,   cur_idle)
	animator_tree.set(P_IDLE_B, cur_idle_b)
	animator_tree.set(P_IDLE_R, cur_idle_r)
	animator_tree.set(P_IDLE_L, cur_idle_l)
	animator_tree.set(P_RUN_R,  cur_run_r)
	animator_tree.set(P_RUN_L,  cur_run_l)

	# If we’re blending rather than clearing…
	if not b.clear_all and (b.blend_left or b.blend_right):
		var base_idle_path: String  = base_idle.get_animation()
		var active_idle_blend: String = P_IDLE
		var cur_idle_active: float      = cur_idle
		var blend_back_to_base: bool    = false

		# Decide if we need to swap into the buffer slot
		if base_idle_path != b.base_idle_animation_path and cur_idle == 1.0:
			active_idle_blend = P_IDLE_B
			blend_back_to_base = true
			cur_idle_active = cur_idle_b
			buffer_idle.set_animation(b.base_idle_animation_path)
		elif cur_idle == 0.0:
			base_idle.set_animation(b.base_idle_animation_path)

		# Pre-set any run animations
		if b.blend_left:
			left_run_anim.set_animation(b.left_idle_animation_path)
		if b.blend_right:
			right_run_anim.set_animation(b.right_idle_animation_path)

		# — Only one hand —
		if not b.blend_left or not b.blend_right:
			# Right hand only
			if b.blend_right and not b.blend_left:
				right_idle_anim.set_animation(b.right_idle_animation_path)
				right_run_anim.set_animation(b.right_idle_animation_path)

				idle_blend_tween.tween_property(animator_tree, active_idle_blend, 1.0, 0.7).from(cur_idle_active)
				idle_blend_tween.tween_property(animator_tree, P_IDLE_R,        1.0, 0.7).from(cur_idle_r)
				idle_blend_tween.tween_property(animator_tree, P_IDLE_L,        0.0, 0.7).from(cur_idle_l)

				animator_tree.set(P_RUN_R, 1.0)
				animator_tree.set(P_RUN_L, 0.0)
				await idle_blend_tween.finished

				if blend_back_to_base:
					base_idle.set_animation(b.base_idle_animation_path)
					idle_blend_tween.kill()
					idle_blend_tween = get_tree().create_tween()
					idle_blend_tween.tween_property(animator_tree, active_idle_blend, 0.0, 1.5)
					await idle_blend_tween.finished
					Console.print_line("Custom blend successful on: " + b.base_idle_animation_path)
				return

			# Left hand only
			elif not b.blend_right and b.blend_left:
				left_idle_anim.set_animation(b.left_idle_animation_path)
				left_run_anim.set_animation(b.left_idle_animation_path)

				idle_blend_tween.tween_property(animator_tree, active_idle_blend, 1.0, 0.7).from(cur_idle_active)
				idle_blend_tween.tween_property(animator_tree, P_IDLE_R,        0.0, 0.7).from(cur_idle_r)
				idle_blend_tween.tween_property(animator_tree, P_IDLE_L,        1.0, 0.7).from(cur_idle_l)

				animator_tree.set(P_RUN_R, 0.0)
				animator_tree.set(P_RUN_L, 1.0)
				await idle_blend_tween.finished

				if blend_back_to_base:
					base_idle.set_animation(b.base_idle_animation_path)
					idle_blend_tween.kill()
					idle_blend_tween = get_tree().create_tween()
					idle_blend_tween.tween_property(animator_tree, active_idle_blend, 0.0, 1.5)
					await idle_blend_tween.finished
					Console.print_line("Custom blend successful on: " + b.base_idle_animation_path)
				return

		# — Both hands —
		elif b.blend_left and b.blend_right:
			right_idle_anim.set_animation(b.right_idle_animation_path)
			left_idle_anim.set_animation(b.left_idle_animation_path)
			right_run_anim.set_animation(b.right_idle_animation_path)
			left_run_anim.set_animation(b.left_idle_animation_path)

			idle_blend_tween.tween_property(animator_tree, active_idle_blend, 1.0, 0.7).from(cur_idle_active)
			idle_blend_tween.tween_property(animator_tree, P_IDLE_R,        1.0, 0.7).from(cur_idle_r)
			idle_blend_tween.tween_property(animator_tree, P_IDLE_L,        1.0, 0.7).from(cur_idle_l)

			animator_tree.set(P_RUN_R, 1.0)
			animator_tree.set(P_RUN_L, 1.0)
			await idle_blend_tween.finished

			if blend_back_to_base:
				base_idle.set_animation(b.base_idle_animation_path)
				idle_blend_tween.kill()
				idle_blend_tween = get_tree().create_tween()
				idle_blend_tween.tween_property(animator_tree, active_idle_blend, 0.0, 1.5)
				await idle_blend_tween.finished
				Console.print_line("Custom blend successful on: " + b.base_idle_animation_path)
			return

	# --------------------------------------------------------
	# Default: clear all blends back to zero
	# --------------------------------------------------------
	idle_blend_tween.tween_property(animator_tree, P_IDLE,   0.0, 0.7).from(cur_idle)
	idle_blend_tween.tween_property(animator_tree, P_IDLE_R, 0.0, 0.7).from(cur_idle_r)
	idle_blend_tween.tween_property(animator_tree, P_IDLE_L, 0.0, 0.7).from(cur_idle_l)

	animator_tree.set(P_RUN_R, 0.0)
	animator_tree.set(P_RUN_L, 0.0)

	await idle_blend_tween.finished





func play_animation_by_name(
	animation_name: String, blend_time: float = 0.2, \
	use_root_motion: bool = false, animation_mask: int = AnimationMask.NONE, \
	abort_self: bool = true) -> void:

	# 1) BEFORE we fire the shot: clear and then set those arm mask filters
	if !filtered_one_shot_bones.is_empty():
		clear_all_filters()

	set_one_shot_arm_masks(animation_mask)



	var anim_path: String = (animation_library + animation_name)

	# 2) Set up the one-shot fade in/out, as well as the animation
	one_shot_blend.set_fadein_time(blend_time)
	one_shot_blend.set_fadeout_time(blend_time)
	var current_anim_name: String = one_shot.get_animation()
	if current_anim_name != animation_name:

		one_shot.set_animation(animation_library + animation_name)
	animator_tree.set(P_ONE_SHOT_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	# 3) Set the root motion and wait for the length of the animation
	var anim: Animation = animator.get_animation(anim_path)
	is_root_motion = use_root_motion
	print_debug("Currently Playing: " + animation_name)
	await get_tree().create_timer(anim.length / timescale_multiplier).timeout

	# 4) AFTER the one shot time runs out, fade the blend back out.
	if abort_self:

		animator_tree.set("P_ONE_SHOT_REQUEST", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
		print_debug("Animation Aborted: " + animation_name)

	is_root_motion = false
	return

## Enables or disables the filter on the OneShotNode,
## then starting at a passed in Bone and going down the hierarchy,
## it gets all the bones in the chain (default case is left shoulder down).
## Afterwards, it inverts this by getting the bone count, and setting the filter
## of every bone not getting masked out.
## Finally, the filtered bone names are added to an array to be more efficiently cleared later.
## Enables or disables the filter on the OneShotNode.
## When enabled, starts from a specific bone (default: left shoulder) and walks
## down its child hierarchy (e.g. upper arm → forearm → hand).
## Then, inverts the filter by setting the filter on all bones *not* in that chain.
## This means only the selected chain will be affected by the one-shot animation.
## The function tracks all filtered bones in an array so they can be cleared later.
func set_filter_path(enabled: bool = true, in_bone: String = "DEF_shoulder.L.001") -> Array[String]:
	var filtered_bone_names: Array[String] = []

	# Enable or disable the filter on the blend node
	one_shot_blend.set_filter_enabled(enabled)

	# If filter is being disabled, we return an empty list immediately
	if enabled == false:
		return filtered_bone_names

	# Find the bone index for the starting bone name (e.g., DEF_shoulder.L.001)
	var bone: int = skeleton.find_bone(in_bone)
	if bone == -1:
		# If bone doesn't exist, exit early
		return filtered_bone_names

	# Collect the initial bone and all of its descendants
	var current_bone: int = bone
	var bone_decendants: Array[int] = [bone]

	# Traverse down the hierarchy starting from the initial bone.
	# This assumes a single chain (e.g. arm), not a complex branching structure.
	for i in 20:
		var bone_children: PackedInt32Array = skeleton.get_bone_children(current_bone)
		if bone_children.is_empty():
			break
		# Follow only the first child (linear chain assumption)
		bone_decendants.append(bone_children[0])
		current_bone = bone_children[0]

	# Get total bone count to iterate through the entire skeleton
	var skeleton_bone_count: int = skeleton.get_bone_count()

	# Loop through all bones in the skeleton
	for b in range(skeleton_bone_count):
		# Skip bones in the target chain (we don't want to filter those out)
		if b in bone_decendants:
			continue

		# For all other bones, set the filter path to TRUE (i.e., they will be ignored by the animation)
		var bone_name: String = skeleton.get_bone_name(b)
		one_shot_blend.set_filter_path(skeleton_node_path + ":" + bone_name, true)

		# Add the bone name to the return list for later clearing
		filtered_bone_names.append(bone_name)

		# Also add it to the persistent filter tracking list if it's not already there
		if !filtered_one_shot_bones.has(bone_name):
			filtered_one_shot_bones.append(bone_name)
	
	
	
	# Return the list of filtered bone names (for debugging or external use)
	return filtered_bone_names


## Masks out the specified arms from the animation
func set_one_shot_arm_masks(anim_mask: int = AnimationMask.NONE) -> void:
	var bone_names: Array[String] = []
	match anim_mask:
		#AnimationMask.NONE:
			#bone_names.append
		AnimationMask.LEFT:
			bone_names.append(left_shoulder_bone_name)
		AnimationMask.RIGHT:
			bone_names.append(right_shoulder_bone_name)
		AnimationMask.BOTH:
			bone_names.append(left_shoulder_bone_name)
			bone_names.append(right_shoulder_bone_name)
		#_:
		#	pass

	for bn in bone_names:
		set_filter_path(true, bn)


func clear_filter_path(bone_names: Array[String]) -> void:
	for b_name in bone_names:
		one_shot_blend.set_filter_path(skeleton_node_path + ":" + b_name, false)
		if filtered_one_shot_bones.has(b_name):
			filtered_one_shot_bones.erase(b_name)

func clear_all_filters() -> void:
	for b_name in filtered_one_shot_bones:
		one_shot_blend.set_filter_path(skeleton_node_path + ":" + b_name, false)

	filtered_one_shot_bones.clear()





func attack_anim(in_animation: Animation, in_miss: bool = false) -> void:
# Note: Later replace greatsword test with the animation library


	miss = in_miss

	if in_animation == null:
		push_error("Null attack animation")


	play_animation_by_name(in_animation.resource_name, 0.2, false, 2, false)



	await attack_completed


	return

func weapon_trail_toggle(weapon: Weapon = null) -> void:
	#var weapon: Weapon = unit.get_equipped_weapon()
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

		toggle_slowdown(0.1)
		await get_tree().create_timer(1.3).timeout
		toggle_slowdown()
		return
	trigger_camera_shake()
	toggle_slowdown()
	await get_tree().create_timer(0.4).timeout
	toggle_slowdown()


func emit_attack_completed() -> void:
	attack_completed.emit()

func emit_dodge_prompt() -> void:
	prompt_dodge.emit()

func emit_event_occurred() -> void:
	event_occured.emit()


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
	hit_fx.global_rotation = originator#chest_point.global_rotation

	hit_fx.get_child(0).emitting = true



func testprint() -> void:
	print_debug("AnimTestPrint")


func root_motion_process() -> void:
	var new_pos: Vector3 = animator_tree.get_root_motion_position()
	new_pos *= rig_root.get_scale()
	# Rotate the translation by the unit's current rotation
	new_pos = unit.get_global_transform().basis * new_pos
	new_pos += unit.get_global_position()

	if unit.get_global_position() != new_pos:
		#print_debug(new_pos)
		unit.set_global_position(new_pos)





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
func rotate_unit_towards_target_position(grid_position: GridPosition, rot_spd: float = 4.0) -> void:
	is_rotating = true
	facing_direction = (LevelGrid.get_world_position(grid_position) - unit.get_world_position()).normalized()
	rotate_speed = rot_spd
	await rotation_completed
	return


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
	var unit_slerp_basis: Basis = unit.global_transform.basis.slerp(tar_rot, delta * rotate_speed)
	unit.global_transform.basis = unit_slerp_basis.orthonormalized()

	# Check if the rotation is close enough to stop rotating
	var current_direction = unit.global_transform.basis.z.normalized()
	if current_direction.dot(facing_direction) > 0.9999:
		is_rotating = false  # Stop rotating if we're almost facing the target
		rotation_completed.emit()


func flash_color(color: Color = Color.DEEP_SKY_BLUE, flash_time: float = hit_flash_time, flash_weapon: bool = true) -> void:
	var unit_meshes: Array[MeshInstance3D] = get_character_mesh()
	if flash_weapon:
		var weapons: Array[Weapon] = unit.get_equipped_weapons()
		for weapon in weapons:
			if not weapon.category == "unarmed" and weapon.object:
				var weapon_mesh: MeshInstance3D = weapon.get_object()
				if weapon_mesh:
					unit_meshes.append(weapon_mesh)

	Utilities.flash_color_on_meshes(unit_meshes, color, flash_time)


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
	look_at_toggle(by_unit.body.get_part_marker("head"))


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
