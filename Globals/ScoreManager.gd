extends Node

# Importe
const BASE_POINTS_MODIFIER_SCRIPT = preload("res://Scoring/Modifiers/BasePointsModifier.gd")
const STREAK_MODIFIER_SCRIPT = preload("res://Scoring/Modifiers/StreakModifier.gd")
const HEAT_BONUS_MODIFIER_SCRIPT = preload("res://Scoring/Modifiers/HeatBonusModifier.gd")
const MODIFIER_MANAGER_SCRIPT = preload("res://Scoring/ModifierManager.gd")

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

# Fortschrittsanzeige
@onready var _score_progress_bar: ProgressBar = null
var _max_score_target: float = 10000.0  # Standardwert für max. Punktzahl

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

func set_progress_bar(progress_bar: ProgressBar) -> void:
	_score_progress_bar = progress_bar
	if _score_progress_bar:
		print("ScoreManager: Fortschrittsleiste verbunden - initialisiere mit _current_score: ", _current_score)
		# Maximalen Wert setzen
		_score_progress_bar.max_value = _max_score_target
		
		# Forciere die Wertzuweisung und Update der UI
		_score_progress_bar.value = _current_score
		_score_progress_bar.value = _current_score # Doppelte Zuweisung um UI-Update zu erzwingen
		
		# Score Label in der Fortschrittsleiste finden und aktualisieren
		var score_label = _score_progress_bar.get_node_or_null("%ScoreLabel")
		if score_label:
			score_label.text = str(_current_score)
			print("ScoreManager: Score Label in Fortschrittsleiste auf ", _current_score, " gesetzt")
		else:
			for child in _score_progress_bar.get_children():
				print("Kind der Fortschrittsleiste: ", child.get_name(), " - Klasse: ", child.get_class())
				if child is Label:
					child.text = str(_current_score)
					print("Fallback: Label in Fortschrittsleiste gefunden und aktualisiert")
		
		print("ScoreManager: Progress bar connected successfully")
	else:
		push_error("ScoreManager: Invalid progress bar reference")

func _init() -> void:
	# Modifier initialisieren
	_modifier_manager = MODIFIER_MANAGER_SCRIPT.new()
	
	# Modifier erstellen
	_base_points_modifier = BASE_POINTS_MODIFIER_SCRIPT.new()
	_streak_modifier = STREAK_MODIFIER_SCRIPT.new()
	_heat_bonus_modifier = HEAT_BONUS_MODIFIER_SCRIPT.new()
	
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

func setup_ui_references(panel: Control) -> void:
	print("ScoreManager: Connecting UI references...")
	
	# Labels für Punktanzeige finden
	_total_score_label = panel.get_node_or_null("VBoxContainer/TotalScoreContainer/ScoreValue")
	_factor_one_label = panel.get_node_or_null("VBoxContainer/FactorsContainer/StreakFactor")
	_factor_two_label = panel.get_node_or_null("VBoxContainer/FactorsContainer/LastRoundFactor")
	_game_won_message_label = panel.get_node_or_null("VBoxContainer/GameWonContainer/GameWonLabel")
	
	# Fortschrittsanzeige finden (in der BackgroundArea/ScoreBar)
	var background_area = panel.get_parent().get_node_or_null("../BackgroundArea")
	if background_area:
		var score_bar = background_area.get_node_or_null("ScoreBar")
		if score_bar:
			_score_progress_bar = score_bar.get_node_or_null("%ScoreProgressBar")
			if _score_progress_bar:
				# Standardwerte setzen
				_score_progress_bar.max_value = _max_score_target
				_score_progress_bar.value = _current_score
				print("ScoreManager: Progress bar connected successfully with value: ", _current_score)
			else:
				push_error("ScoreManager: Failed to find %ScoreProgressBar in ScoreBar")
		else:
			push_error("ScoreManager: Failed to find ScoreBar in BackgroundArea")
	else:
		push_error("ScoreManager: Failed to find BackgroundArea")
	
	if _total_score_label and _factor_one_label and _factor_two_label:
		print("ScoreManager: UI labels connected successfully")
	else:
		push_error("ScoreManager: Failed to connect UI labels")

func reset_score_panel() -> void:
	# Setze nur die UI-Elemente zurück, nicht den Score
	if _total_score_label:
		_total_score_label.text = "0"  # Gesamtpunktzahl auf 0 setzen
	if _factor_one_label:
		_factor_one_label.text = "0"  # Streak auf 0 setzen
	if _factor_two_label:
		_factor_two_label.text = "0"  # Basis-Punkte auf 0 setzen
	if _game_won_message_label:
		_game_won_message_label.visible = false
	
	print("ScoreManager: Score-Panel UI zurückgesetzt")

func reset_score_progress_bar() -> void:
	# Fortschrittsanzeige vollständig zurücksetzen
	if _score_progress_bar:
		_score_progress_bar.value = 0
		var score_label = _score_progress_bar.get_node_or_null("%ScoreLabel")
		if score_label:
			score_label.text = "0"

# Fügt Punkte hinzu
func add_score(score: int) -> void:
	print("\n==== add_score CALLED ====")
	print("Adding score: ", score, " to current score: ", _current_score)
	_current_score += score
	print("New total score: ", _current_score)
	_update_ui()
	print("==== add_score DONE ====")

# Diese Funktion wird aufgerufen, wenn ein neues Spiel beginnt
func reset_game() -> void:
	# Alle Punktestände und Zustände zurücksetzen
	print("\n==== reset_game CALLED ====")
	_current_score = 0
	_pairs_found = 0
	_current_streak = 0
	_streak_multiplier = 1
	_last_round_points = 0
	
	# UI aktualisieren
	reset_score_panel()
	print("==== reset_game DONE ====")
	reset_score_progress_bar()
		
	print("ScoreManager: Spiel zurückgesetzt - Score: 0")

func _update_ui() -> void:
	print("\n==== _update_ui CALLED ====")
	print("Current score: ", _current_score)
	print("Progress bar exists: ", _score_progress_bar != null)
	
	if _total_score_label:
		_total_score_label.text = str(_current_score)
		print("Total score label updated to: ", _current_score)
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
		
	# Aktualisiere die Fortschrittsanzeige
	if _score_progress_bar:
		print("Updating progress bar from ", _score_progress_bar.value, " to ", _current_score)
		_score_progress_bar.value = _current_score
		
		# Passe das Label in der Fortschrittsanzeige an
		var score_label = _score_progress_bar.get_node_or_null("%ScoreLabel")
		if score_label:
			score_label.text = str(_current_score)
			print("ScoreLabel in progress bar updated to: ", _current_score)
		else:
			push_error("ScoreLabel not found in progress bar")
	else:
		push_error("NO PROGRESS BAR FOUND to update!")
		
	print("==== _update_ui DONE ====")

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
	print("ScoreManager: Mismatch - Streak wird zurückgesetzt")
	_current_streak = 0
	_streak_multiplier = 1
	_last_round_points = 0  # Keine Punkte für diesen Zug
	
	# UI aktualisieren
	if _factor_two_label:
		_factor_two_label.text = "0"  # Direkt 0 Punkte anzeigen
	
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
