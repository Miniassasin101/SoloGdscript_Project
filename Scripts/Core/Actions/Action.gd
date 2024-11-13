class_name Action
extends Node


var is_active: bool
var unit: Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
