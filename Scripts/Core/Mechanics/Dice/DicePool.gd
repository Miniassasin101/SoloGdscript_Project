# DicePool.gd
extends Resource
class_name DicePool

@export var dice_count: int = 0
@export var success_threshold: int = 4  # Rolls ≥ this count as “success”
@export var target_successes: int = 0     # How many successes needed

var results: Array[int] = []

# -1 = crit fail, 0 = fail, 1 = success, 2 = crit
var success_level: int = 0




func _init(_dice_count: int = 0, _target_successes: int = 1, _success_threshold: int = 4) -> void:
	dice_count = _dice_count
	target_successes = _target_successes
	success_threshold = _success_threshold

func roll(pool_size: int = -1) -> void:
	# Roll N d6s and store them
	results.clear()
	var count: int = pool_size if pool_size >= 0 else dice_count
	for i in range(count):
		results.append(randi() % 6 + 1)
	dice_count = count
	
	# Optionally auto-evaluate after rolling
	evaluate()


func evaluate(_target: int = -1) -> int:
	# If caller passed a new target, use it
	if _target >= 0:
		target_successes = _target

	var successes = get_success_count()
	var diff = successes - target_successes

	if diff >= 3:
		success_level = 2
	elif diff <= -3:
		success_level = -1
	elif diff >= 0:
		success_level = 1
	else:
		success_level = 0

	return success_level


func get_success_count() -> int:
	var c := 0
	for r in results:
		if r >= success_threshold:
			c += 1
	return c

func get_result_counts() -> Dictionary:
	# Returns a dict {1: n1, 2: n2, …, 6: n6}
	var tally := {1:0,2:0,3:0,4:0,5:0,6:0}
	for r in results:
		tally[r] += 1
	return tally

func get_average() -> float:
	if results.is_empty():
		return 0.0
	var total: int = results.reduce(func(accum, val):
		return accum + val, 0)
	return float(total) / results.size()

func get_max() -> int:
	return 0 if results.is_empty() else results.max()  # this inline is okay since it's just 2 values

func get_min() -> int:
	return 0 if results.is_empty() else results.min()

func to_str() -> String:
	# Include success_level in the string
	var level_name: String = "" 
	match success_level:
		2: level_name = "Crit Success"
		1: level_name = "Success"
		0: level_name = "Failure"
		-1: level_name = "Crit Fail"
		_: level_name = "Unknown"
	return "Rolls: %s | Successes: %d/%d | Result: %s (%d)" % [
		results,
		get_success_count(),
		target_successes,
		level_name,
		success_level
	]
