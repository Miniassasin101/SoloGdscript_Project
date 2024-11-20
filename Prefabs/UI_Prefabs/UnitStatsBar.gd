class_name UnitStatsBar
extends PanelContainer

@export var unit_name_label: Label
@export var action_points_label: Label
@export var health_text_label: Label
@export var health_bar: TextureProgressBar


func _ready() -> void:
	pass

# Update the stats bar with the given unit's stats
func update_stats(unit: Unit) -> void:
	unit_name_label.text = unit.name
	action_points_label.text = str(unit.get_action_points())
	health_text_label.text = "Health: %d / %d" % [unit.health_system.current_health, unit.health_system.max_health]
	#health_bar.set_value_no_signal(float(unit.health_system.current_health) / unit.health_system.max_health * 100)
	
	
	# Calculate the target health percentage
	var target_health_percentage = float(unit.health_system.current_health) / unit.health_system.max_health * 100

	# Create a tween to animate the health bar value
	var tween = create_tween()
	tween.tween_property(health_bar, "value", target_health_percentage, .4)  # Animate over 0.5 seconds
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
