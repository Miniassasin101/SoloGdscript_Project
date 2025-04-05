class_name UnitStatsBar
extends PanelContainer

@export var unit_name_label: Label
@export var action_points_label: Label
@export var movement_points_label: Label
@export var health_text_label: Label
@export var health_bar: TextureProgressBar

@export var shadowed_stylebox: StyleBoxFlat
@export var flat_stylebox: StyleBoxFlat

# Drift tweakable properties:
@export var drift_amount: float = 20.0   # Pixels to drift right.
@export var drift_duration: float = 2.0    # Duration (in seconds) for one half of the drift.

# Reference to the drift tween.
var drift_tween: Tween = null
# Store the original position.
var base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set initial stylebox override.
	add_theme_stylebox_override("panel", shadowed_stylebox)
	# Store the initial position so we can reset later.
	base_position = get_position()

# Update the stats bar with the given unit's stats.
func update_stats(unit: Unit) -> void:
	var move_rate = unit.attribute_map.get_attribute_by_name("movement_rate").current_buffed_value
	var speed_multiplier = Utilities.GAIT_SPEED_MULTIPLIER.get(unit.current_gait)
	unit_name_label.text = unit.ui_name
	
	action_points_label.text = str(int(unit.attribute_map.get_attribute_by_name("action_points").current_value))
	movement_points_label.text = "MOV: " + str(int(((move_rate * speed_multiplier) / 2) - unit.distance_moved_this_turn))
	health_text_label.text = "Health: %d / %d" % [
		unit.attribute_map.get_attribute_by_name("health").current_value, 
		unit.attribute_map.get_attribute_by_name("health").maximum_value
	]
	
	# Animate the health bar value.
	var target_health_percentage = (float(unit.attribute_map.get_attribute_by_name("health").current_value) /
		unit.attribute_map.get_attribute_by_name("health").maximum_value * 100)
	var tween = create_tween()
	tween.tween_property(health_bar, "value", target_health_percentage, 0.4) \
		 .set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	# Change the stylebox based on whether this unit has already acted.
	if TurnSystem.instance and TurnSystem.instance.has_taken_proactive_action_this_cycle(unit):
		add_theme_stylebox_override("panel", flat_stylebox)
	else:
		add_theme_stylebox_override("panel", shadowed_stylebox)

# Call this function to start the drift animation.
func start_drift() -> void:
	# If already drifting, do nothing.
	if drift_tween:
		return
	base_position = position
	var final_position: Vector2 = Vector2(base_position.x + drift_amount, base_position.y)
	drift_tween = get_tree().create_tween()
	drift_tween.set_loops(50)  # Loop indefinitely.
	drift_tween.tween_property(self, "position", final_position, drift_duration) \
			   .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift_tween.tween_property(self, "position", base_position, drift_duration) \
			   .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Call this function to stop the drift and reset the position.
func stop_drift() -> void:
	if drift_tween:
		drift_tween.kill()
		drift_tween = null
		position = base_position
