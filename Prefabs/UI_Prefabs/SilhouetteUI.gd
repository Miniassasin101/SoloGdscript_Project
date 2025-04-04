extends Control
class_name SilhouetteUI

# Exported typed dictionary for color mapping.
@export var colors: Dictionary[String, Color] = {
	"blue": Color(0, 0, 1, 1),
	"orange": Color(1, 0.5, 0, 1),
	"red": Color(1, 0, 0, 1)
}

# List of expected body part node names.
var body_parts: Array[String] = [
	"Head",
	"Chest",
	"LeftArm",
	"RightArm",
	"Abdomen",
	"LeftLeg",
	"RightLeg"
]

func _ready() -> void:
	# Initialization if needed.
	pass

# Generic function to set a body part's color using a key from the colors dictionary.
func set_part_color_by_key(part_name: String, color_key: String) -> void:
	if not colors.has(color_key):
		push_warning("Color key not found: " + color_key)
		return

	var color_to_set: Color = colors[color_key]
	
	if has_node(part_name + "Image"):
		var part_node = get_node(part_name)
		part_node.modulate = color_to_set
	else:
		push_warning("No node found for body part: " + part_name)

# Convenience functions to set a specific body part to blue, orange, or red.
func set_part_blue(part_name: String) -> void:
	set_part_color_by_key(part_name, "blue")

func set_part_orange(part_name: String) -> void:
	set_part_color_by_key(part_name, "orange")

func set_part_red(part_name: String) -> void:
	set_part_color_by_key(part_name, "red")

# Optionally, set all body parts to a given color.
func set_all_parts_color_by_key(color_key: String) -> void:
	for part in body_parts:
		set_part_color_by_key(part, color_key)

# Optionally, reset all body parts to white.
func reset_all_parts() -> void:
	for part in body_parts:
		if has_node(part + "Image"):
			get_node(part + "Image").modulate = Color(1, 1, 1, 1)
