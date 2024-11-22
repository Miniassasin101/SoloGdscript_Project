class_name LevelDebug
extends Node

# Manages a lot of the debug settings and variables
static var instance: LevelDebug = null

@export var end_turn_debug: bool
@export_category("Grid Debug")
@export var grid_dimensions: Vector2 = Vector2(10, 10)
@export var grid_scale: float = 2.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if instance != null:
		push_error("There's more than one Level! - " + str(instance))
		queue_free()
		return
	instance = self
	LevelGrid.generate_grid_system(int(grid_dimensions.x), int(grid_dimensions.y), grid_scale)
