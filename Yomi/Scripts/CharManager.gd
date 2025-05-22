class_name CharManager
extends Node

var is_started: bool = false

var units: Array[Unit] = []

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if is_started:
		return
	if Input.is_action_just_pressed("testkey_n"):
		initialize_units()
		is_started = true


func initialize_units() -> void:
	# Iterate through all children and add those of type Unit to the units array
	for child in get_children():
		if child is BaseChar:
			units.append(child)
			
			BeatUtils.spawn_text_line(child, "Added")
