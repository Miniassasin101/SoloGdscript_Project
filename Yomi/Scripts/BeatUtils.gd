# BeatUtils
# Autoload Utilities
extends Node



# base multipliers for each letter rank
var rank_bases: Dictionary[String, float] = {
	"F": 1.500,
	"E": 1.200,
	"D": 1.000,
	"C": 0.850,
	"B": 0.750,
	"A": 0.600,
	"S": 0.500
}

# how many real beats → one displayed beat
var display_divisor: float = 5.0





func next_letter(letter:String) -> String:
	match letter:
		"F": return "E"
		"E": return "D"
		"D": return "C"
		"C": return "B"
		"B": return "A"
		"A": return "S"
		_:   return ""


# compute the exact multiplier for a sub‑tier, e.g. "E7" or "C1"
func get_multiplier(subrank:String) -> float:
	var letter: String = subrank.substr(0, 1)
	var base: float = rank_bases.get(letter, 1.0)
	if letter == "S":
		return base
	var next: float = rank_bases.get(next_letter(letter), base)
	var n: int = int(subrank.substr(1))  # 1 through 10
	var delta: float = (base - next) / 10.0
	return base - (10 - n) * delta

# convert real beats into a player‑friendly number
func get_display_beats(real_beats: float) -> int:
	return int(ceil(real_beats / display_divisor))



# Text Utilities
func spawn_text_line(in_unit: BaseChar, text: String, color: Color = Color.SNOW, scale: float = 1.0, at_pos: Vector3 = Vector3.ZERO) -> void:
	if !in_unit:
		return
	var add_to_q: bool = false
	if at_pos == Vector3.ZERO:
		add_to_q = true
		at_pos = in_unit.get_world_position_above_marker()
	var camera: Camera3D = get_viewport().get_camera_3d()
	var screen_pos: Vector2 = camera.unproject_position(at_pos)

	# Instance the label
	var text_label_scene: PackedScene = UILayer.instance.text_controller_scene
	var text_label = text_label_scene.instantiate() as TextController
	
	# Add to CharacterLogQueue instead of UILayer directly
	if add_to_q:
		UILayer.instance.get_node("CharacterLogQueue").add_message(text_label)
	else:
		UILayer.instance.add_child(text_label)

	# Position it in screen-space
	text_label.set_position(screen_pos)
	text_label.world_pos = at_pos
	text_label.set_scale(Vector2(scale, scale))
	text_label.set_text_color(color)

	# Initialize the label's text, color, etc.
	text_label.play(text)
