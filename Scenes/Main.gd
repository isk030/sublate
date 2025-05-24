extends Control

@onready var ui_total_score_label: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/Label2
@onready var ui_factor_one: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect/Label
@onready var ui_factor_two: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect2/Label

@onready var ui_card_area: Control = $BackgroundArea/VBoxContainer/HBoxContainer/CardArea

@onready var background_area = $BackgroundArea
@onready var menu = $Menu

func _ready() -> void:
	background_area.visible = false
	
	
	if ScoreManager != null:
		ScoreManager.set_score_labels(ui_total_score_label, ui_factor_one, ui_factor_two)
	else:
		printerr("Main-Szene: FEHLER: ScoreManager (Autoload) nicht gefunden! Bitte in Projekteinstellungen prüfen.")
	
	if GameManager != null:
		GameManager.set_card_area_ref(ui_card_area)
		GameManager.init_game_elements()
		GameManager.init_player_panel()
	else:
		printerr("Main-Szene: FEHLER: GameManager (Autoload) nicht gefunden! Bitte in Projekteinstellungen prüfen.")
