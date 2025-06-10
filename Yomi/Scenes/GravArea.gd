class_name GravArea
extends Area3D

@export var gravity_scale: float = 1.0

func apply_gravity(body: Node3D) -> void:
	if not body is BaseChar:
		return
	var char: BaseChar = body as BaseChar
	char.apply_central_impulse(gravity_direction * gravity_scale)
