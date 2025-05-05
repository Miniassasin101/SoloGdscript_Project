class_name MouseEventDroppableSlotContainer extends PanelContainer



enum MouseEventsCardSlotContainerType {Hand, Active}


@export var unit_action_system_ui: UnitActionSystemUI = null

@export var droppable_controller: MouseEventDroppableSlotController = null

@export var slot_container_type: MouseEventsCardSlotContainerType


@export var slot_hbox_container: HBoxContainer
@export var droppable_panel_prefab: PackedScene
@export var mouse_event_droppable_slot: PackedScene

var self_slot_list: Array[MouseEventDroppableSlot] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func get_first_free_slot() -> MouseEventDroppableSlot:
	for slot: MouseEventDroppableSlot in self_slot_list:
		if !slot.has_panel():
			return slot
	return null


func get_special_effects() -> Array[SpecialEffect]:
	var ret_effects: Array[SpecialEffect] = []
	for slot: MouseEventDroppableSlot in self_slot_list:
		if slot.has_panel():
			var special_effect: SpecialEffect = slot.get_panel().get_special_effect()
			if special_effect != null:
				ret_effects.append(special_effect)
	
	return ret_effects



func reset_slots() -> void:
	for slot: MouseEventDroppableSlot in self_slot_list:
		slot.queue_free()
	self_slot_list.clear()

func setup_special_effect_slots(special_effects: Array[SpecialEffect], abs_dif: int = 1) -> void:
	if !slot_hbox_container.get_children().is_empty():
		for child in slot_hbox_container.get_children():
			child.queue_free()
	
	match slot_container_type:
		
		MouseEventsCardSlotContainerType.Hand:
			for effect: SpecialEffect in special_effects:
				var new_slot: MouseEventDroppableSlot = mouse_event_droppable_slot.instantiate() as MouseEventDroppableSlot
				new_slot.slot_type = MouseEventDroppableSlot.MouseEventsCardSlotType.Hand
				slot_hbox_container.add_child(new_slot)
				droppable_controller.slot_list.append(new_slot)
				self_slot_list.append(new_slot)
				var new_panel: DroppablePanelUI = droppable_panel_prefab.instantiate() as DroppablePanelUI
				new_panel.panel_source = new_slot.slot_type
				new_panel.set_special_effect(effect)
				new_slot.add_panel(new_panel)
		
		MouseEventsCardSlotContainerType.Active:
			for i in range(abs_dif + 1):
				var new_slot: MouseEventDroppableSlot = mouse_event_droppable_slot.instantiate() as MouseEventDroppableSlot
				new_slot.slot_type = MouseEventDroppableSlot.MouseEventsCardSlotType.Active
				slot_hbox_container.add_child(new_slot)
				droppable_controller.slot_list.append(new_slot)
				self_slot_list.append(new_slot)
