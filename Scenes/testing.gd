extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GridSystem.new(10, 10, 2.0)
