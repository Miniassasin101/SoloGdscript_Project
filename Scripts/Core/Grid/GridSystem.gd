class_name GridSystem
extends Node


var width: int
var height: int
var cellSize: float

func _init(inwidth, inheight, incellsize: float) -> void:
	var width = inwidth
	var height = inheight
	var cellSize = incellsize
# Draw the grid lines
	for x in range(width):
		for z in range(height):
			.(get_world_position(x, z)

func get_world_position(x: int, z: int):
	return Vector3(x, 0, z) * cellSize
	begin(Mesh.PRIMITIVE_LINES)

func get_grid_position():
	
