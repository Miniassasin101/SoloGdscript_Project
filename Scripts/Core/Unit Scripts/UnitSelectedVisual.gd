# SelectedUnitIndicator.gd
# Visual indicator that shows when a unit is selected.

class_name SelectedUnitIndicator
extends MeshInstance3D

# Reference to the unit that this indicator is associated with.
@export var current_unit: Unit
# Reference to the UnitActionSystem (adjust the path as necessary).
var action_system: UnitActionSystem

func _ready() -> void:
	# Get the UnitActionSystem node (assuming it's at the root).
	action_system = current_unit.get_action_system()
	# Connect the 'selected_unit_changed' signal from SignalBus to the local function.
	SignalBus.selected_unit_changed.connect(_on_selected_unit_changed)
	# Initialize visibility based on whether this unit is selected.
	if action_system != null:
		update_visual()

# This method is connected to the SignalBus signal.
# It gets triggered when the selected unit changes.
func _on_selected_unit_changed(_unit: Unit) -> void:
	update_visual()

# Updates the visibility of the visual object based on the selected unit.
func update_visual() -> void:
	action_system = current_unit.get_action_system()
	# Retrieve the selected unit from the action system.
	var selected_unit = action_system.get_selected_unit()
	# If the selected unit is the current unit, make this object visible.
	self.visible = (selected_unit == current_unit)
