# DynamicSlider.gd
# This script is intended to live on a PanelContainer whose child structure looks like:
#
# DynamicSlider (PanelContainer) [ this node has the script ]
# └ VBoxContainer
#   ├ ValueNameLabel               <-- Label showing the “name” of this slider
#   └ HBoxContainer
#       ├ CurrentSliderValueLabel  <-- Label that displays the current numeric value
#       └ HSlider                  <-- The actual slider control
#
# Behavior:
#   • Exposes exported vars to configure name, min, max, step, and initial value.
#   • Automatically updates CurrentSliderValueLabel whenever the slider moves.
#   • Emits `value_changed(new_value: float)` whenever the user drags/releases the slider.
#   • You can also call `set_value()`, `set_range()`, or `set_name()` at runtime if needed.

extends PanelContainer
class_name DynamicSlider

# SIGNALS
# Emitted whenever the slider’s value changes (either by user input or by set_value()).
signal value_changed(new_value: float)


# —— NODE REFERENCES (filled automatically in _ready) ——
@export var _value_name_label: Label
@export var _current_value_label: Label
@export var _hslider: HSlider


# —— EDITOR‐EXPOSED PROPERTIES ——
# The textual “name” you want to display above/next to the slider.
@export var slider_name: String = "Slider"

# Range of the slider
@export_range(0, 100, 1) var min_value: float = 0
@export_range(0, 100, 1) var max_value: float = 100

# Step (increment) for the HSlider
@export var step: float = 1

# Initial/default value when the scene is instantiated
@export var initial_value: float = floor(max_value/2)

# Whether the CurrentSliderValueLabel should show zero‐decimals or one‐decimal (e.g. “42” vs “42.5”)
@export var decimals: int = 0

var beat_value: BeatValue = null

func _ready() -> void:

	# 2) Configure the HSlider based on exported variables
	#_hslider.min_value = min_value
	#_hslider.max_value = max_value
	#_hslider.step = step
	#_hslider.value = initial_value

	# 3) Set labels (name + current value)
	_update_name_label()
	_update_current_value_label(_hslider.value)

	# 4) Connect the HSlider’s “value_changed” signal
	#_hslider.connect("value_changed", Callable(self, "_on_HSlider_value_changed"))


func _on_HSlider_value_changed(value: float) -> void:
	# Update the numeric label
	_update_current_value_label(value)
	# Emit our own signal so parent/UI logic can respond
	emit_signal("value_changed", value)


func _update_name_label() -> void:
	if _value_name_label:
		_value_name_label.text = slider_name


func _update_current_value_label(value: float) -> void:
	if _current_value_label:
		if decimals <= 0:
			# Show as integer (rounded)
			var int_val = int(round(value))
			# Format with a single "{_}" placeholder:
			_current_value_label.text = str(int_val)
		else:
			# Show with exactly `decimals` decimal places.
			# Using String.pad_decimals() is simpler than trying to force
			# printf‐style formatting via String.format():
			_current_value_label.text = str(value).pad_decimals(decimals)


# —— PUBLIC API ——

# Change the slider’s displayed name at runtime
func set_slider_name(new_name: String) -> void:
	slider_name = new_name
	_update_name_label()

# Change the min/max/step of the slider at runtime.
# Calling this will clamp the current value into the new range if necessary.
func set_range(new_min: float = 0.0, new_max: float = 100.0, new_step: float = 1.0) -> void:
	min_value = new_min
	max_value = new_max
	step = new_step

	_hslider.min_value = min_value
	_hslider.max_value = max_value
	_hslider.step = step

	# Clamp current value
	if _hslider.value < min_value:
		_hslider.value = min_value
	elif _hslider.value > max_value:
		_hslider.value = max_value

	_update_current_value_label(_hslider.value)

# Programmatically set the slider’s value, updating the label and emitting the signal.
func set_value(new_value: float) -> void:
	var clamped = clamp(new_value, min_value, max_value)
	#if !is_equal_approx(clamped, _hslider.value):
	_hslider.value = clamped
	_update_current_value_label(clamped)
	value_changed.emit(clamped)

# Retrieve the current slider value
func get_value() -> float:
	return _hslider.value

# Change how many decimal places to show in CurrentSliderValueLabel
func set_decimals(new_decimals: int = 0) -> void:
	decimals = max(new_decimals, 0)
	# Refresh the text immediately
	_update_current_value_label(_hslider.value)


func disconnect_all() -> void:
	if beat_value:
		if value_changed.has_connections():
			value_changed.disconnect(beat_value.apply_slider_value)
		#var connections := value_changed.get_connections()
		
		#for connection in connections:
		#	for key in connection:
				
