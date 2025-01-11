class_name ActionButtonUI
extends Button

@export var button_text: Label
@export var button: Button
var ability: Ability
var is_gait: bool = false
var gait: int = 0


func _ready() -> void:
	pass # Replace with function body.


func set_base_ability(_ability: Ability) -> void:
	button_text.set_text(_ability.ui_name.to_upper())
	#print_debug(_ability.ui_name.to_upper())
	ability = _ability


func set_gait(in_gait: int) -> void:
	is_gait = true
	match in_gait:
		0:
			button_text.set_text("Hold")
			gait = Utilities.MovementGait.HOLD_GROUND
		1:
			button_text.set_text("Walk")
			gait = Utilities.MovementGait.WALK
		2:
			button_text.set_text("Run")
			gait = Utilities.MovementGait.RUN
		3:
			button_text.set_text("Sprint")
			gait = Utilities.MovementGait.SPRINT

func _pressed() -> void:
	if is_gait:
		SignalBus.gait_selected.emit(gait)
		return
	if ability.tags_type.has("reaction"):
		SignalBus.reaction_selected.emit(ability)
		
	SignalBus.selected_ability_changed.emit(ability)
