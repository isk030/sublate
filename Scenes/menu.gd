class_name Menu
extends Control

signal game_start_requested
signal exit_requested
signal continue_requested

@onready var _continue_button: Button = %Continue
@onready var _start_button: Button = %StartButton
@onready var _exit_button: Button = %ExitButton
@onready var _error_label: Label = %ErrorLabel

var _opened_via_escape := false

func _ready() -> void:
	_validate_nodes()
	_connect_signals()
	_initialize_ui()

func _validate_nodes() -> void:
	var missing_nodes: Array[String] = []
	
	if not _continue_button:
		missing_nodes.append("Continue")
	if not _start_button:
		missing_nodes.append("StartButton")
	if not _exit_button:
		missing_nodes.append("ExitButton")
	
	if not missing_nodes.is_empty():
		push_error("Fehlende Nodes: " + ", ".join(missing_nodes))

func _connect_signals() -> void:
	if _continue_button:
		_continue_button.pressed.connect(_on_continue_pressed)
	if _start_button:
		_start_button.pressed.connect(_on_start_pressed)
	if _exit_button:
		_exit_button.pressed.connect(_on_exit_pressed)

func _initialize_ui() -> void:
	if _error_label:
		_error_label.visible = false
	if _continue_button:
		_continue_button.visible = false

func _on_start_pressed() -> void:
	game_start_requested.emit()

func set_opened_via_escape(value: bool) -> void:
	_opened_via_escape = value
	if _continue_button:
		_continue_button.visible = value

func _on_continue_pressed() -> void:
	continue_requested.emit()

func _on_exit_pressed() -> void:
	exit_requested.emit()
	get_tree().quit()

func _show_error(message: String) -> void:
	push_error(message)
	if _error_label:
		_error_label.text = "Fehler: " + message
		_error_label.visible = true
