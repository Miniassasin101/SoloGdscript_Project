extends Label


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	set_text("FPS %d" % Engine.get_frames_per_second())
