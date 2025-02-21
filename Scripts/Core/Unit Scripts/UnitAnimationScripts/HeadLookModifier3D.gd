@tool
class_name HeadLookModifier3D
extends SkeletonModifier3D

""" 10 Step Setup Guide:
	1. Setup your Skeleton3D
	2. Add this Script/Class to your project
	3. Add a child node of this class to your Skeleton3D
	4. Make sure you have the EXACT name of your neck bone saved somewhere, in my case it was "DEF_neck.001"
	5. Add a BoneAttatchment3D child node to your skeleton and point it at your neck bone
	6. Add a Marker3d (or other Node3D) as a child of the BoneAttatchment3D, this will be the root marker
	7. Add another Marker3D as a guide for the neck as a child of THAT Marker3D. This is reffered to as "neck_guide" below
	8. Add a sibling RemoteTransform3D that is also a child of the neck root and copies ONLY it's position to the neck_guide
	9. Set up the empty exported fields in HeadLookModifier and MAKE SURE that you 
	10. Use your own logic for setting the SkeletonModifier to active or blending the influence, but otherwise it should just work now!
	
	NOTE: If the head seems to be looking slightly above the target, try moving the neck root up to the center of the head
	Either that, or change the setup to use the head instead of the neck
"""




# Either manually put the name of the bone here or better yet, use a type hint to avoid user error
@export var neck_bone: String = "DEF_neck.001"

# This marker will look at the target position and be used as a base for calculations
@export var neck_guide: Marker3D
@export var neck_root: Marker3D

@export var chest_root: Marker3D
# The node that the 
@export var look_target_path: NodePath

@export var head_look_vertical_offset: float = 0.0
@export var head_look_horizantal_offset: float = 0.0
@export var max_horizontal_angle: float = 90.0
@export var max_vertical_angle: float = 20.0



@export var tween_time: float = 0.5

var look_target: Node3D = null

var _current_tween: Tween = null


func set_modifier_active_and_target(value: bool, target: Node3D = null) -> void:
	set_look_target(target)
	set_modifier_active(value)

func set_look_target(target: Node3D = null) -> void:
	look_target = target

func set_modifier_active(value: bool) -> void:
	# If the state is already what we want, do nothing.
	if active == value:
		return

	if value:
		# When activating, set active immediately and tween the influence to 1.
		active = true
		if _current_tween:
			_current_tween.kill()
		_current_tween = create_tween()
		_current_tween.tween_property(self, "influence", 1.0, tween_time)
	else:
		# When deactivating, first tween influence to 0...
		if _current_tween:
			_current_tween.kill()
		_current_tween = create_tween()
		_current_tween.tween_property(self, "influence", 0.0, tween_time)
		# ...then, when the tween finishes, mark the modifier as inactive.
		_current_tween.connect("finished", Callable(self, "_on_inactive_tween_finished"))

func _on_inactive_tween_finished() -> void:
	active = false
	_current_tween = null

func _ready() -> void:
	# Initialize influence to match the starting active state.
	influence = 1.0 if active else 0.0


func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	var neck_idx = skeleton.find_bone(neck_bone)
	if !look_target:
		look_target = get_node_or_null(look_target_path)
	neck_guide.look_at(look_target.global_position, Vector3.UP, true)
	

	var parent_idx: int = skeleton.get_bone_parent(neck_idx)
	var parent_global: Transform3D = skeleton.get_bone_global_pose(parent_idx)
	var neck_global: Quaternion =  skeleton.get_bone_global_pose(neck_idx).basis.get_rotation_quaternion() - skeleton.get_bone_pose(neck_idx).basis.get_rotation_quaternion()
	var parent_euler: Vector3 = neck_root.rotation_degrees
	var marker_rotation_degrees: Vector3 = neck_guide.rotation_degrees
	#marker_rotation_degrees = marker_rotation_degrees - parent_euler
	marker_rotation_degrees.x = clamp(marker_rotation_degrees.x, -max_vertical_angle, max_vertical_angle)
	marker_rotation_degrees.y = clamp(marker_rotation_degrees.y, -max_horizontal_angle, max_horizontal_angle)
	var new_rotation: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(marker_rotation_degrees.x + head_look_vertical_offset), deg_to_rad(marker_rotation_degrees.y + head_look_horizantal_offset), 0.0))
	
	
	
	new_rotation = new_rotation - neck_global

	
	
	
	#new_rotation = new_rotation * Quaternion(parent_global.affine_inverse().basis.orthonormalized())
	
	
	# Optionally reset the pose rotation of the subsequent bone (if needed).
	skeleton.set_bone_pose_rotation(neck_idx + 1, Quaternion.from_euler(Vector3.ZERO))
	
	#new_rotation = new_rotation * Quaternion(skeleton.global_basis.inverse().orthonormalized())
	skeleton.set_bone_pose_rotation(neck_idx, new_rotation)
	
