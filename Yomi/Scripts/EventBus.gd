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
