@tool
class_name OverworldNodePath extends Node

@export_tool_button("update") var update_action: Callable = generate_path

@export var overworld_node_1: OverworldNode
@export var overworld_node_2: OverworldNode
@export var number_of_twists: int = 2
@export var twist_variance: float = 0.0
@export var twist_scale: float = 1.0

@export var path_curve: Curve3D

@export var offset_from_ground: float = 0.01

var debug_mesh_instance: MeshInstance3D = null
var debug_mesh: ImmediateMesh = null

func _ready() -> void:
	if Engine.is_editor_hint():
		_create_debug_mesh()

func generate_path_dep() -> void:
	var node_1_pos: Vector3 = overworld_node_1.get_position_for_path()
	var node_2_pos: Vector3 = overworld_node_2.get_position_for_path()
	
	var new_curve: Curve3D = Curve3D.new()
	var points: Array[Vector3] = []
	points.append(node_1_pos)
	
	# Calculate the normalized direction from node1 to node2.
	var direction: Vector3 = (node_2_pos - node_1_pos).normalized()
	# Compute a perpendicular vector (assuming Y is up).
	var side: Vector3 = direction.cross(Vector3.UP).normalized()
	if side == Vector3.ZERO:
		side = Vector3(1, 0, 0)  # Fallback if the direction is vertical
	
	# Create intermediate points with a smooth sine offset.
	for twist in range(number_of_twists):
		var t: float = float(twist + 1) / float(number_of_twists + 1)
		var base_point: Vector3 = node_1_pos.lerp(node_2_pos, t)
		# Use a sine wave to determine the offset (2π gives one full sine wave along the path).
		var sine_offset: float = sin(t * PI * 2.0)
		var twist_point: Vector3 = base_point + side * sine_offset * twist_scale
		points.append(twist_point)
	
	points.append(node_2_pos)
	
	# Now add the points to the curve while setting in/out handles.
	# The handle lengths are determined by a factor (adjustable via handle_factor).
	var handle_factor: float = 0.25
	new_curve.clear_points()
	
	for i in range(points.size()):
		var pos: Vector3 = points[i]
		var in_handle: Vector3 = Vector3.ZERO
		var out_handle: Vector3 = Vector3.ZERO
		
		if i == 0:
			# First point: only define an outgoing handle.
			if points.size() > 1:
				out_handle = (points[i+1] - pos) * handle_factor
		elif i == points.size() - 1:
			# Last point: only define an incoming handle.
			in_handle = (pos - points[i-1]) * handle_factor
		else:
			# For intermediate points, compute an average tangent.
			var tangent: Vector3 = (points[i+1] - points[i-1]).normalized()
			var d_prev: float = (pos - points[i-1]).length()
			var d_next: float = (points[i+1] - pos).length()
			in_handle = -tangent * d_prev * handle_factor
			out_handle = tangent * d_next * handle_factor
		new_curve.add_point(pos, in_handle, out_handle)
	
	path_curve = new_curve
	_update_debug_mesh()  # Refresh the debug visualization
	print_debug("Path made on ", name)

func generate_path() -> void:
	var node_1_pos: Vector3 = overworld_node_1.get_position_for_path()
	var node_2_pos: Vector3 = overworld_node_2.get_position_for_path()
	
	var new_curve: Curve3D = Curve3D.new()
	var points: Array[Vector3] = []
	points.append(node_1_pos)
	
	# Calculate the normalized direction from node1 to node2.
	var direction: Vector3 = (node_2_pos - node_1_pos).normalized()
	# Compute a perpendicular vector (assuming Y is up).
	var side: Vector3 = direction.cross(Vector3.UP).normalized()
	if side == Vector3.ZERO:
		side = Vector3(1, 0, 0)  # Fallback if the direction is vertical
	
	# Create intermediate points with a sine offset that scales with number_of_twists.
	for twist in range(number_of_twists):
		var t: float = float(twist + 1) / float(number_of_twists + 1)
		var base_point: Vector3 = node_1_pos.lerp(node_2_pos, t)
		# Multiply t by number_of_twists * PI to control the number of twists.
		var sine_offset: float = sin(t * number_of_twists * PI)
		var twist_point: Vector3 = base_point + side * sine_offset * twist_scale
		points.append(twist_point)
	
	points.append(node_2_pos)
	
	# Build the curve with in/out handles for smooth Bézier interpolation.
	var handle_factor: float = 0.25
	new_curve.clear_points()
	
	for i in range(points.size()):
		var pos: Vector3 = points[i]
		var in_handle: Vector3 = Vector3.ZERO
		var out_handle: Vector3 = Vector3.ZERO
		
		if i == 0:
			# First point: only outgoing handle.
			if points.size() > 1:
				out_handle = (points[i+1] - pos) * handle_factor
		elif i == points.size() - 1:
			# Last point: only incoming handle.
			in_handle = (pos - points[i-1]) * handle_factor
		else:
			# For intermediate points, calculate a tangent and set both handles.
			var tangent: Vector3 = (points[i+1] - points[i-1]).normalized()
			var d_prev: float = (pos - points[i-1]).length()
			var d_next: float = (points[i+1] - pos).length()
			in_handle = -tangent * d_prev * handle_factor
			out_handle = tangent * d_next * handle_factor
		new_curve.add_point(pos, in_handle, out_handle)
	
	path_curve = new_curve
	_update_debug_mesh()  # Refresh the debug mesh
	print_debug("Path made on ", name)


# Creates a MeshInstance3D with an ImmediateMesh to display our curve.
func _create_debug_mesh() -> void:
	if debug_mesh_instance:
		remove_child(debug_mesh_instance)
		debug_mesh_instance.queue_free()
	
	debug_mesh_instance = MeshInstance3D.new()
	debug_mesh = ImmediateMesh.new()
	debug_mesh_instance.mesh = debug_mesh
	add_child(debug_mesh_instance)

# Updates the ImmediateMesh so the curve is drawn as a red line strip.
func _update_debug_mesh() -> void:
	if not debug_mesh or not path_curve:
		return
	
	# Clear any existing surfaces.
	debug_mesh.clear_surfaces()
	
	# Begin a new surface using a line strip.
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Sample the curve using tessellate_even_length.
	# Adjust max_stages and tolerance_length as needed for smoothness.
	var tess_points: PackedVector3Array = path_curve.tessellate_even_length(5, 0.2)
	
	# Draw each tessellated point.
	for pt in tess_points:
		debug_mesh.surface_set_color(Color(1, 0, 0))  # Red color for visibility
		debug_mesh.surface_add_vertex(pt + Vector3(0, offset_from_ground, 0))
	
	debug_mesh.surface_end()
