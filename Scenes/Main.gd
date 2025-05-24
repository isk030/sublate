class_name Main
extends Control

# UI Elemente
@onready var _background_area: Control = $BackgroundArea
@onready var _ui_total_score_label: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/Label2
@onready var _ui_factor_one: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect/Label
@onready var _ui_factor_two: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect2/Label
@onready var _ui_card_area: Control = $BackgroundArea/VBoxContainer/HBoxContainer/CardArea
@onready var _menu: Control = $Menu

func _ready() -> void:
	_validate_nodes()
	_initialize_ui()
	_initialize_managers()
	_connect_menu_signals()

func _validate_nodes() -> void:
	var missing_nodes: Array[String] = []
	
	if not _background_area:
		missing_nodes.append("BackgroundArea")
	if not _ui_total_score_label:
		missing_nodes.append("TotalScoreLabel")
	if not _ui_factor_one:
		missing_nodes.append("FactorOneLabel")
	if not _ui_factor_two:
		missing_nodes.append("FactorTwoLabel")
	if not _ui_card_area:
		missing_nodes.append("CardArea")
	
	if not missing_nodes.is_empty():
		push_error("Fehlende UI-Nodes: " + ", ".join(missing_nodes))

func _initialize_ui() -> void:
	# Hide background area at start, show menu
	_background_area.visible = false
	if _menu:
		_menu.visible = true

func _initialize_managers() -> void:
	_initialize_score_manager()
	_initialize_game_manager()

func _initialize_score_manager() -> void:
	if not ScoreManager:
		push_error("ScoreManager (Autoload) nicht gefunden!")
		return
	
	# Direkter Aufruf, da die Methode void zurückgibt
	ScoreManager.set_score_labels(
		_ui_total_score_label, 
		_ui_factor_one, 
		_ui_factor_two
	)

func _initialize_game_manager() -> void:
	if not GameManager:
		push_error("GameManager (Autoload) nicht gefunden!")
		return
	
	GameManager.set_card_area_ref(_ui_card_area)
	GameManager.init_game_elements()
	GameManager.init_player_panel()

func _connect_menu_signals() -> void:
	if _menu:
		_menu.game_start_requested.connect(_on_menu_start_pressed)

func _on_menu_start_pressed() -> void:
	# Hide menu and show game area
	if _menu:
		_menu.visible = false
	_background_area.visible = true
	
	# Reset game state if needed
	if GameManager:
		GameManager.reset_game()
