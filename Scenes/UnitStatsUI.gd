class_name UnitStatsUI
extends Control

@export var unit_manager: UnitManager
@export var unit_stats_bar_scene: PackedScene
@onready var unit_stats_container: VBoxContainer = $UnitStatsContainer/MarginContainer/UnitStatsContainer
@export var show_stats_for_all_units: bool = false  # Boolean to control stats bar creation for all units or just player units

# Dictionary to store references to each unit's stats bar
var unit_stats_bars: Dictionary = {}
var units_to_create_for: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiate_stats_bars()
	SignalBus.update_stat_bars.connect(_on_update_stats_bars)

# Instantiate a stats bar for each unit in the unit manager.
func instantiate_stats_bars() -> void:
	if unit_manager:
		# Remove all current children from the unit_stats_container
		for child in unit_stats_container.get_children():
			child.queue_free()

		# Clear the dictionary holding unit stats bar references
		unit_stats_bars.clear()

		# Choose units based on the boolean flag
		if show_stats_for_all_units:
			units_to_create_for = unit_manager.get_all_units()
		else:
			units_to_create_for = unit_manager.get_player_units()

		# Create a new stats bar for each selected unit
		for unit in units_to_create_for:
			var stats_bar = unit_stats_bar_scene.instantiate() as UnitStatsBar
			stats_bar.update_stats(unit)  # Initialize the stats with the current unit values
			unit_stats_container.add_child(stats_bar)
			unit_stats_bars[unit] = stats_bar

# Update stats bars whenever the global "update_stats_bars" signal is fired.
func _on_update_stats_bars() -> void:
	for unit in unit_stats_bars.keys():
		if is_instance_valid(unit):
			var stats_bar = unit_stats_bars[unit]
			stats_bar.update_stats(unit)
		else:
			# Remove stats bar if the unit no longer exists
			unit_stats_bars.erase(unit)
