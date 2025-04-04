extends Node3D
class_name UnitUIManager3D

# Reference to the active Camera3D in your scene.
@export var main_camera: Camera3D

# Packed scene for your 3D sprite UI.
# This scene should have a Sprite3D node (with your silhouette texture) as its root.
@export var silhouette_scene: PackedScene



# Offset distance in world units (to the left of the unit’s above marker).
@export var left_offset: float = 0.5

# Additional vertical offset (if needed).
@export var vertical_offset: float = 0.0

# Dictionary to map each unit (key) to its UI Sprite3D instance (value).
var unit_ui_instances: Dictionary[Unit, SilhouetteUI3D] = {}

static var instance: UnitUIManager3D = null

func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitUIManager3D! - " + str(instance))
		queue_free()
		return
	instance = self


# Call this method after UnitManager has finished setting up the units.
func setup_unit_ui(units: Array[Unit]) -> void:
	# Clear any previous UI instances.
	for ui in unit_ui_instances.values():
		if is_instance_valid(ui):
			ui.queue_free()
	unit_ui_instances.clear()
	
	for unit in units:
		# Instantiate a new Sprite3D UI from the provided scene.
		var ui_instance: SilhouetteUI3D = silhouette_scene.instantiate() as SilhouetteUI3D
		
		
		# Optional: adjust scale or other properties if the sprite is too big.
		# ui_instance.scale = Vector3(0.25, 0.25, 0.25)
		
		# Add the UI instance to the scene.
		#unit.above_marker.add_child(ui_instance)
		add_child(ui_instance)
		
		# Map the unit to its UI sprite.
		unit_ui_instances[unit] = ui_instance
		
		unit.body.update_body_ui()

# Updates the 3D UI sprite positions each frame.
func update_ui_positions() -> void:
	for unit in unit_ui_instances.keys():
		var ui_instance: SilhouetteUI3D = unit_ui_instances[unit]
		if not is_instance_valid(unit) or not is_instance_valid(ui_instance):
			continue
		
		# Get the unit's world position from its above_marker.
		var world_pos: Vector3 = unit.get_world_position_above_marker()
		
		# Compute a leftward offset relative to the camera's view.
		# The camera's right vector is given by its global_transform.basis.x,
		# so multiplying by -1 gives the left direction.
		var left_vector: Vector3 = -main_camera.global_transform.basis.x
		var offset: Vector3 = left_vector * left_offset
		
		# Optionally add a vertical offset (using the camera's up vector).
		offset += main_camera.global_transform.basis.y * vertical_offset
		
		# Set the UI sprite's global position.
		ui_instance.global_position = world_pos + offset

func _process(delta: float) -> void:
	update_ui_positions()
	#pass


### --- NEW FUNCTIONS: Interfacing with SilhouetteUI3D --- ###

# Sets a specific body part's color for a unit using a key from the exported dictionary.
func set_unit_part_color(unit: Unit, part_name: String, color_key: String) -> void:
	if unit_ui_instances.has(unit):
		var silhouette: SilhouetteUI3D = unit_ui_instances[unit]
		silhouette.set_part_color_by_key(part_name, color_key)
	else:
		push_warning("Unit not found in UI manager: " + str(unit))

# Convenience function: Set a unit's body part color to blue.
func set_unit_part_blue(unit: Unit, part_name: String) -> void:
	if unit_ui_instances.has(unit):
		var silhouette: SilhouetteUI3D = unit_ui_instances[unit]
		silhouette.set_part_blue(part_name)
	else:
		push_warning("Unit not found in UI manager: " + str(unit))

# Convenience function: Set a unit's body part color to orange.
func set_unit_part_orange(unit: Unit, part_name: String) -> void:
	if unit_ui_instances.has(unit):
		var silhouette: SilhouetteUI3D = unit_ui_instances[unit]
		silhouette.set_part_orange(part_name)
	else:
		push_warning("Unit not found in UI manager: " + str(unit))

# Convenience function: Set a unit's body part color to red.
func set_unit_part_red(unit: Unit, part_name: String) -> void:
	if unit_ui_instances.has(unit):
		var silhouette: SilhouetteUI3D = unit_ui_instances[unit]
		silhouette.set_part_red(part_name)
	else:
		push_warning("Unit not found in UI manager: " + str(unit))

# Sets all body parts of a unit's silhouette to the given color key.
func set_unit_all_parts_color(unit: Unit, color_key: String) -> void:
	if unit_ui_instances.has(unit):
		var silhouette: SilhouetteUI3D = unit_ui_instances[unit]
		silhouette.set_all_parts_color_by_key(color_key)
	else:
		push_warning("Unit not found in UI manager: " + str(unit))

# Resets all body parts of a unit's silhouette to white.
func reset_unit_colors(unit: Unit) -> void:
	if unit_ui_instances.has(unit):
		var silhouette: SilhouetteUI3D = unit_ui_instances[unit]
		silhouette.reset_all_parts_color()
	else:
		push_warning("Unit not found in UI manager: " + str(unit))
