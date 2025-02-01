@tool
class_name DynamicButtonUI
extends Button

@export var button_text: Label
@export var button: Button

signal button_clicked(value)

func _ready() -> void:
	# Connect the built-in "pressed" signal
	self.pressed.connect(_on_button_pressed)

func setup(in_text: String) -> void:
	# Either set an internal Label or just set this Button's text
	if button_text and is_instance_valid(button_text):
		button_text.set_text(in_text)


func _on_button_pressed() -> void:
	# Emit a signal with the button's text (or label text)
	var final_text = button_text.get_text()
	button_clicked.emit(final_text)
