#SignalBus.gd
#Autoloaded Singleton
extends Node


signal selected_unit_changed(unit: Unit)

signal selected_action_changed(action: Action)

signal update_grid_visual

signal action_complete

signal action_started

signal end_turn

signal on_turn_changed

signal action_points_changed

signal update_stat_bars

signal remove_unit(unit: Unit)

signal add_unit(unit: Unit)

signal obstacles_changed
