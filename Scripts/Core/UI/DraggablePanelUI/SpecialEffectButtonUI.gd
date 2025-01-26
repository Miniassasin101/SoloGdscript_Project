class_name DroppablePanelUI
extends Control

signal dragged_away(panel: DroppablePanelUI)

@export var tween_time: float = 0.25

@export var panel_text: Label

var mouse_offset: Vector2

var is_being_dragged: bool = false

var dragged_from_pos: Vector2

@export var panel_source: MouseEventDroppableSlot.MouseEventsCardSlotType = MouseEventDroppableSlot.MouseEventsCardSlotType.Hand

var special_effect: SpecialEffect = null

var stackable: bool = false
#var z_inx: int

func _ready() -> void:
	pass # Replace with function body.
	#z_inx = z_index


func _on_mouse_button_down() -> void:
	mouse_offset = get_local_mouse_position()
	dragged_from_pos = global_position
	z_index += 1
	is_being_dragged = true

func _on_mouse_button_up() -> void:
	UIBus.panel_dropped.emit(self)
	z_index -= 1
	is_being_dragged = false


func _on_right_mouse_button_down() -> void:
	if is_being_dragged:
		return
	if panel_source == MouseEventDroppableSlot.MouseEventsCardSlotType.Hand:
		var to_slot: MouseEventDroppableSlot = MouseEventDroppableSlotController.instance.get_free_active_slot()
		if can_move_to_slot(to_slot):
			move_to_slot(to_slot)
	elif panel_source == MouseEventDroppableSlot.MouseEventsCardSlotType.Active:
		if stackable:
			var owner: MouseEventDroppableSlot = get_parent() as MouseEventDroppableSlot
			owner.dragged_away(self)
			#queue_free()
			return
		var to_slot: MouseEventDroppableSlot = MouseEventDroppableSlotController.instance.get_free_hand_slot()
		if can_move_to_slot(to_slot):
			move_to_slot(to_slot)


func revert_pos() -> void:
	move_to_pos(dragged_from_pos)

func tween_pos_done() -> void:
	z_index -= 1



func can_move_to_slot(slot: MouseEventDroppableSlot) -> bool:
	if slot == null:
		return false
	match slot.slot_type:

		MouseEventDroppableSlot.MouseEventsCardSlotType.Hand:
			return slot.get_child_count() == 0 and (stackable == false)

		MouseEventDroppableSlot.MouseEventsCardSlotType.Active:
			return slot.get_child_count() == 0
	return false

func move_to_pos(pos: Vector2) -> void:
	z_index += 1
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", pos, tween_time)
	tween.tween_callback(tween_pos_done)

func move_to_slot(slot: MouseEventDroppableSlot) -> void:
	var old_pos: Vector2 = global_position
	dragged_away.emit(self)
	panel_source = slot.slot_type
	slot.add_panel(self)
	set_deferred("global_position", old_pos)
	call_deferred("move_to_pos", slot.global_position)



func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == 1:
			if mouse_event.button_mask == 1:
				_on_mouse_button_down()
			else:
				_on_mouse_button_up()
		
		if mouse_event.button_index == 2:
			if mouse_event.button_mask == 2:
				_on_right_mouse_button_down()

	elif is_being_dragged and event is InputEventMouseMotion:
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		global_position = get_global_mouse_position() - mouse_offset




func set_special_effect(in_effect: SpecialEffect) -> void:
	special_effect = in_effect
	stackable = special_effect.stackable
	panel_text.set_text(in_effect.ui_name.to_upper())
