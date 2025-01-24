class_name UILayer extends CanvasLayer

static var instance: UILayer = null
@export var damage_number_scene: PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if instance != null:
		push_error("There's more than one UILayer! - " + str(instance))
		queue_free()
		return
	instance = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
