extends RefCounted
class_name ScoringService

# Import required classes
const SCORE_MODIFIER_CLASS = preload("res://Scoring/ScoreModifier.gd")
const BASE_SCORE_MODIFIER_CLASS = preload("res://Scoring/Modifiers/BaseScoreModifier.gd")
const HEAT_BONUS_MODIFIER_CLASS = preload("res://Scoring/Modifiers/HeatBonusModifier.gd")
const STREAK_MULTIPLIER_MODIFIER_CLASS = preload("res://Scoring/Modifiers/StreakMultiplierModifier.gd")

# Type hints for the modifier instances
var _base_modifier: Object  # Will be instance of BaseScoreModifier
var _heat_bonus_modifier: Object  # Will be instance of HeatBonusModifier
var _streak_modifier: Object  # Will be instance of StreakMultiplierModifier
var _score_chain: Object = null  # Will be instance of ScoreModifier or ChainModifier

# Konstanten für die Standardwerte
const DEFAULT_BASE_POINTS = 100
const DEFAULT_HEAT_BONUS = 50
const DEFAULT_MAX_STREAK_MULTIPLIER = 2.0

# Modifikatoren werden jetzt oben deklariert

## Initialisiert den ScoringService mit Standardwerten
func _init() -> void:
	# Initialize all modifiers
	_initialize_modifiers()
	
	# Create the modifier chain
	_create_modifier_chain()

## Initializes all modifier instances
func _initialize_modifiers() -> void:
	_base_modifier = BASE_SCORE_MODIFIER_CLASS.new(DEFAULT_BASE_POINTS)
	_heat_bonus_modifier = HEAT_BONUS_MODIFIER_CLASS.new(DEFAULT_HEAT_BONUS)
	_streak_modifier = STREAK_MULTIPLIER_MODIFIER_CLASS.new(DEFAULT_MAX_STREAK_MULTIPLIER)

## Creates the modifier chain with all available modifiers
func _create_modifier_chain() -> void:
	var modifiers = []
	
	# Add all valid modifiers to the chain
	if _base_modifier != null and _base_modifier.has_method("apply"):
		modifiers.append(_base_modifier)
	if _heat_bonus_modifier != null and _heat_bonus_modifier.has_method("apply"):
		modifiers.append(_heat_bonus_modifier)
	if _streak_modifier != null and _streak_modifier.has_method("apply"):
		modifiers.append(_streak_modifier)
	
	# Create the chain if we have any modifiers
	if not modifiers.is_empty():
		_score_chain = SCORE_MODIFIER_CLASS.chain(modifiers)
	else:
		push_error("Failed to create modifier chain: No valid modifiers available")

## Berechnet den Score für ein gefundenes Paar
## @param context: Dictionary mit Kontextinformationen (z.B. current_streak, cards_in_play, etc.)
## @return Dictionary mit "score" (int) und "description" (String)
func calculate_pair_score(context: Dictionary = {}) -> Dictionary:
	# Ensure the context is valid
	if not context is Dictionary:
		push_error("Invalid context parameter: " + str(context))
		return {"score": 0, "description": ""}
	
	# Apply all modifiers if the chain is valid
	if _score_chain != null:
		var result = _score_chain.apply(0, context)
		
		# Ensure the result has the correct format
		if not result is Dictionary or not "score" in result or not "description" in result:
			push_error("Invalid result from score chain: " + str(result))
			return {"score": 0, "description": ""}
			
		return result
	else:
		push_error("Cannot calculate score: Score chain not initialized")
		return {"score": 0, "description": ""}

## Setzt die Basis-Punkte pro Paar
## @param points: Die Anzahl der Basis-Punkte pro Paar
func set_base_points(points: int) -> void:
	if _base_modifier != null:
		_base_modifier._points_per_pair = max(0, points)  # Ensure non-negative
		_recreate_chain()  # Recreate chain to apply changes
	else:
		push_error("Cannot set base points: Base modifier not initialized")

## Setzt den Heat-Bonus für rhythmische Kartenpaare
## @param bonus: Die Höhe des Bonus (muss nicht negativ sein)
func set_heat_bonus(bonus: int) -> void:
	if _heat_bonus_modifier != null:
		_heat_bonus_modifier._bonus_amount = max(0, bonus)  # Ensure non-negative
		_recreate_chain()  # Recreate chain to apply changes
	else:
		push_error("Cannot set heat bonus: Heat bonus modifier not initialized")

## Setzt den maximalen Streak-Multiplikator
## @param multiplier: Der maximale Multiplikator (muss >= 1.0 sein)
func set_max_streak_multiplier(multiplier: float) -> void:
	if _streak_modifier != null:
		_streak_modifier._max_multiplier = max(1.0, multiplier)  # Ensure at least 1.0
		_recreate_chain()  # Recreate chain to apply changes
	else:
		push_error("Cannot set max streak multiplier: Streak modifier not initialized")

## Fügt einen benutzerdefinierten Modifikator zur Kette hinzu
## Adds a new modifier to the end of the chain
## @param modifier The modifier to add
func add_custom_modifier(modifier: Object) -> void:
	if modifier == null or not modifier.has_method("apply"):
		push_error("Cannot add invalid modifier")
		return
		
	# If we don't have a chain yet, create one with just this modifier
	if _score_chain == null:
		_score_chain = modifier
		return
		
	# If the current chain is a ChainModifier, add to it
	if _score_chain.has_method("add_modifier"):
		_score_chain.add_modifier(modifier)
	else:
		# Otherwise, create a new chain with both the old and new modifiers
		var new_chain = SCORE_MODIFIER_CLASS.chain([_score_chain, modifier])
		if new_chain != null:
			_score_chain = new_chain
		else:
			push_error("Failed to create new chain with custom modifier")
func add_modifier(modifier: ScoreModifier) -> void:
	if modifier != null and _score_chain is ScoreModifier.ChainModifier:
		_score_chain._modifiers.append(modifier)

## Recreates the modifier chain with the current modifier settings
func _recreate_chain() -> void:
	var valid_modifiers = []
	
	# Only add valid modifiers that have the apply method
	if _base_modifier != null and _base_modifier.has_method("apply"):
		valid_modifiers.append(_base_modifier)
	if _heat_bonus_modifier != null and _heat_bonus_modifier.has_method("apply"):
		valid_modifiers.append(_heat_bonus_modifier)
	if _streak_modifier != null and _streak_modifier.has_method("apply"):
		valid_modifiers.append(_streak_modifier)
	
	if valid_modifiers.is_empty():
		push_error("Cannot recreate chain: No valid modifiers available")
		return
	
	_score_chain = SCORE_MODIFIER_CLASS.chain(valid_modifiers)
	
	if _score_chain == null:
		push_error("Failed to recreate score chain")
