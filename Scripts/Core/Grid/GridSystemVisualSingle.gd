class_name GridSystemVisualSingle
extends Node3D

@export var mesh_renderer: MeshInstance3D
# Called when the node enters the scene tree for the first time.

func _init() -> void:
	pass
	
func _ready() -> void:
	pass # Replace with function body.

func _show() -> void:
	mesh_renderer.visible = true


func hide_self() -> void:
	mesh_renderer.visible = false
