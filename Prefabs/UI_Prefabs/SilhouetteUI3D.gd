extends Node3D
class_name SilhouetteUI3D

# Exported dictionary for color mapping.
# You can adjust these colors in the Inspector.
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

var is_pulsing: bool = false

func _ready() -> void:
	# Optional: Warn if any expected body part is missing.
	for part in body_parts:
		if not has_node(part):
			push_warning("Silhouette3D is missing part: " + part)

# Generic function to set a body part's color using a key from the colors dictionary,
# and trigger a scale pulse effect.
func set_part_color_by_key(part_name: String, color_key: String) -> void:
	if not colors.has(color_key):
		push_warning("Color key not found: " + color_key)
		return
	var color_to_set: Color = colors[color_key]
	if has_node(part_name):
		var sprite = get_node(part_name) as Sprite3D
		# Set the color
		sprite.modulate = color_to_set
		
		# --- Pulse Animation ---
		if is_pulsing:
			return
		is_pulsing = true
		# Get the sprite's current scale.
		var original_scale: Vector3 = sprite.scale
		# Define a pulse scale factor (e.g. 20% larger).
		var pulse_scale: Vector3 = original_scale * 1.2
		# Create a tween to animate the scale pulse.
		var tween: Tween = get_tree().create_tween()
		# Scale up quickly.
		tween.tween_property(sprite, "scale", pulse_scale, 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		# Then scale back to original.
		tween.tween_property(sprite, "scale", original_scale, 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN)
		await tween.finished
		is_pulsing = false
	else:
		push_warning("Body part not found: " + part_name)

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

# Reset all body parts to white.
func reset_all_parts_color() -> void:
	for part in body_parts:
		if has_node(part):
			var sprite = get_node(part) as Sprite3D
			sprite.modulate = Color(1, 1, 1, 1)
