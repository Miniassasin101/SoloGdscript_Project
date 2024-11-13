class_name SpinAction
extends Action

var total_spin_amount: float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If start_spinning is true, spin the unit.
	if !is_active:
		return
	# spin_add_amount is the rotation speed in degrees per second.
	var spin_add_amount: float = 360 * delta  # Full rotation per second
	unit.rotate_y(deg_to_rad(spin_add_amount))  # Rotate around Y axis
	total_spin_amount += spin_add_amount
	if total_spin_amount >= 360.0:
		is_active = false

func spin():
	is_active = true
	total_spin_amount = 0.0
