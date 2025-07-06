extends Control

signal buff_selected(buff_type: String)

# Button-Referenzen
@onready var _heat_buff_container = $VBoxContainer/HBoxContainer/ColorRect
@onready var _base_points_buff_container = $VBoxContainer/HBoxContainer/ColorRect2

func _ready() -> void:
	visible = false  # Initially hidden

func show_shop() -> void:
	visible = true
	
	# Prüfen, welche Buffs bereits aktiviert sind
	if ScoreManager:
		# Heat Buff Container ausblenden, wenn bereits aktiviert
		if _heat_buff_container:
			_heat_buff_container.visible = not ScoreManager.is_heat_bonus_enabled()
		
		# Base Points Buff Container ausblenden, wenn bereits aktiviert
		if _base_points_buff_container:
			_base_points_buff_container.visible = not ScoreManager.is_base_point_increase_enabled()
		
		# Wenn beide Buffs aktiviert sind, einen Hinweis anzeigen
		if ScoreManager.is_heat_bonus_enabled() and ScoreManager.is_base_point_increase_enabled():
			$VBoxContainer/Label.text = "Alle Buffs aktiviert!"
		else:
			$VBoxContainer/Label.text = "Wähle einen Buff:"

func _on_heat_buff_pressed() -> void:
	emit_signal("buff_selected", "heat_bonus")
	visible = false

func _on_base_points_buff_pressed() -> void:
	emit_signal("buff_selected", "base_point_increase")
	visible = false
