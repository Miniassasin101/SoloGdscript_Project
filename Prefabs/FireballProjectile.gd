class_name Projectile
extends Node3D

@export var speed: float = 50.0  # Speed at which the projectile travels
@export var timer: float = 2.0  # Duration in seconds for how long the projectile will travel
var target_position: Vector3 

@export var trail_3d: Trail3D
@export var fireball_hit_vfx: PackedScene

func setup(target_position: Vector3) -> void:
	self.target_position = target_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var move_direction = (target_position - global_transform.origin).normalized()

	if timer > 0:
		var distance_before_moving = global_transform.origin.distance_to(target_position)
		# Move the projectile in the desired direction at the specified speed
		global_translate(move_direction * speed * delta)
		var distance_after_moving = global_transform.origin.distance_to(target_position)
		# Decrease the timer to stop movement after one second
		timer -= delta

		if distance_before_moving < distance_after_moving:
			# The projectile has reached or passed the target
			global_transform.origin = target_position  # Snap to target position
			
			# Handle the trail effect
			trail_3d.remove_on_completion = true
			trail_3d.trailEnabled = false
			remove_child(trail_3d)
			get_tree().root.add_child(trail_3d)
			
			# Spawn the fireball hit effect at the target position
			if fireball_hit_vfx:
				var fireball_effect = fireball_hit_vfx.instantiate() as Node3D
				get_tree().root.add_child(fireball_effect)
				fireball_effect.global_transform.origin = target_position
				fireball_effect.get_child(0).emitting = true

			# Queue the projectile for deletion
			queue_free()
	else:
		# Queue the projectile for deletion after the timer runs out
		queue_free()
