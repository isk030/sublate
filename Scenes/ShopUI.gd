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
	_award_inventory_items()
	emit_signal("buff_selected", "heat_bonus")
	visible = false

func _on_base_points_buff_pressed() -> void:
	_award_inventory_items()
	emit_signal("buff_selected", "base_point_increase")
	visible = false

# Funktion zur Vergabe von Inventar-Items beim ersten Spielabschluss
func _award_inventory_items() -> void:
	# Prüfe ob InventoryManager-Singleton verfügbar ist
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if not inventory_manager:
		push_error("ShopUI: InventoryManager-Singleton nicht gefunden")
		return
	
	# Initialisiere das Inventar, wenn es das erste Mal ist
	inventory_manager.initialize_inventory()
	
	# Vergebe die Start-Items (wird nur gemacht, wenn das Inventar initialisiert ist)
	inventory_manager.award_start_items()
	
	# Zeige eine Benachrichtigung an
	var notif_label = $VBoxContainer/ItemNotification
	if notif_label:
		notif_label.text = "Du hast ein 'Stap Scratch' Item erhalten!"
		notif_label.visible = true
		
		# Blende die Nachricht nach 3 Sekunden aus
		await get_tree().create_timer(3.0).timeout
		notif_label.visible = false
