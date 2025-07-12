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
var _max_score_target: float = 2800.0  # Maximale Punktzahl für die Fortschrittsleiste
var _base_score_target: float = 2800.0  # Basis-Punktzahl (wird pro Run verdoppelt)
var _current_run: int = 1  # Aktueller Spiel-Run (1, 2, 3, ...)

# Spielzustand
var _current_score: int = 0
var _pairs_found: int = 0
var _current_streak: int = 0
var _streak_multiplier: int = 1
var _last_round_points: int = 0  # Punkte des letzten erfolgreichen Zugs
var _last_pair_in_rhythm: bool = false  # Merkt, ob letztes Paar im Rhythmus war

# Signals
signal score_threshold_reached()
signal run_completed(run_number: int, target_reached: bool)

# Bonus-Einstellungen (können über ShopUI aktiviert werden)
var _enable_heat_bonus: bool = false
var _enable_base_point_increase: bool = false
var _threshold_reached: bool = false  # To track if we've already shown the shop

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
	print("\n==== set_progress_bar CALLED ====")
	print("Progress bar reference received:", progress_bar)
	
	if not progress_bar:
		push_error("ScoreManager: No progress bar provided to set_progress_bar")
		return
		
	_score_progress_bar = progress_bar
	print("ScoreManager: Progress bar connected - Initializing with score:", _current_score, "/", _max_score_target)
	
	# Set max value
	_score_progress_bar.max_value = _max_score_target
	print("Set max value to:", _score_progress_bar.max_value)
	
	# Force value update
	_score_progress_bar.value = _current_score
	print("Set initial value to:", _score_progress_bar.value)
	
	# Try to find and update the score label
	# First try to find the ScoreLabel directly as a child
	var score_label = _score_progress_bar.get_node_or_null("ScoreLabel")
	if not score_label:
		print("ScoreLabel not found as direct child, searching for any Label...")
		for child in _score_progress_bar.get_children():
			if child is Label:
				score_label = child
				print("Found label:", child.name, " of type:", child.get_class())
				break
	
	if score_label:
		score_label.text = str(_current_score)
		print("Updated score label to:", score_label.text)
	else:
		print("Warning: Could not find any label in progress bar to update")
	
	print("==== set_progress_bar DONE ====")

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
	
	# Fortschrittsanzeige finden (in der ScoreBar)
	var score_bar = panel.get_parent().get_node_or_null("../ScoreBar")
	if score_bar:
		_score_progress_bar = score_bar.get_node_or_null("%ScoreProgressBar")
		if _score_progress_bar:
			# Standardwerte setzen
			_score_progress_bar.max_value = _max_score_target
			_score_progress_bar.value = 0
			print("ScoreManager: Progress bar connected successfully")
		else:
			push_error("ScoreManager: Failed to find progress bar")
	
	if _total_score_label and _factor_one_label and _factor_two_label:
		print("ScoreManager: UI labels connected successfully")
	else:
		push_error("ScoreManager: Failed to connect UI labels")

func reset_score_panel() -> void:
	# Setze nur die UI-Elemente zurück, nicht den Score
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	if _factor_one_label:
		_factor_one_label.text = "1"
	if _factor_two_label:
		_factor_two_label.text = "0"  # Changed from "100" to "0"
	if _game_won_message_label:
		_game_won_message_label.visible = false
	# Fortschrittsanzeige zurücksetzen
	if _score_progress_bar:
		_score_progress_bar.value = _current_score
		# Label aktualisieren
		var score_label = _score_progress_bar.get_node_or_null("%ScoreLabel")
		if score_label:
			score_label.text = str(_current_score)
	
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
	print("Progress bar exists: ", _score_progress_bar != null)
	if _score_progress_bar:
		print("Progress bar max value: ", _score_progress_bar.max_value)
		print("Progress bar current value: ", _score_progress_bar.value)
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
	_threshold_reached = false
	
	# UI zurücksetzen
	if _factor_two_label:
		_factor_two_label.text = "0"  # Auf 0 zurücksetzen
	reset_score_panel()
	print("==== reset_game DONE ====")
	reset_score_progress_bar()
	
	print("ScoreManager: Spiel zurückgesetzt - Run: %d - Target Score: %.0f" % [_current_run, _max_score_target])

# Erhöht den Run-Zähler und verdoppelt die Zielpunktzahl
func increment_run() -> void:
	_current_run += 1
	_max_score_target = _base_score_target * pow(2, _current_run - 1)
	print("ScoreManager: Run erhöht auf %d, neue Zielpunktzahl: %.0f" % [_current_run, _max_score_target])

# Setzt das Spiel für einen neuen Run zurück
func prepare_next_run() -> void:
	# Punktestände zurücksetzen, aber Run-Zähler und Zielpunkte erhöhen
	increment_run()
	_current_score = 0
	_pairs_found = 0
	_current_streak = 0
	_streak_multiplier = 1
	_last_round_points = 0
	_threshold_reached = false
	
	# UI zurücksetzen
	reset_score_panel()
	reset_score_progress_bar()
	print("ScoreManager: Nächster Run vorbereitet - Run: %d - Zielpunktzahl: %.0f" % [_current_run, _max_score_target])

func _update_ui() -> void:
	print("\n==== _update_ui CALLED ====")
	print("Current score: ", _current_score)
	print("Progress bar reference: ", _score_progress_bar)
	
	# Check if score reached the threshold and we haven't shown the shop yet
	if _score_progress_bar and not _threshold_reached:
		if _current_score >= _max_score_target:
			_threshold_reached = true
			print("Score threshold reached: ", _current_score, " >= ", _max_score_target)
			# Emit signal with the current run number
			emit_signal("score_threshold_reached")
			emit_signal("run_completed", _current_run, true)
		print("Score threshold reached! Showing shop UI...")
	
	if _score_progress_bar:
		print("Before update - Progress bar value: ", _score_progress_bar.value, " / ", _score_progress_bar.max_value)
	
	# Update total score label
	if _total_score_label:
		_total_score_label.text = str(_current_score)
	
	# Update factor one (streak multiplier) - always show at least 1
	if _factor_one_label:
		_factor_one_label.text = str(max(1, _current_streak))
	
	# Update factor two (base points + heat bonus)
	if _factor_two_label:
		# If we're in a mismatch state (current_streak == 0), show 0
		if _current_streak == 0:
			_factor_two_label.text = "0"
		else:
			# Calculate base points (100 for first pair, more if enabled)
			var base_points = 100
			if _enable_base_point_increase and _pairs_found > 1:
				base_points += (_pairs_found - 1) * 20
			# Add heat bonus if enabled and last pair was in rhythm
			if _enable_heat_bonus and _last_pair_in_rhythm:
				base_points += 100
			# Update factor two label
			_factor_two_label.text = str(base_points)
	
	# Update progress bar if available
	if _score_progress_bar:
		# Set max value if not already set
		if _score_progress_bar.max_value != _max_score_target:
			_score_progress_bar.max_value = _max_score_target
		# Update current value
		_score_progress_bar.value = min(_current_score, _max_score_target)
		print("Score progress: ", _score_progress_bar.value, " / ", _score_progress_bar.max_value)
		
		# Update score label in progress bar if it exists
		# First try with %ScoreLabel (if it's a unique name)
		var score_label = _score_progress_bar.get_node_or_null("%ScoreLabel")
		# If not found, try direct child named "ScoreLabel"
		if not score_label:
			score_label = _score_progress_bar.get_node_or_null("ScoreLabel")
		
		if score_label:
			score_label.text = str(_current_score)
		
		# Fallback: Try to find any Label in the progress bar
		if not score_label:
			for child in _score_progress_bar.get_children():
				if child is Label:
					score_label = child
					break
		
		if score_label:
			score_label.text = str(_current_score)
			print("ScoreLabel in progress bar updated to: ", _current_score)
		else:
			print("Warning: Could not find ScoreLabel in progress bar")
	else:
		print("Warning: No progress bar found to update!")
	
	print("==== _update_ui DONE ====")

func _on_pair_found(data: Dictionary) -> void:
	print("\n--- ScoreManager: pair_found event received ---")
	print("Data received: ", data)
	
	# Check if in rhythm (on beat) - do this before updating pairs_found
	var was_in_rhythm = data.get("heat_bonus", 0) > 0
	
	# Update pairs found counter
	_last_pair_in_rhythm = was_in_rhythm  # merken für UI
	_pairs_found = data.get("pairs_found", _pairs_found + 1)
	
	# Increase streak for every match
	_current_streak = 1 if _current_streak == 0 else _current_streak + 1
	
	# Apply base points (100 for first pair, 100 + 20*(n-1) for subsequent pairs if enabled)
	var base_points = 100
	if _enable_base_point_increase and _pairs_found > 1:
		base_points += (_pairs_found - 1) * 20

	# Apply heat bonus if enabled and in rhythm
	var rhythm_bonus = 100 if (_enable_heat_bonus and was_in_rhythm) else 0

	# Calculate points with streak multiplier
	if _pairs_found == 1:
		# First pair: 100 points, plus 100 if in rhythm and heat bonus is enabled
		_last_round_points = base_points + rhythm_bonus
	else:
		# Subsequent pairs: base points + rhythm bonus, multiplied by streak
		_last_round_points = max(1, _current_streak) * (base_points + rhythm_bonus)

	# Update factor two label to show base points + rhythm bonus (without streak multiplier)
	if _factor_two_label:
		_factor_two_label.text = str(base_points + rhythm_bonus)
	
	# Add to total score
	_current_score += _last_round_points
	
	# Debug output
	print("Pair ", _pairs_found, ":")
	print("  Points: ", _last_round_points)
	print("  Total score: ", _current_score)
	print("  In rhythm: ", "Yes" if was_in_rhythm else "No")
	print("  Current streak: ", _current_streak)
	
	# Update UI to reflect the changes
	_update_ui()



func _on_mismatch_attempt() -> void:
	# Reset streak and multiplier on mismatch
	print("ScoreManager: Mismatch - Resetting streak")
	_current_streak = 0
	_streak_multiplier = 1
	_last_round_points = 0  # No points for this attempt
	_last_pair_in_rhythm = false
	
	# Update UI immediately to show 0 points
	if _factor_one_label:
		_factor_one_label.text = "1"  # Multiplier stays at least 1
	if _factor_two_label:
		_factor_two_label.text = "0"  # Show 0 immediately on mismatch
		print("Mismatch - Factor Two set to 0")
	
	# Update the UI
	_update_ui()
	
	# Emit score update event
	EventManager.emit_signal("score_updated", {
		"current_score": _current_score,
		"points_this_round": 0,
		"streak": 0,
		"descriptions": ["No match found"]
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

# Bonus activation methods for ShopUI
func set_heat_bonus_enabled(enabled: bool) -> void:
	_enable_heat_bonus = enabled
	print("Heat bonus ", "enabled" if enabled else "disabled")

func set_base_point_increase_enabled(enabled: bool) -> void:
	_enable_base_point_increase = enabled
	print("Base point increase ", "enabled" if enabled else "disabled")

# Getter-Methoden für den Buff-Status
func is_heat_bonus_enabled() -> bool:
	return _enable_heat_bonus

func is_base_point_increase_enabled() -> bool:
	return _enable_base_point_increase
