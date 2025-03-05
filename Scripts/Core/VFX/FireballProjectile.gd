class_name FireballProjectile
extends Node3D

signal target_hit

@export var speed: float = 30.0  # Units per second
@export var timer: float = 3.0   # Max travel time in seconds
@export var trail_3d: Trail3D
@export var fireball_hit_vfx: PackedScene

var miss: bool = false
var target_position: Vector3

func setup(_target_position: Vector3, _miss: bool) -> void:
	target_position = _target_position
	miss = _miss

func trigger_projectile() -> void:
	# Orient the projectile to face its target once.
	look_at(target_position, Vector3.UP, true)

	var start_pos: Vector3 = global_transform.origin
	var distance: float = start_pos.distance_to(target_position)
	var direction: Vector3 = (target_position - start_pos).normalized()

	# Calculate how many seconds it *would* take to travel the full distance at 'speed'.
	var travel_time: float = distance / speed

	# If the full travel time is longer than our allowed 'timer', 
	# we only move part of the way (speed * timer).
	var final_pos: Vector3
	if travel_time > timer:
		# Move only partially toward the target.
		travel_time = timer
		final_pos = start_pos + direction * (speed * timer)
	else:
		# We'll reach the target in less than 'timer' seconds.
		final_pos = target_position

	# Create and configure the tween.
	var tween = get_tree().create_tween()
	# Move this projectile from its current position to final_pos in travel_time seconds
	tween.tween_property(self, "global_transform:origin", final_pos, travel_time)

	# Once the tween finishes, call 'on_hit_target()'.
	tween.tween_callback(self.on_hit_target)

func on_hit_target() -> void:
	target_hit.emit()

	# If it's not a miss, snap to the exact target location and shake the camera
	if !miss:
		global_transform.origin = target_position
		trigger_camera_shake()

	remove_trail_effect()

	# Spawn the fireball effect if not a miss
	if fireball_hit_vfx and !miss:
		spawn_fireball_effect()

	queue_free()

func trigger_camera_shake() -> void:
	var strength = 0.15
	var shake_time = 0.3
	var shake_frequency = 50
	CameraShake.instance.shake(strength, shake_time, shake_frequency)

func remove_trail_effect() -> void:
	trail_3d.remove_on_completion = true
	trail_3d.trailEnabled = false
	trail_3d.reparent(get_parent())

func spawn_fireball_effect() -> void:
	var fireball_effect = fireball_hit_vfx.instantiate() as Node3D
	get_tree().root.add_child(fireball_effect)
	fireball_effect.global_transform.origin = target_position

	# Optionally start emitting if the scene's first child is GPUParticles3D
	if fireball_effect.get_child_count() > 0 and fireball_effect.get_child(0) is GPUParticles3D:
		fireball_effect.get_child(0).emitting = true
