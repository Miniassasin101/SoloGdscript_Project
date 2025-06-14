# EventBus.gd
# Autoloaded Singleton
extends Node


@warning_ignore("unused_signal")
signal pause

@warning_ignore("unused_signal")
signal resume


@warning_ignore("unused_signal")
signal combat_started

@warning_ignore("unused_signal")
signal selected_action_changed(action: State)

@warning_ignore("unused_signal")
signal selection_locked_in(action: State)

@warning_ignore("unused_signal")
signal unit_actionable(unit: BaseChar)

@warning_ignore("unused_signal")
signal unit_changed(unit: BaseChar)

signal hide_all_selection_visuals

signal update_stat_bars

signal on_unit_added
signal on_unit_removed

signal frame_ended

signal apply_physics_requests

# Prediction Signals:

signal prediction_started

signal prediction_paused

signal prediction_pause_for_beats

signal prediction_resumed

signal prediction_reset

signal prediction_iteration_end   # one 3s pass done

signal prediction_finished
