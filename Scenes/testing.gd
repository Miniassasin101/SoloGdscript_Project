class_name Testing
extends Node3D

@export var unit: Unit
@onready var unit_action_system: UnitActionSystem = $"../UnitActionSystem"

# Called when the node enters the scene tree for the first time.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("testkey"):
		pass
