class_name ObstacleManager
extends Node

var grid_system: GridSystem

func _ready() -> void:
	grid_system = LevelGrid.grid_system
	SignalBus.obstacles_changed.connect(update_obstacles)
	update_obstacles()

func _process(_delta: float) -> void:
	#can optionally add the update obstacles function here
	#Likely wont be neccesary as the game is turn based so events should work fine for obstacles
	pass

func _on_obstacles_changed() -> void:
	update_obstacles()


func update_obstacles() -> void:
	# Gather AABBs from all MeshInstance3D children
	var bounding_boxes = []
	for child in get_children():
		if child is MeshInstance3D:
			var aabb = child.mesh.get_aabb()  # Local AABB of the mesh
			var global_transform = child.global_transform

			# Transform the AABB using the Transform3D operator
			var world_aabb = global_transform * aabb

			# Ensure the resulting AABB has valid size
			if world_aabb.size.x < 0 or world_aabb.size.y < 0 or world_aabb.size.z < 0:
				world_aabb = world_aabb.abs()

			bounding_boxes.append(world_aabb)
		elif child is Node3D:
			# Search for a MeshInstance3D child
			for grandchild in child.get_children():
				if grandchild is MeshInstance3D:
					var mesh_child = grandchild as MeshInstance3D
					var aabb = mesh_child.mesh.get_aabb()  # Local AABB of the mesh
					var global_transform = mesh_child.global_transform
					var world_aabb = global_transform * aabb

					# Ensure the resulting AABB has valid size
					if world_aabb.size.x < 0 or world_aabb.size.y < 0 or world_aabb.size.z < 0:
						world_aabb = world_aabb.abs()

					bounding_boxes.append(world_aabb)
	
	# Pass the bounding boxes to the grid system
	grid_system.update_walkability_from_bounding_boxes(bounding_boxes)

	
	# Pass the bounding boxes to the grid system
	grid_system.update_walkability_from_bounding_boxes(bounding_boxes)
