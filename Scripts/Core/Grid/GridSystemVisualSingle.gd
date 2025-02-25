class_name GridSystemVisualSingle
extends Node3D

@export var color_mat_resource: StandardMaterial3D

@export var grid_system_visual: MeshInstance3D
@export var grid_system_visual_red: MeshInstance3D

# How high the grid cell should rise.
@export var rise_height: float = 1.0
# Duration for rising.
@export var rise_duration: float = 0.5
# Duration for falling.
@export var fall_duration: float = 0.5

var original_pos: Vector3

var is_hovered: bool = false

var is_highlighted: bool = false

func _ready() -> void:
	# Store the starting global position.
	original_pos = grid_system_visual.global_position

# Called to update visuals for this cell.
func update_visual(is_red: bool) -> void:
	grid_system_visual.visible = not is_red
	grid_system_visual_red.visible = is_red

# Example usage in the script.
func set_difficult_terrain(is_difficult: bool) -> void:
	update_visual(is_difficult)

# Function to raise the grid cell.
func rise() -> Tween:
	var tween: Tween = get_tree().create_tween()
	# Tween the grid_system_visual's global_position from original_pos to original_pos + rise_height on Y.
	tween.tween_property(
		grid_system_visual,
		"global_position",
		original_pos + Vector3(0, rise_height, 0),
		rise_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Optionally, you may also tween grid_system_visual_red if needed.
	return tween

# Function to lower the grid cell back to its original position.
func fall() -> Tween:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(
		grid_system_visual,
		"global_position",
		original_pos,
		fall_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Optionally, tween grid_system_visual_red as well.
	return tween

# Function to set the color on the material overlay.
func set_color(color: Color) -> void:
	var color_mat: StandardMaterial3D = color_mat_resource.duplicate()
	color_mat.albedo_color = color
	grid_system_visual.set_surface_override_material(0, color_mat)


func highlight(color: Color = Color(0.68, 0.85, 0.9, 1)) -> void:
	if !is_hovered:
		set_color(color)
		rise()
		is_highlighted = true



func remove_highlight() -> void:
	if !is_hovered and is_highlighted:
		set_color(Color.WHITE)
		fall()
		is_highlighted = false



# Function to flash a given color on a mesh (already provided).
func flash_color_on_mesh(mesh: MeshInstance3D, color: Color = Color.DEEP_SKY_BLUE, flash_time: float = 1.0) -> void:
	var mesh_mat: StandardMaterial3D = preload("res://Hero_Game/Art/Materials/UnitMaterials/UnitVFXMaterials/GeneralHitFXMaterial.tres").duplicate(true)
	mesh_mat.albedo_color = color
	mesh.set_material_overlay(mesh_mat)
	await get_tree().create_timer(flash_time).timeout
	mesh.set_material_overlay(null)

func _show() -> void:
	grid_system_visual.visible = true
	grid_system_visual_red.visible = true

func hide_self() -> void:
	grid_system_visual.visible = false
	grid_system_visual_red.visible = false

# Combined function to change color and then perform the rise/fall animation.
func rise_and_set_color(color: Color) -> void:
	set_color(color)
	# Await the rise tween to finish, then await the fall tween.
	rise()
	#await fall().finished


# --- Mouse Event Callbacks ---

func _on_mouse_enter(in_color: Color = Color.BLUE) -> void:
	# When the mouse hovers, if the cell is visible then rise and turn blue.
	if grid_system_visual.visible:
		is_hovered = true
		set_color(in_color)
		rise()

func _on_mouse_exit() -> void:
	# When the mouse leaves, reset the color to white and fall back to the original position.
	is_hovered = false
	set_color(Color.WHITE)
	fall()
