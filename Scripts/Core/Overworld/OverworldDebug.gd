class_name OverworldDebug extends Node


@export var overworld_manager: OverworldManager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func test_c() -> void:
	if Input.is_action_just_pressed("testkey_c"):
		pass
