class_name TurnSystemUI
extends Control

@export var end_turn_button: Button
@export var end_turn_container: PanelContainer
@export var turn_counter_label: Label
@export var turn_system: TurnSystem
@export var enemy_turn_container: PanelContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.on_turn_changed.connect(on_turn_changed)

	update_turn_label()




func _on_end_turn_button_pressed() -> void:
	SignalBus.emit_signal("end_turn")

func on_turn_changed() -> void:
	update_enemy_turn_visual()
	update_turn_label()

func update_turn_label() -> void:
	turn_counter_label.text = "Turn " + str(turn_system.turn_number)

func update_enemy_turn_visual() -> void:
	var is_player_turn: bool = TurnSystem.instance.is_player_turn
	enemy_turn_container.visible = !is_player_turn
	if !LevelDebug.instance.end_turn_debug:
		end_turn_container.visible = is_player_turn
