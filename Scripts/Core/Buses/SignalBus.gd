#SignalBus.gd
extends Node


signal selected_unit_changed(unit: Unit)

signal selected_action_changed(action: Action)

signal action_complete()

signal action_started

signal next_turn

signal action_points_changed
