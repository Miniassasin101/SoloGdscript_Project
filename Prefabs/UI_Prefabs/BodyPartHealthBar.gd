extends HBoxContainer
class_name BodyPartHealthBar

@export var colors: Dictionary[String, Color] = {
	"blue": Color(0.149, 0.633, 0.922),
	"orange": Color(0.823, 0.623, 0.153),
	"red": Color(0.864, 0.117, 0.315)
}

@export var body_part_name_label: Label
@export var body_part_health_bar_under: TextureProgressBar
@export var body_part_health_bar_middle: TextureProgressBar
@export var body_part_health_bar_above: TextureProgressBar

@export var damage_range_label: Label     # For displaying "min - max" damage range
@export var health_points_label: Label


@export var body_part: BodyPart = null
@export var body_part_name: String = "n/a"
@export var body_part_health: int = 0

# Minimum and maximum damage (set via the UI or calculated from a dice expression)
@export var min_damage: int = 0
@export var max_damage: int = 0

# Helper: a very basic armor reduction calculation.
func apply_armor_reduction(hp: float, damage: float) -> float:
	var armor_value = body_part.get_armor()   # Example armor constant; adjust as needed.
	var effective_damage = max(damage - armor_value, 0)
	return hp - effective_damage

# Called to set up the body part info.
func init_body_part(in_body_part: BodyPart) -> void:
	body_part = in_body_part
	body_part_name = body_part.part_ui_name
	body_part_name_label.text = body_part_name
	body_part_health = body_part.body.get_part_health(in_body_part.part_name)


func get_color_for_hp(hp_value: float, max_hp: float) -> Color:
	# Returns blue if hp_value is >= 0, orange if hp_value is below 0 but above -max_hp, and red if hp_value is <= -max_hp.
	if hp_value >= 0:
		return colors["blue"]
	elif hp_value > -max_hp:
		return colors["orange"]
	else:
		return colors["red"]


# Call this whenever HP changes or a new damage forecast is to be displayed.
func update_body_part_health(current_hp: float, max_hp: float) -> void:
	# Clamp current_hp so it does not drop below -max_hp.
	var clamped_hp = current_hp
	if clamped_hp < -max_hp:
		clamped_hp = -max_hp

	# Set the max_value for all three bars.
	body_part_health_bar_above.max_value = max_hp
	body_part_health_bar_middle.max_value = max_hp
	body_part_health_bar_under.max_value = max_hp

	# Compute predicted HP after damage (post armor reduction)
	var predicted_hp_after_max = apply_armor_reduction(clamped_hp, max_damage)
	var predicted_hp_after_min = apply_armor_reduction(clamped_hp, min_damage)

	# Convert negative predicted HP to a display value.
	# If the predicted HP is negative, add max_hp to convert it to a value between 0 and max_hp.
	var disp_value_max = predicted_hp_after_max if predicted_hp_after_max >= 0 else max_hp + predicted_hp_after_max
	var disp_value_min = predicted_hp_after_min if predicted_hp_after_min >= 0 else max_hp + predicted_hp_after_min

	# Determine the primary color based on the predicted value.
	var primary_color: Color = get_color_for_hp(predicted_hp_after_max, max_hp)
	
	# --- Health Bar Above ---
	# Uses the original progress bar color (primary_color) with a transparent under tint.
	body_part_health_bar_above.value = clamp(disp_value_max, 0, max_hp)
	body_part_health_bar_above.tint_progress = primary_color
	body_part_health_bar_above.tint_under = Color(0, 0, 0, 0)  # Clear under tint

	# --- Health Bar Middle ---
	# Uses a lighter version of the primary color.
	var lighter_color = primary_color.lerp(Color(1, 1, 1), 0.5)
	body_part_health_bar_middle.value = clamp(disp_value_min, 0, max_hp)
	body_part_health_bar_middle.tint_progress = lighter_color
	body_part_health_bar_middle.tint_under = Color(0, 0, 0, 0)  # Clear under tint

	# --- Health Bar Under ---
	# Determine the next tier color.
	var next_tier_color: Color = colors["orange"]
	if primary_color == colors["orange"]:
		next_tier_color = colors["red"]
	if primary_color == colors["red"]:
		next_tier_color = colors["red"]

	# For the under bar, fill it completely and use a nearly white fill.
	body_part_health_bar_under.value = max_hp
	body_part_health_bar_under.tint_progress = next_tier_color#Color(0.95, 0.95, 0.95, 1)  # Almost white
	body_part_health_bar_under.tint_under = next_tier_color

	# Optionally update damage range and HP labels.
	var dmg_text: String = "%d - %d DMG" % [maxi(min_damage - body_part.get_armor(), 0), maxi(max_damage - body_part.get_armor(), 0)]
	if damage_range_label:
		damage_range_label.text = dmg_text
		
	if health_points_label:
		health_points_label.text = "%d / %d" % [clamped_hp, max_hp]


func set_max_damage(_max_damage: int) -> void:
	max_damage = _max_damage
