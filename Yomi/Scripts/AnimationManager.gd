class_name AnimationManager
extends Node


@export var animator: AnimationPlayer
@export var animator_tree: AnimationTree

@export var skeleton: Node3D



func get_character_mesh() -> Array[MeshInstance3D]:
	var ret_array: Array[MeshInstance3D] = []
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			ret_array.append(child as MeshInstance3D)

	return ret_array
