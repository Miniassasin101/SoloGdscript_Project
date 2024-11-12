extends MeshInstance3D

# Exported variable to hold the reference to the currently selected unit.
@export var current_unit: Unit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the 'selected_unit_changed' signal from the SignalBus to the local function.
	SignalBus.selected_unit_changed.connect(_on_selected_unit_changed)

# This method is connected to the SignalBus signal. 
# It gets triggered when the selected unit changes.
func _on_selected_unit_changed(action_system) -> void:
	update_visual(action_system)

# Updates the visibility of the visual object based on the selected unit.
func update_visual(action_system) -> void:
	# Retrieve the selected unit from the action system.
	var selected_unit = action_system.get_selected_unit()

	# If the selected unit is the current unit, make this object visible.
	if selected_unit == current_unit:
		self.visible = true
	else:
		# Otherwise, hide this object.
		self.visible = false
