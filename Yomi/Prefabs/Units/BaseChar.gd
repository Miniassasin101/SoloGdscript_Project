class_name BaseChar
extends Node3D

@export var ui_name: String = "null"
@export_category("References")
@export var state_machine: StateMachine

@export_group("Markers")
@export var above_marker: Marker3D


func _ready() -> void:
	pass


func setup_self() -> void:
	state_machine.start_machine()


func get_world_position_above_marker() -> Vector3:
	return above_marker.get_global_position()
