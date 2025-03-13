class_name UnitStatsBar
extends PanelContainer

@export var unit_name_label: Label
@export var action_points_label: Label
@export var movement_points_label: Label
@export var health_text_label: Label
@export var health_bar: TextureProgressBar


func _ready() -> void:
	pass

# Update the stats bar with the given unit's stats
func update_stats(unit: Unit) -> void:
	var move_rate = unit.attribute_map.get_attribute_by_name("movement_rate").current_buffed_value
	var speed_multiplier = Utilities.GAIT_SPEED_MULTIPLIER.get(unit.current_gait)
	unit_name_label.text = unit.name

	action_points_label.set_text(str(int(unit.attribute_map.get_attribute_by_name("action_points").current_value)))
	movement_points_label.set_text("MOV: " + str(int(((move_rate * speed_multiplier)/2) - unit.distance_moved_this_turn)))
	health_text_label.text = "Health: %d / %d" % [unit.attribute_map.get_attribute_by_name("health").current_value, 
	unit.attribute_map.get_attribute_by_name("health").maximum_value]

	
	
	# Calculate the target health percentage
	var target_health_percentage = (float(unit.attribute_map.get_attribute_by_name("health").current_value) / 
	unit.attribute_map.get_attribute_by_name("health").maximum_value * 100)

	# Create a tween to animate the health bar value
	var tween = create_tween()
	tween.tween_property(health_bar, "value", target_health_percentage, .4)  # Animate over 0.4 seconds
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
