#UIBus.gd
#Autoloaded Singleton
extends Node

signal panel_dropped(panel: DroppablePanelUI)

signal effects_confirmed(effects: Array[SpecialEffect])

signal effects_chosen(effects: Array[SpecialEffect])
