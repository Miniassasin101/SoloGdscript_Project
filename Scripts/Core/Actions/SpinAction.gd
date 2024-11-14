class_name SpinAction
extends Action

var total_spin_amount: float = 0.0

func _ready() -> void:
	super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_active:
		return

	# spin_add_amount is the rotation speed in degrees per second.
	var spin_add_amount: float = 360.0 * delta  # Full rotation per second
	unit.rotate_y(deg_to_rad(spin_add_amount))  # Rotate around the Y-axis
	total_spin_amount += spin_add_amount

	# Check if a full rotation has been completed.
	if total_spin_amount >= 360.0:
		is_active = false
		total_spin_amount = 0.0
		# Invoke the callback if it's valid.
		SignalBus.action_complete.emit()


func take_action(grid_position: GridPosition,) -> void:
	is_active = true
	total_spin_amount = 0.0

func get_action_name() -> String:
	return "Spin"

func get_valid_action_grid_position_list() -> Array[GridPosition]:
	var unit_grid_position = unit.get_grid_position()
	return [unit_grid_position]
