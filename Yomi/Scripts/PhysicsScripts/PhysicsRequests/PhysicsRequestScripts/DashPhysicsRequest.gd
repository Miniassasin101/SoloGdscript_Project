class_name DashPhysicsRequest
extends PhysicsRequest

@export var strength: float = 15.0

func _init(in_val: float) -> void:
	strength = in_val

func apply(to: BaseChar) -> void:
	var back_dir := to.global_transform.basis.z
	to.apply_central_impulse(back_dir * strength)
