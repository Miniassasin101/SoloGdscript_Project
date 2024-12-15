#SignalBus.gd
#Autoloaded Singleton
extends Node



signal selected_unit_changed(unit: Unit)


signal selected_ability_changed(ability: Ability)

signal update_grid_visual

signal ability_complete

signal ability_started

signal end_turn

signal on_turn_changed

signal on_round_changed

signal is_player_turn

signal on_book_keeping_ended

signal action_points_changed

signal update_stat_bars

signal remove_unit(unit: Unit)

signal add_unit(unit: Unit)

signal obstacles_changed
