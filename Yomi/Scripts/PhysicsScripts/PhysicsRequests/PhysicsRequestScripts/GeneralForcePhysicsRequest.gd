class_name GeneralForcePhysicsRequest
extends PhysicsRequest

@export var direction: Vector3 = Vector3.ZERO
@export var strength: float = 30.0

func _init(in_direction: Vector3, in_strength: float) -> void:
	direction = in_direction
	strength = in_strength

func apply(to: BaseChar) -> void:
	to.apply_central_force(direction * strength)
