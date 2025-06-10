class_name UnitStatsBarsUI
extends Control

@export var char_manager: CharManager
@export var unit_stats_bar_scene: PackedScene
@export var unit_stats_container: VBoxContainer
@export var show_stats_for_all_units: bool = false  # Boolean to control stats bar creation for all units or just player units

# Dictionary to store references to each unit's stats bar
var unit_stats_bars: Dictionary = {}
var units_to_create_for: Array = []




# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	EventBus.on_unit_added.connect(instantiate_stats_bars)
	EventBus.on_unit_removed.connect(instantiate_stats_bars)
	
	UIBus.on_ui_update.connect(_on_update_stats_bars)
	UIBus.instantiate_stats_bars.connect(instantiate_stats_bars)
	UIBus.update_stat_bars.connect(_on_update_stats_bars)



func instantiate_stats_bars(_unit: Unit = null) -> void:
	if char_manager:
		# Remove all current children from the container.
		for child: UnitStatsBar in unit_stats_container.get_children():
			child.abort_tween()
			child.queue_free()
		unit_stats_bars.clear()

		# Get the units based on your flag.
		if show_stats_for_all_units:
			units_to_create_for = char_manager.get_all_units()
		else:
			units_to_create_for = char_manager.get_all_units()



		# Create a stats bar for each unit in the ordered array.
		for unit in units_to_create_for:
			var stats_bar = unit_stats_bar_scene.instantiate() as UnitStatsBar
			stats_bar.update_stats(unit)  # Initialize with current values.
			unit_stats_container.add_child(stats_bar)
			unit_stats_bars[unit] = stats_bar
		


func _on_update_stats_bars() -> void:
	for unit: Unit in unit_stats_bars.keys():
		if is_instance_valid(unit):
			var stats_bar: UnitStatsBar = unit_stats_bars[unit]
			stats_bar.update_stats(unit)
			if unit.turn_state == Unit.TurnState.TURN_STARTED: #unit == TurnSystem.instance.current_unit_turn:
				stats_bar.start_drift()
			else:
				stats_bar.stop_drift()
		else:
			unit_stats_bars.erase(unit)
