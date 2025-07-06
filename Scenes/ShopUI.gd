extends Control

signal buff_selected(buff_type: String)

func _ready() -> void:
	visible = false  # Initially hidden

func show_shop() -> void:
	visible = true
	# Add any animation or transition effects here

func _on_heat_buff_pressed() -> void:
	emit_signal("buff_selected", "heat_bonus")
	visible = false

func _on_base_points_buff_pressed() -> void:
	emit_signal("buff_selected", "base_point_increase")
	visible = false
