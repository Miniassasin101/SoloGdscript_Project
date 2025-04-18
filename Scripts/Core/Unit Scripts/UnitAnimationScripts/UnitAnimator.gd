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
# Exported Variables
@export_category("References")
@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree
@export var fireball_projectile_prefab: PackedScene
@export var shoot_point: Node3D
@export var look_at_modifier: LookAtModifier3D
@export var height_offset: float = 1.5  # Height offset to aim towards upper body
@export var skeleton: Skeleton3D
@export var rig_root: Node3D







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


# Root Motion Variables
var is_root_motion: bool = false


# Attack Variables:
var miss: bool = false
var weapon_trail_is_active: bool = false


# Ready Function - Called when the node enters the scene tree for the first time
func _ready() -> void:
	#call_deferred("connect_signals")
	SignalBus.equipment_changed.connect(equipment_anim_check)
	make_tree_root_unique()





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


func equipment_anim_check(in_unit: Unit) -> void:
	if in_unit != unit:
		return
	if !unit.equipment.equipped_items.is_empty():
		var active_weapon: Weapon = unit.equipment.get_equipped_weapon()
		weapon_setup(true, active_weapon)
		return
	weapon_setup(false)

func make_tree_root_unique() -> void:
	animator_tree.set_tree_root(animator_tree.tree_root.duplicate(true))

func weapon_setup(weapon_type: bool, weapon: Weapon = null) -> void:
	var tween: Tween = get_tree().create_tween()

	if weapon_type and weapon:
		var root: AnimationNodeStateMachine = animator_tree.tree_root as AnimationNodeStateMachine
		if root == null:
			push_error("AnimationTree does not have a valid StateMachine root.")
			return
	
		var main: AnimationNodeBlendTree = root.get_node("Main")
		
		var state_machine: AnimationNodeStateMachine = main.get_node("AnimationNodeStateMachine")
		
		var idleblend: AnimationNodeBlendTree = state_machine.get_node("IdleBlend")
		
		var runblend: AnimationNodeBlendTree = state_machine.get_node("RunCycleBlend")
		
		var weapon_idle: AnimationNodeAnimation = idleblend.get_node("WeaponIdle")
		
		var left_arm_anim: AnimationNodeAnimation = runblend.get_node("LeftArmAnimation")
		
		var right_arm_anim: AnimationNodeAnimation = runblend.get_node("RightArmAnimation")
		
		var anim_path: String = ("HumanoidAnimLib01/" + weapon.idle_animation.resource_name)
		
		weapon_idle.set_animation(anim_path)
		
		left_arm_anim.set_animation(anim_path)
		right_arm_anim.set_animation(anim_path)
		
		if weapon.hands == 1:
			if weapon.tags.has("right_hand"):
				animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmAnimation/animation", anim_path)
				#animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmAnimation/animation", anim_path)
		
				tween.tween_property(animator_tree, "parameters/Main/AnimationNodeStateMachine/IdleBlend/WeaponIdleBlend/blend_amount", 1.0, 0.7)
				animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmBlend/blend_amount", 1.0)
				animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmBlend/blend_amount", 0.0)
				return
			elif weapon.tags.has("left_hand"):
				#animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmAnimation/animation", anim_path)
				animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmAnimation/animation", anim_path)
		
				tween.tween_property(animator_tree, "parameters/Main/AnimationNodeStateMachine/IdleBlend/WeaponIdleBlend/blend_amount", 1.0, 0.7)
				animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmBlend/blend_amount", 0.0)
				animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmBlend/blend_amount", 1.0)
				return
		
		animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmAnimation/animation", anim_path)
		animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmAnimation/animation", anim_path)
		
		tween.tween_property(animator_tree, "parameters/Main/AnimationNodeStateMachine/IdleBlend/WeaponIdleBlend/blend_amount", 1.0, 0.7)
		animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmBlend/blend_amount", 1.0)
		animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmBlend/blend_amount", 1.0)
		return
	
	
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/RightArmBlend/blend_amount", 0.0)
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/RunCycleBlend/LeftArmBlend/blend_amount", 0.0)
	tween.tween_property(animator_tree, "parameters/Main/AnimationNodeStateMachine/IdleBlend/WeaponIdleBlend/blend_amount", 0.0, 0.7)

func left_cast_anim(_in_animation: Animation, in_miss: bool = false) -> void:
	# Note: Later replace greatsword test with the animation library
	miss = in_miss

	animator_tree.set("parameters/Main/AnimationNodeStateMachine/IdleBlend/LeftArmBlend/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)# or enum 1


	await attack_completed#timer.timeout

	return
	# Always add call method tracks for resolving the damage
	
func play_animation_by_name(animation_name: String, blend_time: float = 0.2, use_root_motion: bool = false) -> void:
	# Get the AnimationTree's state machine root
	var root: AnimationNodeStateMachine = animator_tree.tree_root as AnimationNodeStateMachine
	if root == null:
		push_error("AnimationTree does not have a valid StateMachine root.")
		return
	
	var main: AnimationNodeBlendTree = root.get_node("Main")
	
	var one_shot: AnimationNodeAnimation = main.get_node("OneShotAnimation")
	
	var one_shot_blend: AnimationNodeOneShot = main.get_node("OneShotBlend")
	
	var anim_path: String = ("HumanoidAnimLib01/" + animation_name)
	
	one_shot_blend.set_fadein_time(blend_time)
	one_shot_blend.set_fadeout_time(blend_time)
	
	one_shot.set_animation(anim_path)
	
	#one_shot_node.set("request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	animator_tree.set("parameters/Main/OneShotBlend/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	print("firing: ", anim_path)
	var anim: Animation = animator.get_animation(anim_path)
	
	is_root_motion = use_root_motion
	
	await get_tree().create_timer(anim.length / timescale_multiplier).timeout
	
	is_root_motion = false
	print("done")
	return




	# NOTE: Always add call method tracks for resolving the damage
func attack_anim(in_animation: Animation, in_miss: bool = false) -> void:
# Note: Later replace greatsword test with the animation library
	#look_at_toggle()

	miss = in_miss
	var root: AnimationNodeStateMachine = animator_tree.tree_root
	var main: AnimationNodeBlendTree = root.get_node("Main")
	var state_mach: AnimationNodeStateMachine = main.get_node("AnimationNodeStateMachine")
	var attack: AnimationNodeBlendTree = state_mach.get_node("Attack")
	var att_anim: AnimationNodeAnimation = attack.get_node("AttackAnimation")
	var animation: StringName = att_anim.get_animation()
	print_debug("Old Animation: ", animation)
	var anim_path: String = ("HumanoidAnimLib01/" + in_animation.resource_name)
	att_anim.set_animation(anim_path)
	#HumanoidAnimLib01/Greatsword_Swing_001

	#var is_attacking: bool = animator_tree.get("parameters/conditions/IsAttacking")
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/conditions/IsAttacking", true)
	# Animation stand-in

	await attack_completed#timer.timeout
	animator_tree.set("parameters/Main/AnimationNodeStateMachine/conditions/IsAttacking", false)
	#look_at_toggle(look_target)

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
