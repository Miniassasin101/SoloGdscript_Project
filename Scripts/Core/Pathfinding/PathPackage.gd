class_name PathPackage extends RefCounted

var path: Array[GridPosition] = []
var path_cost: float
var neighbors: Array[GridPosition] = []

# Constructor
func _init(in_path_cost: float = INF) -> void:
	path_cost = in_path_cost

# Setters
func set_path(in_path: Array[GridPosition]) -> void:
	path = in_path

func set_cost(in_path_cost: float) -> void:
	path_cost = in_path_cost

func set_neighbors(in_neighbors: Array[GridPosition]) -> void:
	neighbors = in_neighbors

# Getters
func get_path() -> Array[GridPosition]:
	return path

func get_cost() -> float:
	return path_cost

func get_neighbors() -> Array[GridPosition]:
	return neighbors
