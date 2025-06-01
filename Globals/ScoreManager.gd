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
const MAX_STREAK_MULTIPLIER: int = 10  # Maximaler Multiplikator (für längere Streaks)
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
	# Setze nur die UI-Elemente zurück, nicht den Score
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	_update_streak_display()
	
	if _game_won_message_label:
		_game_won_message_label.text = ""
		_game_won_message_label.visible = false
	
	print("ScoreManager: Score-Panel UI zurückgesetzt")
	# Debug-Nachricht, wenn das Haupt-Score-Label fehlt
	if not _total_score_label:
		print_debug("ScoreManager: _total_score_label ist nicht gesetzt. Das ist normal beim ersten Laden.")

# Diese Funktion wird aufgerufen, wenn ein neues Spiel beginnt
func reset_game() -> void:
	_current_score = 0
	_pairs_found = 0
	_current_streak = 0
	_streak_multiplier = 1
	_last_round_points = 0
	
	# UI aktualisieren
	reset_score_panel()
	print("ScoreManager: Spiel zurückgesetzt - Score: 0")

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

func _on_pair_found(data: Dictionary) -> void:
	print("\n--- ScoreManager: pair_found event received ---")
	print("Data received: ", data)
	
	# Streak um 1 erhöhen, wenn das letzte Paar erfolgreich war
	# Ansonsten beginnt ein neuer Streak bei 1
	if _current_streak > 0:
		_current_streak += 1
	else:
		_current_streak = 1
	
	_streak_multiplier = min(_current_streak, MAX_STREAK_MULTIPLIER)
	
	# Anzahl der gefundenen Paare erhöhen
	_pairs_found = data.get("pairs_found", _pairs_found + 1)
	print("Current pairs found: ", _pairs_found)
	
	# Basispunkte für dieses Paar (100 für das erste Paar, dann +20 für jedes weitere)
	var base_points = POINTS_PER_PAIR + ((_pairs_found - 1) * POINTS_PER_PREVIOUS_PAIR)
	print("Base points: ", base_points)
	
	# Heat Bonus (100 Punkte, wenn beide Karten im Takt gefunden wurden)
	var heat_bonus = data.get("heat_bonus", 0)
	print("Heat bonus: ", heat_bonus)
	
	# Gesamtpunkte für diesen Zug (Basispunkte + Heat Bonus)
	var points_this_round = base_points + heat_bonus
	
	# Punkte mit Streak-Multiplikator berechnen
	var points_with_multiplier = points_this_round * _streak_multiplier
	
	# Punkte zum Gesamtscore addieren
	_current_score += points_with_multiplier
	_last_round_points = points_this_round  # OHNE Multiplikator für die Anzeige
	
	# Debug-Ausgabe
	print("Paar ", _pairs_found, ": ")
	print("  Base: ", base_points)
	if heat_bonus > 0:
		print("  + Heat Bonus: ", heat_bonus)
	print("  Total: ", points_this_round, " x ", _streak_multiplier, " = ", points_with_multiplier)
	print("  (Streak: ", _current_streak, "x, Gesamt: ", _current_score, ")")
	
	# UI aktualisieren
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	_update_streak_display()
	
	# Debug-Ausgabe
	print("ScoreManager: Pair found! ", 
		"Streak: %dx, " % _current_streak,
		"Multiplier: %dx, " % _streak_multiplier,
		"Base: %d, " % base_points, 
		("+%d Heat Bonus, " % heat_bonus if heat_bonus > 0 else ""),
		"Total: %d" % _last_round_points, 
		"(Score: %d, Pairs: %d)" % [_current_score, _pairs_found])

func _on_mismatch_attempt() -> void:
	# Streak zurücksetzen bei Fehlversuch
	if _current_streak > 0:
		print("ScoreManager: Streak broken! War bei ", _current_streak, "x")
		_current_streak = 0
		_streak_multiplier = 1
		_last_round_points = 0  # Keine Punkte bei Fehlversuch
		# Die Anzahl der gefundenen Paare (_pairs_found) bleibt unverändert,
		# damit die Gesamtpunktzahl erhalten bleibt.
		# Der nächste Treffer beginnt wieder mit Streak 1
		_update_streak_display()  # Aktualisiere die Anzeige

func _on_all_pairs_found() -> void:
	# Update score for all pairs found
	if _game_won_message_label:
		_game_won_message_label.visible = true
