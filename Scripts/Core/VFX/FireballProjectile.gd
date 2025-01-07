class_name Projectile
extends Node3D

signal target_hit

@export var speed: float = 30.0  # Speed at which the projectile travels
@export var timer: float = 3.0  # Duration in seconds for how long the projectile will travel
@export var trail_3d: Trail3D
@export var fireball_hit_vfx: PackedScene
var miss: bool = false
var target_position: Vector3 

func setup(_target_position: Vector3, _miss: bool) -> void:
	target_position = _target_position
	miss = _miss
	
	


	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer > 0:
		check_collision(delta)
	else:
		on_hit_target()  # Queue the projectile for deletion after the timer runs out

func trigger_projectile():
	pass

# Moves the projectile towards the target position
func move_projectile(delta: float) -> void:
	var move_direction = (target_position - global_transform.origin).normalized()
	look_at(target_position, Vector3.UP, true)  # Orient towards the target
	global_translate(move_direction * speed * delta)  # Move in the direction at the given speed
	timer -= delta  # Decrease the timer

# Checks if the projectile has reached or passed the target
func check_collision(delta: float) -> void:
	var distance_before_moving = global_transform.origin.distance_to(target_position)
	move_projectile(delta)

	var distance_after_moving = (global_transform.origin).distance_to(target_position)
	if distance_before_moving < distance_after_moving:
		on_hit_target()

# Handles what happens when the projectile hits the target
func on_hit_target() -> void:
	# Snap to target position
	global_transform.origin = target_position
	target_hit.emit()
	
	if !miss:
		trigger_camera_shake()

	# Handle trail effect
	remove_trail_effect()

	# Spawn the fireball hit effect
	if fireball_hit_vfx and !miss:
		spawn_fireball_effect()

	# Queue the projectile for deletion
	queue_free()

func trigger_camera_shake() -> void:
	var strength = 0.15 # the maximum shake strength. The higher, the messier
	var shake_time = 0.3 # how much it will last
	var shake_frequency = 50 # will apply 'n' shakes per `shake_time`

	CameraShake.instance.shake(strength, shake_time, shake_frequency)

# Handles the trail effect removal and cleanup
func remove_trail_effect() -> void:
	trail_3d.remove_on_completion = true
	trail_3d.trailEnabled = false

	trail_3d.reparent(self.get_parent())

# Spawns the fireball hit VFX at the target position
func spawn_fireball_effect() -> void:
	var fireball_effect = fireball_hit_vfx.instantiate() as Node3D
	get_tree().root.add_child(fireball_effect)
	fireball_effect.global_transform.origin = target_position
	if fireball_effect.get_child_count() > 0 and fireball_effect.get_child(0) is GPUParticles3D:
		fireball_effect.get_child(0).emitting = true
