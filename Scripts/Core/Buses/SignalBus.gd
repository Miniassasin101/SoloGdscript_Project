#SignalBus.gd
#Autoloaded Singleton
extends Node



signal selected_unit_changed(unit: Unit)


signal selected_ability_changed(ability: Ability)

signal update_grid_visual

signal ability_complete(ability: Ability)

# Used as separate for on_ability_ended in UnitActionSystem.
signal ability_complete_next(ability: Ability)

signal ability_started

signal end_turn

signal on_turn_changed

signal on_cycle_changed

signal on_phase_changed

#signal reset_distance_moved

signal on_ui_update ## updates all ui

signal rotate_unit_towards_facing(unit: Unit)

signal next_phase

signal continue_turn

signal on_player_reaction

signal on_player_special_effect(unit: Unit, special_effects: Array[SpecialEffect])

signal special_effects_chosen

signal reaction_selected

signal gait_selected(gait: int)

signal on_round_changed

signal is_player_turn

signal on_book_keeping_ended

signal hide_success

signal action_points_changed

signal update_stat_bars

signal open_character_sheet(unit: Unit)

signal equipment_changed(unit: Unit)

signal form_body

signal remove_unit(unit: Unit)

signal add_unit(unit: Unit)

signal obstacles_changed
