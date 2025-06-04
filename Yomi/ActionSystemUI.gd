class_name ActionSystemUI
extends Node


signal continue_turn

@export_category("References")

@export var action_button_prefab: PackedScene

@export var action_button_container: HBoxContainer

@export var dynamic_slider_container: DynamicSliderContainer

@export var dynamic_button_picker: DynamicButtonPicker
@export var dynamic_button_container: BoxContainer

@export var mouse_event_droppable_controller: MouseEventDroppableSlotController


@export_category("")
@export var selected_unit: BaseChar
var reacting_unit: Unit = null

var slot_list: Array[MouseEventDroppableSlot] = []

var selected_action: State = null

static var instance: ActionSystemUI = null

func _ready() -> void:

	if instance != null:
		push_error("There's more than one ActionSystemUI! - " + str(instance))
		queue_free()
		return
	instance = self

	#create_unit_action_buttons()
	
	EventBus.unit_actionable.connect(on_unit_actionable)
	EventBus.selected_action_changed.connect(on_selected_action_changed)

	toggle_containers_visibility_off_except()




func create_unit_action_buttons() -> void:
	if !selected_unit:
		return
	for action_button in action_button_container.get_children():
		action_button.queue_free()
	
	var granted_actions: Array[State] = selected_unit.state_machine.get_actions()
	
	for action: State in granted_actions:
		
		var action_button_ui: ActionButtonUI = action_button_prefab.instantiate()
		action_button_ui.set_base_action(action)
		action_button_container.add_child(action_button_ui)
	

func on_unit_actionable(unit: BaseChar = selected_unit) -> void:
	
	toggle_containers_visibility_off_except([action_button_container])
	create_unit_action_buttons()

func on_selected_action_changed(action: State) -> void:
	print_debug("Selected Action: " + action.state_name)
	if selected_action and selected_action != action:
		selected_action.on_action_unfocused()
	selected_action = action
	selected_action.on_action_focused()


func on_selected_unit_changed(unit: BaseChar) -> void:
	if selected_unit and selected_unit.selection_visual:
		selected_unit.selection_visual.hide_self()
	if selected_action:
		selected_action.on_action_unfocused()
	selected_unit = unit
	var selection_visual: GridSystemVisualSingle = selected_unit.selection_visual
	selection_visual.set_color(Color.BLUE)
	selection_visual._show()
	create_unit_action_buttons()


func toggle_containers_visibility_off_except(containers: Array[Control] = []) -> void:
	action_button_container.set_visible(false)

	#special_effect_container.set_visible(false)
	#selected_special_effect_container.set_visible(false)
	mouse_event_droppable_controller.set_visible(false)
	
	if !containers.is_empty():
		for container: Control in containers:
			container.set_visible(true)




func get_dynamic_button_picker() -> DynamicButtonPicker:
	return dynamic_button_picker


func _on_lock_in_button_pressed() -> void:
	if selected_action:
		if !ActionabilityTracker.instance.is_unit_actionable(selected_unit):
			return
		if selected_action.state_machine.unit == selected_unit:
			EventBus.selection_locked_in.emit(selected_action)
			#toggle_containers_visibility_off_except()
		else:
			push_error("action unit isnt selected unit")
