class_name UnitActionSystem
extends Node

@export var selectedUnit: Unit 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_HandleUnitSelection()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		selectedUnit.update_target_position()

func _HandleUnitSelection() -> void:
	pass
