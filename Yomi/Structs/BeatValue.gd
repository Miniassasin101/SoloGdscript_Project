class_name BeatValue
extends Resource

@export var value_name: String = "Value Name"
@export var value: float = 10.0
@export var slider_data: SliderData


# When we instantiate the slider in UI, we’ll call this to prime
# the `value` from whatever the slider shows, or vice versa.
func apply_slider_value(new_value: float) -> void:
	value = new_value
