class_name ColorMarker
extends Node3D

# Preloaded materials
const COLOR_MARKER_BLUE = preload("res://Hero_Game/Art/Materials/ColorMarkerMats/ColorMarkerBlue.tres")
const COLOR_MARKER_GREEN = preload("res://Hero_Game/Art/Materials/ColorMarkerMats/ColorMarkerGreen.tres")
const COLOR_MARKER_RED = preload("res://Hero_Game/Art/Materials/ColorMarkerMats/ColorMarkerRed.tres")
const COLOR_MARKER_WHITE = preload("res://Hero_Game/Art/Materials/ColorMarkerMats/ColorMarkerWhite.tres")
const COLOR_MARKER_YELLOW = preload("res://Hero_Game/Art/Materials/ColorMarkerMats/ColorMarkerYellow.tres")

# Mapping of colors to materials
var color_to_material = {
	"blue": COLOR_MARKER_BLUE,
	"green": COLOR_MARKER_GREEN,
	"red": COLOR_MARKER_RED,
	"white": COLOR_MARKER_WHITE,
	"yellow": COLOR_MARKER_YELLOW,
}

# Reference to the child MeshInstance3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# Animation properties
@export var scale_speed: float = 5.0
@export var target_scale: float = 1.0
var shrinking: bool = false
var growing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mesh_instance == null:
		push_error("No MeshInstance3D found as a child. Please ensure the node has a child MeshInstance3D.")
		return
	mesh_instance.scale = Vector3.ZERO  # Start with scale 0
	SignalBus.hide_success.connect(disappear)

# Method to set the material color based on the color name
func set_color(color_name: StringName) -> void:
	# Check if the color exists in the mapping
	if color_name in color_to_material:
		# Assign the material to the MeshInstance3D
		mesh_instance.material_override = color_to_material[color_name]
	else:
		push_error("Invalid color name: '%s'. Valid colors are: %s" % [color_name, color_to_material.keys()])

# Method to make the marker grow (appear)
func appear() -> void:
	growing = true
	shrinking = false
	mesh_instance.visible = true  # Make sure the marker is visible

# Method to make the marker shrink (disappear)
func disappear() -> void:
	shrinking = true
	growing = false

# Method to set visibility of the marker
func set_visibility(is_vis: bool) -> void:
	if is_vis:
		appear()
	else:
		disappear()

# Called every frame to handle the scaling animation
func _process(delta: float) -> void:
	if growing:
		mesh_instance.scale = mesh_instance.scale.lerp(Vector3.ONE * target_scale, scale_speed * delta)
		if mesh_instance.scale.distance_to(Vector3.ONE * target_scale) < 0.01:
			mesh_instance.scale = Vector3.ONE * target_scale
			growing = false

	if shrinking:
		mesh_instance.scale = mesh_instance.scale.lerp(Vector3.ZERO, scale_speed * delta)
		if mesh_instance.scale.distance_to(Vector3.ZERO) < 0.01:
			mesh_instance.scale = Vector3.ZERO
			shrinking = false
			mesh_instance.visible = false  # Make the marker invisible once fully shrunk
