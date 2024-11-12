class_name GridPosition
extends RefCounted

var x: int
var z: int

# Constructor
func _init(x: int, z: int) -> void:
	self.x = x
	self.z = z

# Method to add two GridPosition objects
func add(other: GridPosition) -> GridPosition:
	return GridPosition.new(self.x + other.x, self.z + other.z)

# Method to subtract one GridPosition from another
func subtract(other: GridPosition) -> GridPosition:
	return GridPosition.new(self.x - other.x, self.z - other.z)

# Equality check method for comparing with another GridPosition
func equals(other: GridPosition) -> bool:
	# Check if 'other' is not null and has the same x and z values
	return other != null and other.x == self.x and other.z == self.z

# Override to provide equality comparison
func _equals(obj) -> bool:
	# Check if 'obj' is a GridPosition and compare 'x' and 'z'
	return obj is GridPosition and self.x == obj.x and self.z == obj.z

# Custom hash code generation method (similar to GetHashCode)
func get_hash_code() -> int:
	# Combine 'x' and 'z' values into a unique hash
	return int((x * 31) + z) # Simple hash using a prime multiplier (31)

# Override the '!=', which can be done by negating '==' comparison.
func _not_equals(obj) -> bool:
	return not _equals(obj)

# Workaround for to_string override in GDScript (as it's not officially provided)
func to_str() -> String:
	return "(x=%d, z=%d)" % [x, z]
