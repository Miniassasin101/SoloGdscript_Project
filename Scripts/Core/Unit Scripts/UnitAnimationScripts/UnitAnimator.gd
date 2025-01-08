### UnitAnimator.gd
class_name UnitAnimator
extends Node

# Signals
signal rotation_completed
signal movement_completed
signal attack_completed
# Exported Variables
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
# Variables
@onready var unit: Unit = get_parent()
var fireball_instance: Projectile
var move_action: MoveAction
var shoot_action: ShootAction
var target_unit: Unit
var stored_damage: int
var projectile: Projectile

# Neck Look Variables
var bone_smooth_rot: float = 0.0
var target_rotation: Quaternion
var is_looking: bool = false
var look_target: Node3D = null

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

# Ready Function - Called when the node enters the scene tree for the first time
func _ready() -> void:
	#call_deferred("connect_signals")
	SignalBus.equipment_changed.connect(equipment_anim_check)



# Physics Process - Called every frame to handle physics-related logic
func _physics_process(delta: float) -> void:
	if is_rotating:
		rotate_unit_towards_target_position_process(delta)
	if is_moving:
		move_along_curve_process(delta)
	if look_target and skeleton and is_looking:
		update_look_at(delta)

## Function to be used to trigger and disable looking at a target. Just needs to be called with no arguments to turn off.
func look_at_toggle(target: Node3D = null) -> void:
	if target == null:
		is_looking = false
	look_target = target
	is_looking = true

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
	
	# Calculate the neck's target rotation (look at target position)
	neck_target.look_at((look_target.global_position + Vector3(0.0, 0.3, 0.0)), Vector3.UP, true)
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
	animator_tree.set("parameters/conditions/IsWalking", true)

func equipment_anim_check(in_unit: Unit) -> void:
	if in_unit != unit:
		return
	if !unit.equipment.equipped_items.is_empty():
		weapon_setup(true)
		return
	weapon_setup(false)

func weapon_setup(weapon_type: bool) -> void:
	if weapon_type:
		animator_tree.set("parameters/RunCycleBlend/GreatswordBlend/blend_amount", 1.0)
		animator_tree.set("parameters/IdleBlend/GreatswordIdleBlend/blend_amount", 1.0)
		return
	animator_tree.set("parameters/RunCycleBlend/GreatswordBlend/blend_amount", 0.0)
	animator_tree.set("parameters/IdleBlend/GreatswordIdleBlend/blend_amount", 0.0)

func left_cast_anim(in_animation: Animation, in_miss: bool = false) -> void:
	# Note: Later replace greatsword test with the animation library
	miss = in_miss

	animator_tree.set("parameters/IdleBlend/LeftArmBlend/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)# or enum 1


	await attack_completed#timer.timeout

	return
	# Always add call method tracks for resolving the damage
	

func melee_attack_anim(in_animation: Animation, in_miss: bool = false) -> void:
# Note: Later replace greatsword test with the animation library
	look_at_toggle()
	miss = in_miss
	var root: AnimationNodeStateMachine = animator_tree.tree_root
	var attack: AnimationNodeBlendTree = root.get_node("Attack")
	var attack_anim: AnimationNodeAnimation = attack.get_node("AttackAnimation")
	var animation: StringName = attack_anim.get_animation()
	print("Old Animation: ", animation)
	var anim_path: String = ("GreatSwordTest1/" + in_animation.resource_name)
	attack_anim.set_animation(anim_path)
	#GreatSwordTest1/Greatsword_Swing_001

	#var is_attacking: bool = animator_tree.get("parameters/conditions/IsAttacking")
	animator_tree.set("parameters/conditions/IsAttacking", true)
	# Animation stand-in

	await attack_completed#timer.timeout
	animator_tree.set("parameters/conditions/IsAttacking", false)
	look_at_toggle(look_target)
	return
	# Always add call method tracks for resolving the damage


func attack_landed() -> void:
	attack_completed.emit()
	if miss:
		miss = false
		return
	trigger_camera_shake()




func trigger_camera_shake() -> void:
	var strength = 0.1 # the maximum shake strength. The higher, the messier
	var shake_time = 0.2 # how much it will last
	var shake_frequency = 50 # will apply 250 shakes per `shake_time`

	CameraShake.instance.shake(strength, shake_time, shake_frequency)


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
		var target_rotation = Basis.looking_at(move_direction, Vector3.UP, true)
		unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)
		unit.global_transform.basis = unit.global_transform.basis.orthonormalized()

	# Increment the travel offset along the curve
	curve_travel_offset += min(current_speed * delta, curve_length - curve_travel_offset)

# Rotation Functions
# Handles the start and process of rotating towards a target position
func rotate_unit_towards_target_position(grid_position: GridPosition) -> void:
	is_rotating = true
	facing_direction = (LevelGrid.get_world_position(grid_position) - unit.get_world_position()).normalized()

func rotate_unit_towards_target_position_process(delta: float):
	var target_rotation = Basis.looking_at(facing_direction, Vector3.UP, true)
	unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)
	unit.global_transform.basis = unit.global_transform.basis.orthonormalized()

	# Check if the rotation is close enough to stop rotating
	var current_direction = unit.global_transform.basis.z.normalized()
	if current_direction.dot(facing_direction) > 0.99:
		is_rotating = false  # Stop rotating if we're almost facing the target
		rotation_completed.emit()

# Movement State Handlers
func on_start_moving() -> void:
	animator_tree.set("parameters/conditions/IsWalking", true)

func on_stop_moving() -> void:
	animator_tree.set("parameters/conditions/IsWalking", false)
	is_moving = false
	movement_completed.emit()

# Shooting Functions
# Handles shooting a projectile towards a target
func on_shoot(target_unit_in: Unit, _shooting_unit: Unit, damage: int) -> void:
	if fireball_projectile_prefab and shoot_point:
		# Instantiate the fireball
		fireball_instance = fireball_projectile_prefab.instantiate()

		var target_unit_shoot_at_position: Vector3 = target_unit_in.get_position()
		print(target_unit_shoot_at_position.y)
		target_unit_shoot_at_position.y = shoot_point.global_position.y
		print(target_unit_shoot_at_position.y)
		
		# Add the fireball to the root or the appropriate scene node
		get_tree().root.add_child(fireball_instance)
		# Set the fireball's initial position
		fireball_instance.global_transform.origin = shoot_point.global_transform.origin
		fireball_instance.target_hit.connect(trigger_damage)
		fireball_instance.setup(target_unit_shoot_at_position, true)
		target_unit = target_unit_in
		stored_damage = damage

# Handles the damage triggering when the projectile hits the target
func trigger_damage() -> void:
	target_unit.damage(stored_damage)

# Connect Signals
# Connects signals from move and shoot actions
func connect_signals():
	move_action = unit.get_action("Move")
	shoot_action = unit.get_action("Shoot")
	if move_action:
		move_action.on_start_moving.connect(on_start_moving)
		move_action.on_stop_moving.connect(on_stop_moving)
	if shoot_action:
		shoot_action.on_shoot.connect(on_shoot)
