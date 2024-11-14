class_name UnitActionSystemUI
extends Node

@export var action_button_prefab: PackedScene
@export var action_button_container: BoxContainer
@export var selected_unit: Unit


func _ready() -> void:
	SignalBus.selected_unit_changed.connect(on_selected_unit_changed)
	selected_unit = UnitActionSystem.instance.get_selected_unit()
	create_unit_action_buttons()


func create_unit_action_buttons() -> void:
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	
	for action: Action in  selected_unit.get_action_array():
		var action_button_ui = action_button_prefab.instantiate()
		action_button_ui.set_base_action(action)
		action_button_container.add_child(action_button_ui)
		
func on_selected_unit_changed(unit: Unit) -> void:
	selected_unit = unit
	create_unit_action_buttons()
