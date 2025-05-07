class_name DynamicButtonPicker
extends Window  # or WindowDialog/Popup in Godot 4

signal option_selected(chosen_value: String)

@export var dynamic_button_ui_scene: PackedScene
@export var button_container: HBoxContainer

func _ready() -> void:
	# Start hidden/modally. For Windows in Godot 4, you can do:
	visible = false
	#self.window_mode = Window.Mode.MODE_WINDOWED

##
# Show a list of strings as dynamic buttons. In Godot 4, the typical pattern is:
#   1) Call pick_options(options).
#   2) The function returns immediately.
#   3) We "await" the signal 'option_selected' from the outside code.
##
func pick_options(options: Array[String]) -> void:
	# Clear any previous buttons
	for child in button_container.get_children():
		child.queue_free()

	# Add a button for each option
	for opt in options:
		var button_ui = dynamic_button_ui_scene.instantiate() as DynamicButtonUI
		button_container.add_child(button_ui)
		button_ui.setup(opt)
		button_ui.button_clicked.connect(_on_button_clicked)

	# Show the picker
	visible = true
	popup_centered_ratio(0.5)

func _on_button_clicked(chosen_value: String):
	emit_signal("option_selected", chosen_value)
	visible = false
