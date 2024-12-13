class_name Calculations
extends RefCounted

func attributes_add(attributes: Array[AttributeSpec]) -> int:
	var out: int = 0
	for attribute in attributes:
		out += int(attribute.current_buffed_value)
	return out
