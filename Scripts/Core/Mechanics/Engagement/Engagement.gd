class_name Engagement extends RefCounted

## The two engaged units
var units: Array[Unit]
var line_fx: EngagementLineFX = null

func _init(unit1: Unit, unit2: Unit) -> void:
	units.append(unit1)
	units.append(unit2)
	
	# Automatic handling of weapon reach here



func initialize_line(engagement_manager: Node) -> void:
	line_fx = EngagementLineFX.new(units[0].chest_marker, units[1].chest_marker)
	engagement_manager.add_child(line_fx)
	line_fx.attach_to(engagement_manager)
	line_fx.is_active = true

func remove_engagement() -> void:
	line_fx.is_active = false
	line_fx.remove()
	self.free()
