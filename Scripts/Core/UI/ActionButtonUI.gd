class_name ActionButtonUI
extends Button

@export var button_text: Label
@export var button: Button
var move: Move
var is_gait: bool = false
var gait: int = 0



enum SpecialCase {
	NONE,
	GAIT,
	NO_AP,
	REACTION,
	SPECIAL_EFFECT
}

var special_case: int = SpecialCase.NONE


func _ready() -> void:
	pass # Replace with function body.


func set_base_move(_move: Move) -> void:
	button_text.set_text(_move.ui_name.to_upper())
	if _move.tags_type.has("reaction"):
		special_case = SpecialCase.REACTION
	move = _move


func set_gait(in_gait: int) -> void:
	special_case = SpecialCase.GAIT
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

## This function is to set up an extra action button when a unit has no AP.
## This allows them to still take a move action and/or change gait even if they run out of ap in the first round or two.
func set_no_ap() -> void:
	special_case = SpecialCase.NO_AP
	button_text.set_text("Next Phase")


func _pressed() -> void:
	handle_special_case()


func handle_special_case() -> void:
	match special_case:

		SpecialCase.NONE:
			SignalBus.selected_move_changed.emit(move)
		
		SpecialCase.GAIT:
			SignalBus.gait_selected.emit(gait)
		
		SpecialCase.NO_AP:
			SignalBus.next_phase.emit()
		
		SpecialCase.REACTION:
			SignalBus.selected_move_changed.emit(move)
