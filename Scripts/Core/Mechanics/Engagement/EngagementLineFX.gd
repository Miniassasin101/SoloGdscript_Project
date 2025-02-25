extends Node
class_name EngagementLineFX

var start_point: Node3D
var end_point: Node3D
var line_color: Color = Color.RED # Red glow
var line_thickness: float = 2.0

var immediate_mesh: ImmediateMesh
var mesh_instance: MeshInstance3D
#var material: StandardMaterial3D
var material: ShaderMaterial

var is_active: bool = false

func _init(in_start_point: Node3D, in_end_point: Node3D):
	# Create MeshInstance3D to hold the ImmediateMesh
	mesh_instance = MeshInstance3D.new()
	immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh

	# Create a glowing shader material
	#material = StandardMaterial3D.new()
	#material.albedo_color = Color.RED
	
	material = ShaderMaterial.new()
	material.shader = load("res://Hero_Game/Art/Shaders/VFX_Shaders/engagement_line_shader.gdshader") # Use an external shader file
	mesh_instance.material_override = material
	start_point = in_start_point
	end_point = in_end_point

func _physics_process(delta: float) -> void:
	if is_active:
		update_line()

func update_line():
	if not (start_point and end_point):
		return
	
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	immediate_mesh.surface_set_color(line_color)
	
	var pointA: Vector3 = start_point.global_transform.origin
	var pointB: Vector3 = end_point.global_transform.origin
	#pointB = pointA + pointB
	
	var scale_factor := 100.0
	
	var dir := pointA.direction_to(pointB)
	
	var EPSILON = 0.00001
	
	# Calculate direction and perpendicular for thickness

	var normal := Vector3(-dir.y, dir.x, 0).normalized() \
		if (abs(dir.x) + abs(dir.y) > EPSILON) \
		else Vector3(0, -dir.z, dir.y).normalized()
	normal *= line_thickness / scale_factor

	# Define a quad to make the line thick
	var vertices_strip_order = [4, 5, 0, 1, 2, 5, 6, 4, 7, 0, 3, 2, 7, 6]
	var localB = (pointB - pointA)

	for i in range(14):
		var vertex = normal if vertices_strip_order[i] < 4 else normal + localB
		var final_vert = vertex.rotated(dir, PI * (0.5 * (vertices_strip_order[i] % 4) + 0.25))
		
		final_vert += pointA

		
		immediate_mesh.surface_add_vertex(final_vert)

	immediate_mesh.surface_end()

func attach_to():
	add_child(mesh_instance)

func remove():
	if mesh_instance:
		mesh_instance.queue_free()
