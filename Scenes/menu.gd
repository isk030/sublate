class_name Menu
extends Control

signal game_start_requested
signal exit_requested
signal continue_requested

@onready var _continue_button: Button = %Continue
@onready var _start_button: Button = %StartButton
@onready var _exit_button: Button = %ExitButton
# Error label is optional
@onready var _error_label: Label = %ErrorLabel if has_node("%ErrorLabel") else null
# Hintergrundmusik für das Hauptmenü
@onready var _menu_music: AudioStreamPlayer = %MenuMusic if has_node("%MenuMusic") else null

var _opened_via_escape := false

func _ready() -> void:
	_validate_nodes()
	_connect_signals()
	_initialize_ui()
	_start_menu_music()

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
	else:
		print("Hinweis: Kein ErrorLabel in der Szene gefunden")
	if _continue_button:
		_continue_button.visible = false

func _on_start_pressed() -> void:
	_stop_menu_music()
	game_start_requested.emit()

func set_opened_via_escape(value: bool) -> void:
	_opened_via_escape = value
	if _continue_button:
		_continue_button.visible = value

func _on_continue_pressed() -> void:
	_stop_menu_music()
	continue_requested.emit()

func _on_exit_pressed() -> void:
	exit_requested.emit()
	_stop_menu_music()
	get_tree().quit()

func _show_error(message: String) -> void:
	push_error(message)
	if _error_label:
		_error_label.text = "Fehler: " + message
		_error_label.visible = true

# Startet die Hintergrundmusik für das Hauptmenü
func _start_menu_music() -> void:
	# Stoppe zuerst alle anderen Audio-Player, um Überlappung zu vermeiden
	_stop_all_other_music()
	
	# Kurze Verzögerung, damit andere Player vollständig gestoppt werden
	await get_tree().create_timer(0.1).timeout
	
	if _menu_music and not _menu_music.playing:
		print("Starte Menü-Musik: Gewinn.mp3")
		_menu_music.play()
		if not _menu_music.playing:
			push_error("Fehler beim Abspielen der Menü-Musik")

# Stoppt alle anderen Musik-Player außer dem Menü-Player
func _stop_all_other_music() -> void:
	# Finde alle AudioStreamPlayer in der Szene
	var audio_players = get_tree().get_nodes_in_group("audio_players")
	print("Gefundene Audio-Player: ", audio_players.size())
	
	# Stoppe jeden Player, der nicht der Menü-Player ist
	for player in audio_players:
		if player != _menu_music and player.playing:
			print("Stoppe anderen Audio-Player: ", player.name)
			player.stop()

# Stoppt die Hintergrundmusik
func _stop_menu_music() -> void:
	if _menu_music and _menu_music.playing:
		_menu_music.stop()
