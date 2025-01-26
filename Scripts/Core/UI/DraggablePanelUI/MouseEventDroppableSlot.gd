class_name MouseEventDroppableSlot extends PanelContainer

## Enum that determines what type of slot this is.
## Hand refers to the bottom tray the panels are chosen from.
## Active refers to the top tray of panels that will be activated.
enum MouseEventsCardSlotType {Hand, Active}
@export var slot_type: MouseEventsCardSlotType


func add_panel(panel: DroppablePanelUI) -> void:
	panel.dragged_away.connect(dragged_away)
	add_child(panel)


func dragged_away(panel: DroppablePanelUI) -> void:
	panel.dragged_away.disconnect(dragged_away)
	remove_child(panel)
	if panel.stackable and panel.panel_source == MouseEventsCardSlotType.Hand:
		var new_panel: DroppablePanelUI = panel.duplicate()
		new_panel.stackable = panel.stackable
		new_panel.set_special_effect(panel.special_effect)
		add_panel(new_panel)

func has_panel() -> bool:
	if !get_children().is_empty():
		return true
	else:
		return false

func get_panel() -> DroppablePanelUI:
	return get_child(0)
