class_name ObjectManager
extends Node

@export_group("Item Offsets")
@export var item_offset_from_ground: float = 0.1
@export var final_x_offset: float = 0.5
@export var final_z_offset: float = 0.0

@export_group("Arc Settings")
@export var arc_height: float = 2.0
@export var arc_side_offset_range: float = 1.0

@export_group("Arc Timings")
@export var arc_segment_1_duration: float = 0.5
@export var arc_segment_2_duration: float = 0.5

@export_group("Spin Settings")
@export var spin_animation_name: String = "ItemSpin"
@export var spin_playback_speed: float = 2.0
@export var spin_speed_scale_start: float = 1.0
@export var spin_speed_scale_tween_time: float = 0.6
@export var rotation_tween_time: float = 0.3
@export var rotation_tween_delay: float = 0.2

var items: Array[Item] = []

var is_dropping: bool = false

static var instance: ObjectManager = null

func _ready() -> void:
	if instance != null:
		push_error("There's more than one ObjectManager! - " + str(instance))
		queue_free()
		return
	instance = self


func drop_item_in_world(unit: Unit, in_item: Item = null) -> void:
	#if !unit.equipment.has_equipped_weapon():
	#	return
	# Choose the item to drop
	if is_dropping:
		return
	is_dropping = true
	var item = in_item if in_item else unit.get_equipped_weapon()
	items.append(item)

	var item_visual: ItemVisual = item.get_item_visual()
	item_visual.reparent(self)
	unit.equipment.unequip(item)
	is_dropping = false
	# Find all possible adjacent drop spots
	var adjacent_pos: Array[GridPosition] = Utilities.get_adjacent_tiles_with_diagonal(unit)
	var actual_pos: Array[GridPosition] = []
	for pos in adjacent_pos:
		var grid_obj: GridObject = LevelGrid.grid_system.get_grid_object(pos)
		if grid_obj and grid_obj.is_walkable and !grid_obj.has_any_unit():
			actual_pos.append(pos)

	var num_of_pos: int = actual_pos.size()
	if num_of_pos == 0:
		print_debug("No valid drop tile found, dropping in place.")
		return
	
	# Randomly pick one spot
	var num_rolled: int = Utilities.roll(num_of_pos)
	var drop_pos: GridPosition = actual_pos[num_rolled - 1]

	# Build final position slightly above ground
	var offset: Vector3 = Vector3(final_x_offset, item_offset_from_ground, final_z_offset)
	var final_pos: Vector3 = LevelGrid.get_world_position(drop_pos) + offset

	# We'll do an arc by having a mid_pos somewhere between start & end
	var start_pos: Vector3 = item_visual.global_position
	var mid_pos: Vector3 = start_pos.lerp(final_pos, 0.5)
	# Bump it higher in the air, or also offset sideways for a fancier arc
	mid_pos.y += arc_height
	mid_pos.x += randf_range(-arc_side_offset_range, arc_side_offset_range)

	# Start a tween
	var tween: Tween = get_tree().create_tween()

	# 1) Start the spin animation
	item_visual.play_animation(spin_animation_name, spin_playback_speed)
	item_visual.set_trail_visibility(true)
	# Make the spin scale tween
	tween.tween_property(
		item_visual.animator,
		"speed_scale",
		spin_speed_scale_start,
		spin_speed_scale_tween_time
	)
	tween.parallel()

	# 2) Arc from start -> mid_pos
	tween.tween_property(
		item_visual,
		"global_position",
		mid_pos,
		arc_segment_1_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3) Then continue mid_pos -> final_pos
	tween.tween_property(
		item_visual,
		"global_position",
		final_pos,
		arc_segment_2_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Also do any additional parallel motion/rotation
	tween.parallel()
	tween.tween_property(
		item_visual.root,
		"position",
		Vector3(0.0, 0.0, 0.5),
		arc_segment_2_duration
	)

	tween.parallel()
	tween.tween_property(
		item_visual,
		"rotation",
		Vector3(0.0, 0.5, 0.0),
		rotation_tween_time
	).set_delay(rotation_tween_delay)

	await tween.finished

	# Once item has landed, stop the spin animation
	item_visual.pause_animation()
	item_visual.set_trail_visibility(false)

	print_debug("Item drop arc + spin complete!")
	add_item_to_grid_object(item, drop_pos)
	

func remove_all_dropped_items() -> void:
	# Iterate over all dropped items.
	for item in items:
		# Remove the item from its grid object tracking.
		remove_item_from_grid_object(item)
		# Get the item's visual node.
		var item_visual: ItemVisual = item.get_item_visual()
		# If the visual exists and is in the scene tree, free it.
		if item_visual and item_visual.is_inside_tree():
			item_visual.queue_free()
	# Clear the items list.
	items.clear()
	print_debug("All dropped items have been removed.")



func equip_item(unit: Unit, in_item: Item) -> void:
	var item = in_item if in_item else unit.get_equipped_weapon()
	items.erase(item)


	unit.equipment.equip(item)
	remove_item_from_grid_object(item)


func add_item_to_grid_object(item: Item, drop_pos: GridPosition) -> void:
	var grid_obj: GridObject = LevelGrid.grid_system.get_grid_object(drop_pos)
	grid_obj.add_item(item)


func remove_item_from_grid_object(item: Item) -> void:
	var grid_obj: GridObject = LevelGrid.grid_system.get_grid_object(LevelGrid.get_grid_position(item.item_visual.global_position))
	grid_obj.remove_item(item)
