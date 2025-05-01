class_name EquipmentSocket
extends Node3D


@export var socket_type: String = "Enter Socket Type:"

var item_visual: ItemVisual = null

func add_item_visual(item_vis: ItemVisual) -> void:
	if item_vis.get_parent() != null:
		item_vis.reparent(self, false)
		item_visual = item_vis
	
	else:
		add_child(item_vis)
		item_visual = item_vis
