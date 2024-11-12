class_name Testing
extends Node3D

@export var unit: Unit
# Called when the node enters the scene tree for the first time.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("testkey"):
		unit.get_move_action().get_valid_action_grid_position_list()
