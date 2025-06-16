# DynamicBeatEvent.gd
# ---------------------
# Base class for any BeatEvent that needs one or more “tweakable” numeric parameters.
# You can extend this class and add additional logic in on_beat_event(...), but all
# slider‐related setup/teardown happens here.

class_name DynamicBeatEvent
extends BeatEvent

# An array of BeatValue Resources: each one holds (value_name, value, slider_data).
@export var beat_values: Array[BeatValue] = []



func make_unique() -> void:
	if is_unique:
		return
	var old_beat_values: Array[BeatValue] = [] 
	old_beat_values.append_array(beat_values)
	beat_values.clear()
	for b_val in old_beat_values:
		beat_values.append(b_val.duplicate())

	#beat_values = beat_values.duplicate(true)
	is_unique = true


# Retrieve a BeatValue Resource by its “value_name” property.
# Returns null if no match is found.
func get_beat_value_by_name(val_name: String) -> BeatValue:
	for bv in beat_values:
		if bv.value_name == val_name:
			return bv

	return beat_values.front()

func setup_slider_ui() -> void:
	var slider_container: DynamicSliderContainer = ActionSystemUI.instance.dynamic_slider_container
	
	for beat_val in beat_values:
		var sd: SliderData = beat_val.slider_data
		
		slider_container.add_slider(sd, self)   # initial data (current)
		
		
   # 4) Connect the container’s aggregate signal so we can update each BeatValue:
	slider_container.slider_value_changed.connect(_on_any_slider_changed)

	# 5) Finally, parent it and show it:

	slider_container.show_container()


# Optional: in case you want to re‐initialize the slider values when a new State run begins:
func reset_beat_values_to_defaults() -> void:
	for bv in beat_values:
		bv.value = bv.slider_data.initial_value



# INTERNAL CALLBACK: called whenever any one DynamicSlider inside the container changes.
# We receive both the slider_name and the new numeric value. Find the matching BeatValue
# by name and update its `.value`.
func _on_any_slider_changed(changed_name: String, new_val: float) -> void:
	var bv = get_beat_value_by_name(changed_name)
	if bv:
		bv.apply_slider_value(new_val)
