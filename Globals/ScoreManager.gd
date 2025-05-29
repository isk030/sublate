extends Node

# UI Referenzen
@onready var _total_score_label: Label = null
@onready var _factor_one_label: Label = null  # Für Streak-Anzeige
@onready var _factor_two_label: Label = null  # Punkte des letzten Zugs

# Spielzustand
var _current_score: int = 0
var _pairs_found: int = 0
var _current_streak: int = 0
var _streak_multiplier: int = 1
var _last_round_points: int = 0  # Punkte des letzten erfolgreichen Zugs

# Konstanten
const POINTS_PER_PAIR: int = 100
const POINTS_PER_PREVIOUS_PAIR: int = 20
const MAX_STREAK_MULTIPLIER: int = 5  # Maximaler Multiplikator
var _game_won_message_label: Label = null

# Debug Funktionen
func _print_debug_info() -> void:
	print("--- ScoreManager Debug ---")
	print("Score: ", _current_score)
	print("Pairs: ", _pairs_found)
	print("Streak: ", _current_streak, " (x", _streak_multiplier, ")")
	print("UI - Total: ", _total_score_label, " Factor1: ", _factor_one_label)

func set_score_labels(total_label: Label, factor1_label: Label, factor2_label: Label) -> void:
	_total_score_label = total_label
	_factor_one_label = factor1_label
	_factor_two_label = factor2_label
	
	# Initiale UI-Aktualisierung
	_update_streak_display()
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	
	print("ScoreManager: UI-Labels gesetzt")

func _ready() -> void:
	print("ScoreManager (Autoload) bereit.")
	EventManager.connect_to_event("pair_found", Callable(self, &"_on_pair_found"))
	EventManager.connect_to_event("mismatch_attempt", Callable(self, &"_on_mismatch_attempt"))
	EventManager.connect_to_event("all_pairs_found", Callable(self, &"_on_all_pairs_found"))
	# Optional: If you have a label in your scene for game won messages
	# Search for it. Make sure it's part of the scene tree where ScoreManager can find it.
	# This example assumes it might be a child of the main scene's root, or a sibling of ScoreManager's UI parent.
	# Adjust path as necessary, or set it up via set_game_won_message_label_ref from Main.gd
	# _game_won_message_label = get_tree().root.find_child("GameWonMessageLabel", true, false) 
	# if _game_won_message_label:
	# 	_game_won_message_label.visible = false # Hide initially

func reset_score_panel() -> void:
	_current_score = 0
	_pairs_found = 0
	_current_streak = 0
	_streak_multiplier = 1
	_last_round_points = 0
	
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	_update_streak_display()
	
	print("ScoreManager: Score-Panel zurückgesetzt")
	if _game_won_message_label:
		_game_won_message_label.text = ""
		_game_won_message_label.visible = false
	# Wir geben nur eine Debug-Nachricht aus, wenn das Haupt-Score-Label fehlt
	if not _total_score_label:
		print_debug("ScoreManager: _total_score_label ist nicht gesetzt. Das ist normal beim ersten Laden.")

func _calculate_pair_found_passive_buff() -> int:
	# Returns additional points based on previously found pairs, multipliziert mit Streak-Multiplikator
	return _pairs_found * POINTS_PER_PREVIOUS_PAIR * _streak_multiplier

func _update_streak_display() -> void:
	# Zeige den aktuellen Streak an (mindestens 1)
	var display_streak = max(1, _current_streak)
	
	# Aktualisiere das Streak-Label
	if is_instance_valid(_factor_one_label):
		_factor_one_label.text = str(display_streak)
	
	# Aktualisiere das Punkte-Label mit den Punkten des letzten Zugs
	if is_instance_valid(_factor_two_label):
		_factor_two_label.text = str(_last_round_points)

func _on_pair_found(_data: Dictionary) -> void:
	# Streak erhöhen und Multiplikator berechnen
	_current_streak += 1
	_streak_multiplier = min(_current_streak, MAX_STREAK_MULTIPLIER)
	
	# Punkte berechnen mit Streak-Multiplikator
	var base_points = POINTS_PER_PAIR
	var passive_buff = _pairs_found * POINTS_PER_PREVIOUS_PAIR
	
	# Gesamtpunkte für diese Runde berechnen
	if _current_streak > 1:  # Multiplikator erst ab dem 2. Treffer
		_last_round_points = (base_points + passive_buff) * _streak_multiplier
	else:
		_last_round_points = base_points + passive_buff
	
	# Score und Zähler aktualisieren
	_current_score += _last_round_points
	_pairs_found += 1
	
	# UI aktualisieren
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	_update_streak_display()
	
	# Debug-Ausgabe
	print("ScoreManager: Pair found! ", 
		"Streak: %dx, " % _current_streak,
		"Multiplier: %dx, " % _streak_multiplier,
		"Base: %d + " % base_points, 
		"Passive Buff: %d = " % passive_buff, 
		"Total: %d" % _last_round_points, 
		" (Score: %d, Pairs: %d)" % [_current_score, _pairs_found])

func _on_mismatch_attempt() -> void:
	# Streak zurücksetzen bei Fehlversuch
	if _current_streak > 0:
		print("ScoreManager: Streak broken! Was at ", _current_streak, "x")
	_current_streak = 0
	_streak_multiplier = 1
	_last_round_points = 0  # Keine Punkte bei Fehlversuch
	_update_streak_display()  # Aktualisiere die Anzeige

func _on_all_pairs_found() -> void:
	# Update score for all pairs found
	if _game_won_message_label:
		_game_won_message_label.visible = true
