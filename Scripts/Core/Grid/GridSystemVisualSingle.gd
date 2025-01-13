class_name GridSystemVisualSingle
extends Node3D

@export var grid_system_visual: MeshInstance3D
@export var grid_system_visual_red: MeshInstance3D


# Called to update visuals for this cell
func update_visual(is_red: bool) -> void:
	grid_system_visual.visible = not is_red
	grid_system_visual_red.visible = is_red

# Example usage in the script
func set_difficult_terrain(is_difficult: bool) -> void:
	update_visual(is_difficult)



func _show() -> void:
	grid_system_visual.visible = true
	grid_system_visual_red.visible = true

func hide_self() -> void:
	grid_system_visual.visible = false
	grid_system_visual_red.visible = false
