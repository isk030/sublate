extends Node

# Importe
const BasePointsModifier = preload("res://Scoring/Modifiers/BasePointsModifier.gd")
const StreakModifier = preload("res://Scoring/Modifiers/StreakModifier.gd")
const HeatBonusModifier = preload("res://Scoring/Modifiers/HeatBonusModifier.gd")
const ModifierManager = preload("res://Scoring/ModifierManager.gd")

# Modifier-Instanzen
var _modifier_manager = null
var _base_points_modifier = null
var _streak_modifier = null
var _heat_bonus_modifier = null

# UI Referenzen
@onready var _total_score_label: Label = null
@onready var _factor_one_label: Label = null  # Für Streak-Anzeige
@onready var _factor_two_label: Label = null  # Punkte des letzten Zugs
var _game_won_message_label: Label = null

# Spielzustand
var _current_score: int = 0
var _pairs_found: int = 0
var _current_streak: int = 0
var _streak_multiplier: int = 1
var _last_round_points: int = 0  # Punkte des letzten erfolgreichen Zugs

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
	_update_ui()
	print("ScoreManager: UI-Labels gesetzt")

func _init() -> void:
	# Modifier initialisieren
	_modifier_manager = ModifierManager.new()
	
	# Modifier erstellen
	_base_points_modifier = BasePointsModifier.new()
	_streak_modifier = StreakModifier.new()
	_heat_bonus_modifier = HeatBonusModifier.new()
	
	# Modifier in der richtigen Reihenfolge hinzufügen
	_modifier_manager.add_modifier(_base_points_modifier)
	_modifier_manager.add_modifier(_streak_modifier)
	_modifier_manager.add_modifier(_heat_bonus_modifier)
	
	print("ScoreManager: Modifier initialisiert - ", _modifier_manager.get_modifier_list())

func _ready() -> void:
	print("ScoreManager (Autoload) bereit.")
	EventManager.connect_to_event("pair_found", Callable(self, &"_on_pair_found"))
	EventManager.connect_to_event("mismatch_attempt", Callable(self, &"_on_mismatch_attempt"))
	EventManager.connect_to_event("all_pairs_found", Callable(self, &"_on_all_pairs_found"))

func reset_score_panel() -> void:
	# Setze nur die UI-Elemente zurück, nicht den Score
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	if _factor_one_label:
		_factor_one_label.text = str(max(1, _current_streak))
	if _factor_two_label:
		_factor_two_label.text = str(_last_round_points)
	
	if _game_won_message_label:
		_game_won_message_label.text = ""
		_game_won_message_label.visible = false
	
	print("ScoreManager: Score-Panel UI zurückgesetzt")

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

func _update_ui() -> void:
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	if _factor_one_label:
		_factor_one_label.text = str(max(1, _current_streak))
	if _factor_two_label:
		# Calculate base points (100 for first pair, +20 for each previous pair)
		var base_points = 100 + (max(0, _pairs_found - 1) * 20)
		# Add heat bonus if both cards were flipped in rhythm
		var heat_bonus = 100 if _current_streak > 0 and _last_round_points > (base_points * max(1, _current_streak)) else 0
		# Total flat points (base + heat bonus)
		var total_flat_points = base_points + heat_bonus
		_factor_two_label.text = str(total_flat_points)

func _on_pair_found(data: Dictionary) -> void:
	print("\n--- ScoreManager: pair_found event received ---")
	print("Data received: ", data)
	
	# Streak aktualisieren
	_current_streak = 1 if _current_streak == 0 else _current_streak + 1
	_streak_multiplier = min(_current_streak, 10)  # MAX_STREAK_MULTIPLIER
	
	# Paarzähler erhöhen
	_pairs_found = data.get("pairs_found", _pairs_found + 1)
	
	# Basis-Punkte berechnen (100 + 20 pro bereits gefundenes Paar)
	var base_points = 100 + (max(0, _pairs_found - 1) * 20)
	
	# Heat Bonus prüfen (100 Punkte wenn im Rhythmus)
	var heat_bonus = 100 if data.get("heat_bonus", 0) > 0 else 0
	
	# Gesamt-Punkte für diese Runde (ohne Multiplikator)
	var round_points = base_points + heat_bonus
	
	# Punkte mit Streak-Multiplikator berechnen
	_last_round_points = round_points * max(1, _current_streak)
	_current_score += _last_round_points
	
	# Debug-Ausgabe
	print("Paar ", _pairs_found, ":")
	print("  Basis: ", base_points)
	if heat_bonus > 0:
		print("  + Heat Bonus: ", heat_bonus)
	print("  * Streak: ", max(1, _current_streak), "x")
	print("  = Rundenpunkte: ", _last_round_points)
	print("  Gesamtpunktzahl: ", _current_score)
	print("  (Aktueller Streak: ", _current_streak, ")")
	
	# UI aktualisieren
	_update_ui()

func _on_mismatch_attempt() -> void:
	# Streak zurücksetzen bei Fehlversuch
	if _current_streak > 0:
		print("ScoreManager: Streak broken! War bei ", _current_streak, "x")
		_current_streak = 0
		_streak_multiplier = 1
		_last_round_points = 0  # Keine Punkte für diesen Zug
		_update_ui()
		
		# Event auslösen, um die UI zu aktualisieren
		EventManager.emit_signal("score_updated", {
			"current_score": _current_score,
			"points_this_round": 0,
			"streak": 0,
			"descriptions": ["Kein Paar gefunden"]
		})

func _on_all_pairs_found() -> void:
	# Update score for all pairs found
	if _game_won_message_label:
		_game_won_message_label.text = "Gewonnen! Score: " + str(_current_score)
		_game_won_message_label.visible = true
	print("ScoreManager: Alle Paare gefunden! Endscore: ", _current_score)

# Wird von Main.gd aufgerufen, um die Referenz auf das GameWonMessageLabel zu setzen
func set_game_won_message_label(label_ref: Label) -> void:
	_game_won_message_label = label_ref
	if _game_won_message_label:
		_game_won_message_label.visible = false
