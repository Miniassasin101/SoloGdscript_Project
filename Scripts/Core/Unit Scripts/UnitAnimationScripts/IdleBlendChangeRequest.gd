class_name IdleBlendChangeRequest
extends RefCounted

enum BaseAnimBackup {None, Left, Right}

var base_idle_animation: Animation = null

var right_idle_animation: Animation = null

var left_idle_animation: Animation = null

var animation_library_name: String = "HumanoidAnimLib01/"

var base_idle_animation_path: String = ""

var right_idle_animation_path: String = ""

var left_idle_animation_path: String = ""

var blend_left: bool = false

var blend_right: bool = false

var clear_all: bool = false

var base_anim_backup: int = BaseAnimBackup.Left

func _init(
	_base_idle_animation: Animation = null,
	_right_idle_animation: Animation = null,
	_left_idle_animation: Animation = null,
	_blend_left: bool = false,
	_blend_right: bool = false,
	_base_anim_backup: int = BaseAnimBackup.Left,
	_animation_library_name: String = "HumanoidAnimLib01/"
) -> void:
	base_idle_animation = _base_idle_animation
	right_idle_animation = _right_idle_animation
	left_idle_animation = _left_idle_animation

	blend_left = _blend_left
	blend_right = _blend_right
	base_anim_backup = _base_anim_backup

	animation_library_name = _animation_library_name

	# If right or left animations exist, generate their paths
	if right_idle_animation:
		right_idle_animation_path = animation_library_name + right_idle_animation.resource_name
	if left_idle_animation:
		left_idle_animation_path = animation_library_name + left_idle_animation.resource_name
	
	if base_idle_animation == null:
		match base_anim_backup:
			BaseAnimBackup.None:
				pass
			BaseAnimBackup.Left:
				base_idle_animation = left_idle_animation if left_idle_animation else right_idle_animation
				if !left_idle_animation:
					base_anim_backup = BaseAnimBackup.Right
			BaseAnimBackup.Right:
				base_idle_animation = right_idle_animation if right_idle_animation else left_idle_animation
				if !right_idle_animation:
					base_anim_backup = BaseAnimBackup.Left
	
	if base_idle_animation != null:
		base_idle_animation_path = animation_library_name + base_idle_animation.resource_name
		
		
