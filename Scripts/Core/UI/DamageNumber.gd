class_name DamageNumber extends Control


@export var animator: AnimationPlayer
@export var number_label: Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play(text: String = "N/A") -> void:
	setup_text(text)
	play_anim()


func setup_text(text: String = "N/A") -> void:
	number_label.set_text(text)


func play_anim() -> void:
	animator.play("DamageNumberAnim")
