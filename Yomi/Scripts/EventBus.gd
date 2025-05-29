# EventBus.gd
# Autoloaded Singleton
extends Node


signal pause

signal resume


signal combat_started

signal selected_action_changed(action: State)

signal selection_locked_in(action: State)

signal unit_actionable
