class_name EquippedItemSlot3D extends Node3D


## Displays the current equipped [Item] from a specific [Equipment] node.



## Emitted when an [Item] is displayed.
signal item_displayed(item: Item)
## Emitted when an [Item] is hidden.
signal item_hidden(item: Item)

@export_category("Unit")
@export var unit: Unit = null
@export_category("Sockets")
@export var sockets: Array[EquipmentSocket] = []
@export_category("Equipment")
## The path to the [Equipment] node
@export_node_path("Equipment") var equipment_path: NodePath = NodePath():
	get:
		return equipment_path
	set(value):
		equipment_path = value
		update_configuration_warnings()

@export_group("Tagging", "tags_")
## Displays an equipped [Item] only if both it has these the [member Item.tags] tags.
@export var tags_to_display: Array[String] = []


var current_item_visual: ItemVisual = null

var current_socket: EquipmentSocket = null


func _init() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()


func _ready() -> void:
	#assert(not equipment_path.is_empty(), "equipment_path cannot be empty")
	
	#var equipment = get_node(equipment_path)
	if unit == null:
		unit = get_parent().get_parent().get_parent().get_parent().get_parent()
	
	var equipment: Equipment = unit.equipment
	
	equipment.equipped.connect(on_item_equipped)
	
	equipment.unequipped.connect(on_item_unequipped)


func on_item_equipped(item: Item, _slot: EquipmentSlot) -> void:
	if tags_to_display.size() > 0:
		var has_tags = true
		for tag in tags_to_display:
			if not item.tags.has(tag):
				has_tags = false
				break
		if not has_tags:
			return

	if item.scene and item.scene.can_instantiate() and (item.item_visual == null):
		var object = item.scene.instantiate() as Node3D
		item.set_object(object) # gives the item a reference to the physical item
		print_debug("Unit Name and equipping item: ", unit.name, " ", item.name)
		var item_visual: ItemVisual = preload("res://Hero_Game/Prefabs/Items/ItemVisual.tscn").instantiate()
		var socket: EquipmentSocket = determine_correct_socket(item)
		socket.add_item_visual(item_visual)
		item_visual.add_item(item)
		current_item_visual = item_visual
		current_socket = socket
		
		if item is Weapon:
			item.setup_weapon()
		
	elif item.item_visual:
		var item_visual: ItemVisual = item.item_visual
		var socket: EquipmentSocket = determine_correct_socket(item)
		socket.add_item_visual(item_visual)
		item_visual.set_position(Vector3.ZERO)
		item_visual.set_rotation(Vector3.ZERO)
		item_visual.root.set_position(Vector3.ZERO)
		current_item_visual = item.item_visual
		current_socket = socket



func on_item_unequipped(_item: Item, _slot: EquipmentSlot) -> void:
	#if current_item_visual != null:
	if !current_item_visual:
		return
	elif current_item_visual.item != _item:
		return
	
	current_item_visual = null
	current_socket = null
	ObjectManager.instance.drop_item_in_world(unit, _item)
	#remove_child(current)
	#current_item_visual = null
	#current_socket = null


func determine_correct_socket(item: Item) -> EquipmentSocket:
	for socket in sockets:
		for tag in item.tags:
			if tag.to_lower() == socket.socket_type.to_lower():
				return socket
	
	push_error("No socket matches tags on EquippedItemSlot3D. Item:" + item.name)
	return null
	



func _get_configuration_warnings() -> PackedStringArray:
	var errors: Array[String] = []
	
	if equipment_path == null:
		errors.append("equipment_path cannot be null")

	if equipment_path != null and equipment_path.is_empty():
		errors.append("equipment_path cannot be empty")

	return PackedStringArray(errors)
