class_name MouseEventDroppableSlotController extends Control


@export var hand_droppable_container: MouseEventDroppableSlotContainer
@export var active_droppable_container: MouseEventDroppableSlotContainer
var slot_list: Array[MouseEventDroppableSlot] = []


static var instance: MouseEventDroppableSlotController = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if instance != null:
		push_error("There's more than one MouseEventDroppableSlotController! - " + str(instance))
		queue_free()
		return
	instance = self
	
	
	
	UIBus.panel_dropped.connect(on_panel_dropped)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func setup_special_effect_slot_containers(special_effects: Array[SpecialEffect], abs_dif: int = 1) -> void:
	for child in get_children():
		if child.has_method("setup_special_effect_slots"):
			child.setup_special_effect_slots(special_effects, abs_dif)

func on_panel_dropped(panel: DroppablePanelUI) -> void:
	var slot: MouseEventDroppableSlot = get_slot_at_pos(get_global_mouse_position())
	if slot:
		if panel.can_move_to_slot(slot):
			panel.move_to_slot(slot)
			return

	panel.revert_pos()


func get_free_active_slot() -> MouseEventDroppableSlot:
	return active_droppable_container.get_first_free_slot()

func get_free_hand_slot() -> MouseEventDroppableSlot:
	return hand_droppable_container.get_first_free_slot()

func get_slot_at_pos(pos: Vector2) -> MouseEventDroppableSlot:
	for slot: MouseEventDroppableSlot in slot_list:
		if slot.get_global_rect().has_point(pos):
			return slot
	return null
