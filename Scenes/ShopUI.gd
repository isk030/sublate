extends Control

signal buff_selected(buff_type: String)
signal continue_game
signal exit_game
signal new_run

# Button-Referenzen
@onready var _heat_buff_container = $VBoxContainer/HBoxContainer/ColorRect
@onready var _base_points_buff_container = $VBoxContainer/HBoxContainer/ColorRect2

# TextureRect-Referenzen
@onready var _heat_buff_texture = $VBoxContainer/HBoxContainer/ColorRect/VBoxContainer2/TextureRect
@onready var _base_points_buff_texture = $VBoxContainer/HBoxContainer/ColorRect2/VBoxContainer3/TextureRect

# Audio-Player für die Gewinn-Musik
@onready var _music_player = AudioStreamPlayer.new()
@onready var _continue_button = $VBoxContainer/ButtonsContainer/ContinueButton
@onready var _new_run_button = $VBoxContainer/ButtonsContainer/NewRunButton
@onready var _menu_button = $VBoxContainer/ButtonsContainer/MenuButton
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
		
	# Connect buttons
	if _continue_button:
		_continue_button.pressed.connect(_on_continue_button_pressed)
		print("Continue button connected")

	if _new_run_button:
		_new_run_button.pressed.connect(_on_new_run_button_pressed)
		print("New Run button connected")
		
	if _menu_button:
		_menu_button.pressed.connect(_on_menu_button_pressed)
		print("Menu button connected")
	
	# Buttons initial ausblenden
	$VBoxContainer/ButtonsContainer.visible = false

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
	
	# Debug: Zeige den aktuellen Status der Buff-Flags
	print("\n==== ShopUI: show_shop ====")
	if ScoreManager:
		print("Heat Bonus aktiviert: ", ScoreManager.is_heat_bonus_enabled())
		print("Base Points Bonus aktiviert: ", ScoreManager.is_base_point_increase_enabled())
	else:
		print("ScoreManager nicht verfügbar!")
	
	# Prüfe und hole den Zustand der Buffs vom ScoreManager
	if ScoreManager:
		var heat_enabled = ScoreManager.is_heat_bonus_enabled()
		var base_points_enabled = ScoreManager.is_base_point_increase_enabled()
		print("ShopUI: Heat buff enabled: ", heat_enabled)
		print("ShopUI: Base points buff enabled: ", base_points_enabled)
		
		# Aktiviere oder deaktiviere die Buff-Container entsprechend
		# Wenn ein Buff bereits aktiviert ist, wird er nicht mehr angezeigt
		print("\nUpdating buff container visibility:")
		if _heat_buff_container:
			_heat_buff_container.visible = not heat_enabled
			print("Heat buff container visible: ", not heat_enabled, 
				  ", because heat_enabled = ", heat_enabled)
		if _base_points_buff_container:
			_base_points_buff_container.visible = not base_points_enabled
			print("Base points buff container visible: ", not base_points_enabled, 
				  ", because base_points_enabled = ", base_points_enabled)
		
		print("\nChecking if both buffs are activated:")
		# Wenn beide Buffs aktiviert sind, einen Hinweis anzeigen und Buttons anzeigen
		if heat_enabled and base_points_enabled:
			$VBoxContainer/Label.text = "All Buffs activated!"
			# Buttons anzeigen
			$VBoxContainer/ButtonsContainer.visible = true
			print("Both buffs are activated (heat=true, base_points=true) - showing continue/menu buttons")
		else:
			$VBoxContainer/Label.text = "Well Done! Choose your Buff!"
			# Buttons ausblenden
			$VBoxContainer/ButtonsContainer.visible = false
			print("Not all buffs activated (heat=", heat_enabled, ", base_points=", base_points_enabled, ") - hiding buttons")
	else:
		print("ERROR: ScoreManager not found in show_shop!")
	print("==== ShopUI: show_shop Ende ====")

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

# Handler für den Continue-Button
func _on_continue_button_pressed() -> void:
	emit_signal("continue_game")
	visible = false
	_music_player.stop()
	
	# Die Hauptmusik wird automatisch neu gestartet
	# (ähnlich wie bei den Buff-Buttons)

# Handler für den New Run Button - startet ein komplett neues Spiel
func _on_new_run_button_pressed() -> void:
	print("New Run button pressed - starting fresh game")
	emit_signal("new_run")
	visible = false
	_music_player.stop()
	
# Handler für den EXIT-Button
func _on_menu_button_pressed() -> void:
	emit_signal("exit_game")
	visible = false
	_music_player.stop()

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

# Zeigt den Game Over Bildschirm mit dem finalen Score
func show_game_over_screen(final_score: int) -> void:
	# Zeige die Shop-UI an
	visible = true
	
	# Spiele die Gewinn-Musik ab
	if not _music_player.get_parent():
		_setup_music_player()
		await get_tree().create_timer(0.1).timeout
	
	_music_player.play()
	
	# Rufe die übergeordnete Szene auf, um die Hauptmusik zu pausieren
	var parent = get_parent()
	if parent and parent.has_method("_pause_music"):
		parent._pause_music()
	
	# Verstecke alle Buff-Container
	if _heat_buff_container:
		_heat_buff_container.visible = false
	if _base_points_buff_container:
		_base_points_buff_container.visible = false
	
	# WICHTIG: Entferne ALLE vorhandenen Score-Anzeigen in der VBoxContainer
	# Suche nach ALLEN Nodes, die ScoreContainer im Namen haben oder Score-Labels sein könnten
	for child in $VBoxContainer.get_children():
		# Entferne alle bestehenden Score Container
		if child.name == "ScoreContainer" or "Score" in child.name:
			child.queue_free()
		# Prüfe auch explizit auf Labels mit Score-Texten
		elif child is Label and ("score" in child.text.to_lower() or child.text.is_valid_int()):
			child.visible = false
	
	# Warte kurz, bis die zu entfernenden Nodes wirklich entfernt wurden
	await get_tree().process_frame
	
	# Erstelle einen neuen Container für den Score
	var score_container = VBoxContainer.new()
	score_container.name = "ScoreContainer"
	score_container.size_flags_horizontal = Control.SIZE_FILL
	score_container.size_flags_vertical = Control.SIZE_FILL
	
	# Erstelle das "Your Score" Label
	var score_title = Label.new()
	score_title.text = "Your Score"
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_title.add_theme_font_size_override("font_size", 32)
	score_title.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Erstelle das Label für den Punktestand (nur aktueller Run)
	var score_value = Label.new()
	score_value.text = str(final_score)
	score_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_value.add_theme_font_size_override("font_size", 48)
	score_value.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	
	# Füge die Labels zum Container hinzu
	score_container.add_child(score_title)
	score_container.add_child(score_value)
	
	# Füge den Container zur UI hinzu und positioniere ihn ganz oben
	$VBoxContainer.add_child(score_container)
	$VBoxContainer.move_child(score_container, 0)
	
	# Zeige nur den New Run und EXIT Button
	if _continue_button:
		_continue_button.visible = false
	if _new_run_button:
		_new_run_button.visible = true
	if _menu_button:
		_menu_button.visible = true
	$VBoxContainer/ButtonsContainer.visible = true
	
	# Aktualisiere den Titel-Text
	if $VBoxContainer.has_node("Label"):
		$VBoxContainer/Label.text = "Game Over"
	
	print("Game over screen shown with final score: ", final_score)
