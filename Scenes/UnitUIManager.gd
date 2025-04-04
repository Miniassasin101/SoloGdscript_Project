extends Control
class_name UnitUIManager

# Reference to the main Camera3D.
@export var main_camera: Camera3D

# Packed scene for the silhouette UI (e.g., SilhouetteUI.tscn)
@export var silhouette_scene: PackedScene

# Dictionary mapping each unit (key) to its UI instance (value).
var unit_ui_instances: Dictionary[Unit, SilhouetteUI] = {}

# Make this manager globally accessible.
static var instance: UnitUIManager = null

func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitUIManager! - " + str(instance))
		queue_free()
		return
	instance = self

# Call this method after UnitManager setup is complete.
# It creates a UI instance for each unit.
func setup_unit_ui(units: Array[Unit]) -> void:
	# Clear any previous UI instances.
	for ui in unit_ui_instances.values():
		if is_instance_valid(ui):
			ui.queue_free()
	unit_ui_instances.clear()
	
	for unit in units:
		# Instantiate a new silhouette UI for the unit.
		var ui_instance: SilhouetteUI = silhouette_scene.instantiate() as SilhouetteUI
		add_child(ui_instance)
		unit_ui_instances[unit] = ui_instance

# Converts the unit's above_marker world position to screen space,
# applies a left offset, and updates the UI instance's position.
func update_ui_positions() -> void:
	for unit in unit_ui_instances.keys():
		var ui_instance: SilhouetteUI = unit_ui_instances[unit]
		if not is_instance_valid(unit) or not is_instance_valid(ui_instance):
			continue
		
		# Get the unit's world position using its above_marker.
		var world_pos: Vector3 = unit.get_world_position_above_marker()
		# Convert world position to 2D screen position.
		var screen_pos: Vector2 = main_camera.unproject_position(world_pos)
		# Apply a slight offset to the left (e.g., 20 pixels).
		screen_pos.x -= 20
		# Update the UI instance's position.
		ui_instance.set_position(screen_pos)

func _process(delta: float) -> void:
	update_ui_positions()
