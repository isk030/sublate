class_name Main
extends Control

# UI Elemente
@onready var _background_area: Control = $BackgroundArea
@onready var _ui_total_score_label: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/Label2
@onready var _ui_factor_one: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect/Label
@onready var _ui_factor_two: Label = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/ScorePanel/VBoxContainer/HBoxContainer/ColorRect2/Label
@onready var _ui_card_area: Control = $BackgroundArea/VBoxContainer/HBoxContainer/CardArea
@onready var _menu: Control = $Menu
@onready var _shop_ui: Control = $ShopUI
@onready var _inventory_panel: Control = $BackgroundArea/VBoxContainer/HBoxContainer/PlayerPanel/InventoryPanel

# Musik-System - verwende eine globale Variable für den Player, um mehrere Instanzen zu vermeiden
var _music_player: AudioStreamPlayer = null
var _available_music = []
var _last_played_music = ""
var _is_music_initialized = false
const GEWINN_MUSIC_PATH = "res://assets/music/Gewinn.mp3"

func _ready() -> void:
	# Stelle sicher, dass der Node Eingaben empfängt
	print("Main scene ready")
	print("Input map has ui_cancel:", InputMap.has_action("ui_cancel"))
	_validate_nodes()
	_initialize_ui()
	_initialize_managers()
	_connect_menu_signals()
	# Aktiviere die Verarbeitung von Eingaben
	set_process_input(true)
	
	# Initialisiere das Musik-System
	_initialize_music_system()

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
	if not _inventory_panel:
		missing_nodes.append("InventoryPanel")
	
	if not missing_nodes.is_empty():
		push_error("Fehlende UI-Nodes: " + ", ".join(missing_nodes))

func _initialize_ui() -> void:
	# Hide background area at start, show menu
	toggle_menu(true)

func _initialize_managers() -> void:
	_initialize_score_manager()
	_initialize_game_manager()
	_initialize_inventory_panel()
	_connect_score_signals()
	
	# Connect to the all_pairs_found event
	if EventManager:
		EventManager.connect_to_event("all_pairs_found", Callable(self, "_on_all_pairs_found"))
		print("Connected to all_pairs_found event")

# Initialisiert das Musik-System und lädt alle verfügbaren Musikdateien
func _initialize_music_system() -> void:
	print("Initialisiere Musik-System...")
	
	# Verhindere mehrfache Initialisierung
	if _is_music_initialized:
		print("Musik-System bereits initialisiert!")
		return
	
	# Entferne eventuell vorhandene alte Player
	_cleanup_music_player()
	
	# Erstelle einen neuen Player
	_music_player = AudioStreamPlayer.new()
	
	# Füge den AudioStreamPlayer zur Szene hinzu
	add_child(_music_player)
	
	# Konfiguriere den Player
	_music_player.name = "MainMusicPlayer"
	_music_player.bus = "Master"
	_music_player.volume_db = -10  # Hintergrundmusik etwas leiser
	
	# Füge den Player zur audio_players-Gruppe hinzu
	_music_player.add_to_group("audio_players")
	
	# Verbinde das finished-Signal
	_music_player.finished.connect(_on_music_finished)
	
	# Lade alle verfügbaren Musikdateien
	_load_available_music()
	_is_music_initialized = true
	
	# Starte die Musik nur, wenn wir nicht im Anfangsmenü sind
	await get_tree().create_timer(0.5).timeout
	if not _menu.visible:
		_play_random_music()
	else:
		print("Überspringe Musik-Start, da Menü aktiv ist")

# Lädt alle verfügbaren Musikdateien aus dem assets/music Ordner
func _load_available_music() -> void:
	_available_music.clear()
	
	# Füge die bekannten Musikdateien hinzu
	_available_music.append("res://assets/music/Heartbeat AI Music.mp3")
	_available_music.append("res://assets/music/Schigisaga - AI Music.mp3")
	_available_music.append("res://assets/music/Sneek Up by Cruizer61.mp3")
	_available_music.append("res://assets/music/Suno AI Music Gut.mp3")
	_available_music.append("res://assets/music/Suno AI Music.mp3")
	
	print("Verfügbare Musik: ", _available_music.size(), " Tracks")

# Cleanup old music player instances to prevent duplicates
func _cleanup_music_player() -> void:
	# Suche nach vorhandenen AudioStreamPlayers in der Szene, die unseren Namen haben
	var existing_players = find_children("MainMusicPlayer", "AudioStreamPlayer")
	
	# Lösche alle gefundenen Player
	for player in existing_players:
		print("Entferne vorhandenen AudioStreamPlayer: ", player.name)
		if player.playing:
			player.stop()
		player.queue_free()
	
	# Suche auch nach anderen AudioStreamPlayern im Projekt, die möglicherweise spielen
	var all_audio_players = get_tree().get_nodes_in_group("audio_players")
	for player in all_audio_players:
		if player.playing and player.name != "MenuMusic":
			print("Stoppe anderen AudioStreamPlayer: ", player.name)
			player.stop()

# Spielt eine zufällig ausgewählte Musik ab (außer Gewinn.mp3 und zuletzt gespielte)
func _play_random_music() -> void:
	# Stelle sicher, dass das Musik-System initialisiert ist
	if not _is_music_initialized:
		print("Musik-System nicht initialisiert, initialisiere jetzt...")
		_initialize_music_system()
		return
	
	# Stoppe zuerst die aktuelle Musik, falls sie noch spielt
	if _music_player and _music_player.playing:
		_music_player.stop()
		_music_player.stream = null
		
	if _available_music.is_empty():
		print("Keine Musikdateien verfügbar!")
		return
	
	# Erstelle eine Kopie der verfügbaren Musik für die Auswahl
	var selection_pool = _available_music.duplicate()
	
	# Entferne die Gewinn-Musik, wenn sie vorhanden ist
	var gewinn_index = selection_pool.find(GEWINN_MUSIC_PATH)
	if gewinn_index != -1:
		selection_pool.remove_at(gewinn_index)
	
	# Entferne die zuletzt gespielte Musik, wenn es eine gibt
	if _last_played_music != "":
		var last_index = selection_pool.find(_last_played_music)
		if last_index != -1:
			selection_pool.remove_at(last_index)
	
	# Wenn nach dem Entfernen keine Musik mehr übrig ist
	if selection_pool.is_empty():
		print("Keine weitere Musik zur Auswahl verfügbar, nehme aus allen")
		# Nimm einfach eine beliebige außer Gewinn
		selection_pool = _available_music.duplicate()
		gewinn_index = selection_pool.find(GEWINN_MUSIC_PATH)
		if gewinn_index != -1:
			selection_pool.remove_at(gewinn_index)
	
	# Wähle zufällig eine Musik aus
	var random_index = randi() % selection_pool.size()
	var selected_music = selection_pool[random_index]
	
	# Speichere als zuletzt gespielt
	_last_played_music = selected_music
	
	# Lade und spiele die ausgewählte Musik
	print("Spiele Musik: ", selected_music)
	_music_player.stream = load(selected_music)
	_music_player.play()

# Wird aufgerufen, wenn die aktuelle Musik zu Ende ist
func _on_music_finished() -> void:
	print("Musik beendet, wähle neue aus...")
	_play_random_music()

# Stoppt die aktuell spielende Musik (wird von ShopUI aufgerufen)
func _pause_music() -> void:
	if _music_player and _music_player.playing:
		print("Stoppe Hauptmusik vollständig")
		_music_player.stop()
		_music_player.stream = null  # Stelle sicher, dass kein Stream mehr aktiv ist

func _initialize_score_manager() -> void:
	if not ScoreManager:
		push_error("ScoreManager (Autoload) nicht gefunden!")
		return
	
	# Set up the score labels
	ScoreManager.set_score_labels(
		_ui_total_score_label, 
		_ui_factor_one, 
		_ui_factor_two
	)
	
	# Connect the progress bar - Look for ScoreBar as child of BackgroundArea
	var score_bar = _background_area.get_node_or_null("ScoreBar")
	print("Looking for ScoreBar as child of BackgroundArea")
	print("ScoreBar exists: ", score_bar != null)
	
	if not score_bar:
		push_error("Main: Could not find ScoreBar node")
		print("Children of BackgroundArea:")
		for child in _background_area.get_children():
			print(" - ", child.name, " (Type: ", child.get_class(), ")")
		return
	
	print("ScoreBar found: ", score_bar)
	print("ScoreBar children: ", score_bar.get_children())
	
	# Find the progress bar
	var progress_bar: ProgressBar = null
	
	# First try to find by node path
	progress_bar = score_bar.get_node_or_null("HBoxContainer/ScoreProgressBar")
	
	# If not found, search for any ProgressBar in the scene
	if not progress_bar:
		for child in score_bar.get_children():
			if child is ProgressBar:
				progress_bar = child
				break
			elif child.get_child_count() > 0:
				progress_bar = child.get_node_or_null("ScoreProgressBar")
				if progress_bar:
					break
	
	if not progress_bar:
		push_error("Main: Could not find any ProgressBar in the scene")
		return
	
	print("Found ProgressBar: ", progress_bar)
	
	# Set up the progress bar in ScoreManager
	ScoreManager.set_progress_bar(progress_bar)
	print("Main: Progress bar connected to ScoreManager")
	
	# Force an initial update
	progress_bar.value = ScoreManager._current_score
	
	# Find and update the score label
	var score_label = progress_bar.get_node_or_null("ScoreLabel")
	if not score_label:
		# Try to find any label in the progress bar
		for child in progress_bar.get_children():
			if child is Label:
				score_label = child
				break
	
	if score_label:
		score_label.text = str(ScoreManager._current_score)
		print("Score label updated to: ", score_label.text)
	else:
		print("Warning: Could not find score label in progress bar")

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
		_menu.exit_requested.connect(_on_menu_exit_requested)
		_menu.continue_requested.connect(_on_menu_continue_pressed)

func _connect_score_signals() -> void:
	if ScoreManager:
		if not ScoreManager.score_threshold_reached.is_connected(_on_score_threshold_reached):
			ScoreManager.score_threshold_reached.connect(_on_score_threshold_reached)
	
	# Connect shop ui signals
	if _shop_ui:
		if not _shop_ui.buff_selected.is_connected(_on_shop_buff_selected):
			_shop_ui.buff_selected.connect(_on_shop_buff_selected)
			
		if not _shop_ui.continue_game.is_connected(_on_shop_continue_game):
			_shop_ui.continue_game.connect(_on_shop_continue_game)
			print("ShopUI continue_game signal connected")
			
		if not _shop_ui.exit_game.is_connected(_on_shop_open_menu):
			_shop_ui.exit_game.connect(_on_shop_open_menu)
			print("ShopUI exit_game signal connected")
			
		if not _shop_ui.new_run.is_connected(_on_shop_new_run):
			_shop_ui.new_run.connect(_on_shop_new_run)
			print("ShopUI new_run signal connected")

func _on_score_threshold_reached() -> void:
	if _shop_ui:
		print("Showing shop UI...")
		_shop_ui.visible = true
		_shop_ui.show_shop()
		get_tree().paused = true  # Pause the game while shop is open

func _on_shop_buff_selected(buff_type: String) -> void:
	print("Buff selected: ", buff_type)
	match buff_type:
		"heat_bonus":
			if ScoreManager:
				ScoreManager.set_heat_bonus_enabled(true)
				print("Heat bonus enabled!")
			
			# Aktiviere das Card-Highlighting für den Heat-Buff
			var rhythm_manager = get_node_or_null("Node")
			if rhythm_manager and rhythm_manager.get_script() and rhythm_manager.get_script().get_path().ends_with("CardRhythmManager.gd"):
				rhythm_manager.enable_highlighting = true
				print("Card highlighting enabled for heat bonus!")
		"base_point_increase":
			if ScoreManager:
				ScoreManager.set_base_point_increase_enabled(true)
				print("Base point increase enabled!")
			
			# Aktiviere die Buff-Animationen für den passiven Buff
			var Card = load("res://Globals/Card.gd")
			if Card:
				Card.enable_buff_animations = true
				print("Card buff animations enabled for base point increase!")
				
	# Aktualisiere die Buff-Anzeigen im Inventory-Panel
	if _inventory_panel and _inventory_panel.has_method("update_buff_displays"):
		_inventory_panel.update_buff_displays()
		print("Updated buff displays in inventory panel")
	
	# Spiele eine neue zufällige Musik nach Buff-Auswahl
	_play_random_music()
	
	# Prepare for next run - increment run counter and double target score
	if ScoreManager:
		var current_run = ScoreManager._current_run
		if current_run < 3:  # Nur bis zum dritten Run verdoppeln
			ScoreManager.prepare_next_run()
			print("Prepared for run %d with target score %.0f" % [ScoreManager._current_run, ScoreManager._max_score_target])
		else:
			print("Maximum number of runs reached (3) - not increasing target score further")
	
	# Reset the game for a new run, but preserve the buffs that were just activated
	if GameManager:
		GameManager.reset_game(false) # false = don't reset buffs
		print("Game reset for new run after buff selection (buffs preserved)")
	
	# Resume the game
	if _shop_ui:
		_shop_ui.visible = false
	get_tree().paused = false

func _on_menu_start_pressed() -> void:
	toggle_menu(false)
	
	# Reset game state and score manager (including buffs)
	if GameManager:
		GameManager.reset_game(true) # true = reset all buffs for a completely new game
	
	# Reset score manager to clear all buffs for new run
	if ScoreManager:
		ScoreManager.reset_game(true) # true = reset all buffs for a completely new game
		print("ScoreManager: Reset for new run (including all buffs)")
		
	# Inventar zurücksetzen (Stab Scratches etc.)
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if inventory_manager and inventory_manager.has_method("reset_inventory"):
		inventory_manager.reset_inventory()
		print("Inventory has been reset for new run")
	
	# Aktualisiere auch die Buff-Anzeigen im Inventory Panel
	if _inventory_panel and _inventory_panel.has_method("update_buff_displays"):
		_inventory_panel.update_buff_displays()
		print("Updated buff displays in inventory panel after reset")
	
	# Stelle sicher, dass CardRhythmManager das Highlighting deaktiviert
	var rhythm_manager = get_node_or_null("Node")
	if rhythm_manager and rhythm_manager.get_script() and rhythm_manager.get_script().get_path().ends_with("CardRhythmManager.gd"):
		rhythm_manager.enable_highlighting = false
		print("Card highlighting disabled after reset")
		
	# Auch die Card-Buff-Animationen deaktivieren
	var Card = load("res://Globals/Card.gd")
	if Card:
		Card.enable_buff_animations = false
		print("Card buff animations disabled after reset")
		
	# Start music again if it was stopped
	_play_random_music()

func _on_menu_continue_pressed() -> void:
	toggle_menu(false)

func _on_menu_exit_requested() -> void:
	get_tree().quit()

# Handler for the continue_game signal from ShopUI
func _on_shop_continue_game() -> void:
	print("ShopUI: Continue game signal received")
	# Hide the ShopUI
	if _shop_ui:
		_shop_ui.visible = false
	
	# Play random music like when a buff is selected
	_play_random_music()
	
	# Unpause the game and continue
	get_tree().paused = false

# Handler for the EXIT button signal from ShopUI
func _on_shop_open_menu() -> void:
	print("ShopUI: EXIT button pressed, quitting game")
	# Quit the game
	get_tree().quit()

# Handler for the NEW RUN button signal from ShopUI - resets the game completely
func _on_shop_new_run() -> void:
	print("ShopUI: NEW RUN button pressed, completely resetting game")
	# Hide ShopUI
	if _shop_ui:
		_shop_ui.visible = false
	
	# Stop all audio first
	_pause_music()
	
	# Reset static variables for Card animations
	var Card = load("res://Globals/Card.gd")
	Card.enable_buff_animations = false  # Deaktiviere den Buff-Animationen-Status explizit
	print("Explicitly reset Card.enable_buff_animations to false")
	
	# Reset game state completely
	if GameManager:
		GameManager.reset_game(true)  # true = reset all buffs
	
	# Reset score and buffs
	if ScoreManager:
		# Reset score completely
		ScoreManager.reset_game(true)
	
	# Aktualisiere das Inventar und die Buff-Anzeigen
	if _inventory_panel:
		# Falls möglich, rufe eine reset_inventory-Methode auf
		if _inventory_panel.has_method("reset_inventory"):
			_inventory_panel.reset_inventory()
			print("Reset inventory panel")
		
		# Aktualisiere die Buff-Anzeigen
		if _inventory_panel.has_method("update_buff_displays"):
			_inventory_panel.update_buff_displays()
			print("Updated buff displays in inventory panel after reset")
	
	# Play random music
	_play_random_music()
	
	# Unpause the game
	get_tree().paused = false

# Handler for the all_pairs_found event when all card pairs have been matched
func _on_all_pairs_found() -> void:
	print("All pairs found! Game over - showing ShopUI with final score")
	
	# Wait a short moment before showing the score screen
	await get_tree().create_timer(1.0).timeout
	
	# Show the ShopUI with only EXIT button and score
	if _shop_ui and _shop_ui.has_method("show_game_over_screen"):
		# Get the current score directly from the ScoreManager's internal variable
		var final_score = 0
		if ScoreManager and "_current_score" in ScoreManager:
			# Immer direkt den internen _current_score verwenden, nicht den Label-Text
			final_score = ScoreManager._current_score
			print("Getting final score directly from ScoreManager._current_score: ", final_score)
			
		print("Final score for game over screen: ", final_score)
		_shop_ui.show_game_over_screen(final_score)
		get_tree().paused = true

# Initialize the inventory panel and connect item signals
func _initialize_inventory_panel() -> void:
	if not _inventory_panel:
		push_error("Main: InventoryPanel not found")
		return
	
	print("Initializing inventory panel...")
	
	# Setze GameManager-Referenz
	_inventory_panel.set_game_manager(GameManager)
	
	# Initialisiere Buff-Anzeigen im Inventory-Panel
	if _inventory_panel.has_method("update_buff_displays"):
		_inventory_panel.update_buff_displays()
		print("Updated buff displays in inventory panel")
	
	# Connect the use_item signal from the inventory panel to handle item usage
	# This assumes the InventoryPanel has a signal called item_used that's emitted when an item is used
	if _inventory_panel.has_signal("item_used") and not _inventory_panel.item_used.is_connected(_on_inventory_item_used):
		_inventory_panel.item_used.connect(_on_inventory_item_used)
		print("Connected item_used signal from InventoryPanel")
	else:
		print("Warning: InventoryPanel does not have an item_used signal or it's already connected")

# Handle inventory item usage
func _on_inventory_item_used(item_id: String) -> void:
	print("Item used from inventory: ", item_id)
	
	match item_id:
		"stap_scratch":
			# Use the stap scratch item to reset a random matched pair
			if GameManager and GameManager.reset_random_matched_pair():
				print("Successfully reset a random matched pair using Stap Scratch item")
			else:
				print("Failed to reset a matched pair - no pairs found or error occurred")
		_: 
			print("Unknown item used: ", item_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			print("ESC key pressed!")
			var show_menu = not _menu.visible
			toggle_menu(show_menu)
			if show_menu:
				_menu.set_opened_via_escape(true)
			get_viewport().set_input_as_handled()

func toggle_menu(show_menu: bool) -> void:
	if _menu:
		_menu.visible = show_menu
		
		# Wenn das Menü geöffnet wird, pausiere die Hauptmusik
		# Wenn das Menü geschlossen wird, starte die Hauptmusik wieder
		if show_menu:
			if _music_player and _music_player.playing:
				print("Pausiere Hauptmusik für Menü-Musik")
				_music_player.stop()
		else:
			_menu.set_opened_via_escape(false)
			# Nur wenn wir nicht aus dem Menü heraus in ein Spiel starten,
			# starten wir die Musik wieder (beim Spielstart wird die Musik ohnehin neu gestartet)
			await get_tree().create_timer(0.3).timeout  # Kurze Verzögerung, um sicherzustellen, dass die Menü-Musik stoppt
			if not _background_area.visible:  # Nur wenn wir nicht im Spiel sind
				_play_random_music()
	
	_background_area.visible = not show_menu
