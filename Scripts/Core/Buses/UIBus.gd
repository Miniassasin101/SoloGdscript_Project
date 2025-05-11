#UIBus.gd
#Autoloaded Singleton
extends Node

@warning_ignore("unused_signal")
signal panel_dropped(panel: DroppablePanelUI)

@warning_ignore("unused_signal")
signal effects_confirmed(effects: Array[SpecialEffect])

@warning_ignore("unused_signal")
signal effects_chosen(effects: Array[SpecialEffect])

@warning_ignore("unused_signal")
signal on_ui_update

@warning_ignore("unused_signal")
signal update_stat_bars

signal instantiate_stats_bars
