# DynamicSliderContainer.gd
# A PanelContainer that can hold any number of DynamicSlider children.
# Use `.add_slider(...)` to create and configure each inner slider on‐the‐fly.
#
# Scene hierarchy MUST be:
#   DynamicSliderContainer (PanelContainer)    ← this script is attached here
#   └ MarginContainer
#     └ VBoxContainer
#       ├ TitleLabel                         ← a Label node (for the group’s title)
#       ├ HSeparator
#       └ SlidersVBoxContainer               ← a VBoxContainer (initially empty)

extends PanelContainer
class_name DynamicSliderContainer

# ─── SIGNALS ─────────────────────────────────────────────────────────────────
# Emitted whenever any inner DynamicSlider’s value changes.
# We pass both the slider’s “name” and the new numeric value.
signal slider_value_changed(slider_name: String, new_value: float)

# ─── EDITOR‐EXPOSED NODES & PROPERTIES ─────────────────────────────────────────
# (Assign these in the Inspector, or leave them blank and rely on default paths.)



# Drag your DynamicSlider.tscn here in the Inspector:
@export var dynamic_slider_scene: PackedScene

# ─── INTERNAL STATE ────────────────────────────────────────────────────────────
@export var _title_label: Label
@export var _sliders_vbox: VBoxContainer
var _sliders: Array = []         # Holds references to all DynamicSlider instances we create

func _ready() -> void:

	#  Start hidden (you can call `show_container()` when you actually need it):
	visible = false


# ─── ADD / REMOVE / QUERY SLIDERS ──────────────────────────────────────────────

# Create a new DynamicSlider under SlidersVBoxContainer.
#   • name          : the label that appears above that particular slider.
#   • min_val / max_val / step_val : range and increment.
#   • initial_val   : starting value (will be clamped to [min_val, max_val]).
#   • decimal_places: how many digits after the decimal point to show.
#
# Returns the newly‐created DynamicSlider instance, or null on error.
func add_slider(
		slider_name: String,
		min_val: float,
		max_val: float,
		step_val: float = 1.0,
		initial_val: float = 0.0,
		decimal_places: int = 0
	) -> DynamicSlider:
	if not dynamic_slider_scene:
		push_error("DynamicSliderContainer: dynamic_slider_scene is not assigned.")
		return null

	# 1) Instantiate the PackedScene:
	var new_slider = dynamic_slider_scene.instantiate() as DynamicSlider
	if new_slider == null:
		push_error("DynamicSliderContainer: Failed to instantiate DynamicSlider.")
		return null

	# 2) Configure its exported properties:
	new_slider.set_name(slider_name)             # This updates the ValueNameLabel inside it
	new_slider.set_range(min_val, max_val, step_val)
	new_slider.set_decimals(decimal_places)
	new_slider.set_value(initial_val)             # Clamped automatically

	# 3) Give it a node‐name so we can find/remove it by name if needed:
	new_slider.name = slider_name

	# 4) Add it to our VBox so it shows up vertically:
	_sliders_vbox.add_child(new_slider)
	_sliders.append(new_slider)

	# 5) Forward its `value_changed` signal, but prepend with this slider’s name:
	new_slider.connect(
		"value_changed",
		Callable(self, "_on_inner_slider_changed").bind(slider_name)
	)

	return new_slider


# Called whenever any child DynamicSlider emits `value_changed`.
# We re‐emit as `slider_value_changed(slider_name, new_value)`.
func _on_inner_slider_changed(slider_name: String, new_value: float) -> void:
	emit_signal("slider_value_changed", slider_name, new_value)


# Remove (and free) a specific slider by the name you gave in add_slider(…).
func remove_slider_by_name(slider_name: String) -> void:
	for s in _sliders:
		if s.get_name() == slider_name:
			_sliders.erase(s)
			s.queue_free()
			return


# Remove all sliders at once:
func clear_sliders() -> void:
	for s in _sliders:
		s.queue_free()
	_sliders.clear()


# You can also retrieve a slider instance by its name:
func get_slider_by_name(slider_name: String) -> DynamicSlider:
	for s in _sliders:
		if s.get_name() == slider_name:
			return s
	return null


# ─── PUBLIC API ────────────────────────────────────────────────────────────────

# Set the group title (text shown in TitleLabel at the top of this container)
func set_title(text: String) -> void:
	if not _title_label:
		_title_label = $MarginContainer/VBoxContainer/TitleLabel
	_title_label.text = text


# Show this entire container (panel + all its sliders).
func show_container() -> void:
	visible = true


# Hide (but do not free) this container.
func hide_container() -> void:
	visible = false


# Fully free this container and all its child sliders.
func queue_free_container() -> void:
	queue_free()
