class_name Unit

extends Node3D
## Unit base class that contains functionality general to all units in combat

var target_position: Vector3

func _process(delta: float) -> void:
	var stoppingDistance: float = 0.1
	if (global_transform.origin.distance_to(target_position) > stoppingDistance):
		var move_direction = (target_position - global_transform.origin).normalized()
		var move_speed = 4.0
		global_transform.origin += move_direction * move_speed * delta
	if Input.is_action_just_pressed("testkey"):
		move(Vector3(4, 0, 4))

func move(target_position: Vector3) -> void:
	self.target_position = target_position
