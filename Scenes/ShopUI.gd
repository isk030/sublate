extends Control

signal buff_selected(buff_type: String)

# Button-Referenzen
@onready var _heat_buff_container = $VBoxContainer/HBoxContainer/ColorRect
@onready var _base_points_buff_container = $VBoxContainer/HBoxContainer/ColorRect2

# TextureRect-Referenzen
@onready var _heat_buff_texture = $VBoxContainer/HBoxContainer/ColorRect/VBoxContainer2/TextureRect
@onready var _base_points_buff_texture = $VBoxContainer/HBoxContainer/ColorRect2/VBoxContainer3/TextureRect

# Audio-Player für die Gewinn-Musik
@onready var _music_player = AudioStreamPlayer.new()
const GEWINN_MUSIC = preload("res://assets/music/Gewinn.mp3")

func _ready() -> void:
	visible = false  # Initially hidden
	
	# Verbinde die TextureRects mit Klick-Signalen
	if _heat_buff_texture:
		_heat_buff_texture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_heat_buff_texture.gui_input.connect(_on_heat_buff_texture_gui_input)
		
	if _base_points_buff_texture:
		_base_points_buff_texture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_base_points_buff_texture.gui_input.connect(_on_base_points_buff_texture_gui_input)

func show_shop() -> void:
	visible = true
	
	# Pause die Hauptmusik, falls sie abgespielt wird
	var main_node = get_node_or_null("/root/Main")
	if main_node and main_node.has_method("_pause_music"):
		main_node._pause_music()
	
	# Musik-Player initialisieren, falls noch nicht geschehen
	if not _music_player.get_parent():
		_setup_music_player()
		# Kleine Verzögerung, um sicherzustellen, dass die Hauptmusik gestoppt wurde
		await get_tree().create_timer(0.1).timeout
	
	# Musik abspielen
	_music_player.play()
	
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
			$VBoxContainer/Label.text = "Well Done choose your Buff!"

func _on_heat_buff_pressed() -> void:
	_award_inventory_items()
	emit_signal("buff_selected", "heat_bonus")
	visible = false
	_music_player.stop()
	
	# Die Hauptmusik wird automatisch durch das buff_selected-Signal 
	# neu gestartet, wir müssen sie hier nicht manuell starten

func _on_base_points_buff_pressed() -> void:
	_award_inventory_items()
	emit_signal("buff_selected", "base_point_increase")
	visible = false
	_music_player.stop()
	
	# Die Hauptmusik wird automatisch durch das buff_selected-Signal 
	# neu gestartet, wir müssen sie hier nicht manuell starten

# Event-Handler für Klicks auf die Heat-Buff-Textur
func _on_heat_buff_texture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_heat_buff_pressed()

# Event-Handler für Klicks auf die Base-Points-Buff-Textur
func _on_base_points_buff_texture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_base_points_buff_pressed()

# Initialisiert den Musik-Player
func _setup_music_player() -> void:
	# AudioStreamPlayer als Kind-Node hinzufügen
	add_child(_music_player)
	
	# Musik laden und konfigurieren
	_music_player.stream = GEWINN_MUSIC
	_music_player.bus = "Master"
	_music_player.volume_db = -5  # Ein bisschen leiser als Standard
	_music_player.mix_target = AudioStreamPlayer.MIX_TARGET_STEREO
	_music_player.stream_paused = false
	_music_player.autoplay = false
	
	# Loop aktivieren
	_music_player.finished.connect(func(): if visible: _music_player.play())

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
