## A template for the status of a ghost at the first frame of the prediction.
## For an actionable unit changing their hovered action will change the starting action of the ghost template.
class_name GhostTemplate
extends Resource

var template_name: String
var global_transform: Transform3D
var saved_linear_velocity: Vector3


var current_state_name: String

var original_unit: BaseChar
var original_current_state: State

var action_override : State = null
var is_overridden: bool = false


static func create_from_unit(real_unit: BaseChar) -> GhostTemplate:
	var new_template: GhostTemplate = GhostTemplate.new()
	
	new_template.global_transform = real_unit.global_transform
	new_template.saved_linear_velocity = real_unit.saved_linear_velocity
	#new_template.state_name = real_unit.
	new_template.template_name = real_unit.ui_name
	new_template.current_state_name = real_unit.state_machine.current_state.state_name
	new_template.original_unit = real_unit
	new_template.original_current_state = real_unit.state_machine.current_state
	
	new_template.action_override = null
	
	return new_template
