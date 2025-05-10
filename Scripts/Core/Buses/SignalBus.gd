#SignalBus.gd
#Autoloaded Singleton
extends Node




@warning_ignore("unused_signal")
signal selected_unit_changed(unit: Unit)


@warning_ignore("unused_signal")
signal selected_move_changed(move: Move)

@warning_ignore("unused_signal")
signal new_grid_pos_hovered

@warning_ignore("unused_signal")
signal update_grid_visual

@warning_ignore("unused_signal")
signal move_complete(move: Move)

# Used as separate for on_move_ended in UnitActionSystem.
@warning_ignore("unused_signal")
signal move_complete_next(move: Move)

@warning_ignore("unused_signal")
signal move_started

@warning_ignore("unused_signal")
signal end_turn

@warning_ignore("unused_signal")
signal on_turn_changed

@warning_ignore("unused_signal")
signal on_cycle_changed

@warning_ignore("unused_signal")
signal on_phase_changed

#signal reset_distance_moved

@warning_ignore("unused_signal")
signal on_ui_update ## updates all ui

@warning_ignore("unused_signal")
signal rotate_unit_towards_facing(unit: Unit)

@warning_ignore("unused_signal")
signal next_phase

@warning_ignore("unused_signal")
signal continue_turn

@warning_ignore("unused_signal")
signal on_player_reaction

@warning_ignore("unused_signal")
signal on_player_special_effect(unit: Unit, special_effects: Array[SpecialEffect], abs_dif: int)

@warning_ignore("unused_signal")
signal special_effects_chosen

@warning_ignore("unused_signal")
signal reaction_selected

@warning_ignore("unused_signal")
signal reaction_started

@warning_ignore("unused_signal")
signal gait_selected(gait: int)

@warning_ignore("unused_signal")
signal on_round_changed

@warning_ignore("unused_signal")
signal is_player_turn

@warning_ignore("unused_signal")
signal on_book_keeping_ended

@warning_ignore("unused_signal")
signal hide_success

@warning_ignore("unused_signal")
signal action_points_changed

@warning_ignore("unused_signal")
signal update_stat_bars

@warning_ignore("unused_signal")
signal open_character_sheet(unit: Unit)

@warning_ignore("unused_signal")
signal equipment_changed(unit: Unit)

@warning_ignore("unused_signal")
signal form_body

@warning_ignore("unused_signal")
signal remove_unit(unit: Unit)

@warning_ignore("unused_signal")
signal add_unit(unit: Unit)

@warning_ignore("unused_signal")
signal on_unit_added(unit: Unit)

@warning_ignore("unused_signal")
signal on_unit_removed(unit: Unit)

@warning_ignore("unused_signal")
signal obstacles_changed

@warning_ignore("unused_signal")
signal unit_moved_position(unit: Unit)
