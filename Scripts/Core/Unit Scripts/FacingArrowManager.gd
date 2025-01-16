class_name FacingArrowManager
extends Node3D

# Reference to the parent unit
@export var unit: Unit

# Rotation speed of the arrow
@export var rotate_speed: float = 5.0

# Internal state for managing rotation
var is_rotating: bool = false
var target_rotation: Basis

func _ready() -> void:
	# Connect to the unit's facing change signal, if it exists
	if unit.has_method("set_facing"):
		unit.facing_changed.connect(_on_facing_changed)
	#rotate_arrow_towards_facing(unit.facing)


func _process(delta: float) -> void:
	if is_rotating:
		# Smoothly interpolate to the target rotation
		global_transform.basis = global_transform.basis.slerp(target_rotation, delta * rotate_speed)
		global_transform.basis = global_transform.basis.orthonormalized()
		
		# Check if the rotation is close enough to stop
		if global_transform.basis.z.normalized().dot(target_rotation.z.normalized()) > 0.9999:
			is_rotating = false
			global_transform.basis = target_rotation

# Called when the unit's facing changes
func _on_facing_changed(new_facing: int) -> void:
	rotate_arrow_towards_facing(new_facing)

func set_arrow_visibility(is_visible: bool) -> void:
	set_visible(is_visible)

# Rotate the arrow towards the unit's new facing direction
func rotate_arrow_towards_facing(new_facing: int) -> void:
	var direction: Vector3
	match new_facing:
		2:  # South
			direction = Vector3(0, 0, -1)
		3:  # East
			direction = Vector3(1, 0, 0)
		0:  # North
			direction = Vector3(0, 0, 1)
		1:  # West
			direction = Vector3(-1, 0, 0)
	
	# Calculate the target rotation
	target_rotation = Basis().looking_at(direction, Vector3.UP)
	is_rotating = true
