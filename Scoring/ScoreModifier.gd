## Base class for all score modifiers in the game.
## This class should be extended to create custom score modifiers.
extends RefCounted
class_name ScoreModifier

## Applies this score modifier to the given base score and context.
## Must be overridden by child classes.
## @param base_score The base score to modify
## @param _context Additional context for the modification (unused in base class)
## @return Dictionary containing 'score' (int) and 'description' (String)
func apply(base_score: int, _context: Dictionary = {}) -> Dictionary:
	push_error("apply() must be overridden in child classes")
	return {
		"score": base_score,
		"description": ""
	}

## Chains multiple score modifiers together.
## @param modifiers Array of ScoreModifier instances to chain
## @return A new ScoreModifier that applies all modifiers in sequence
static func chain(modifiers: Array) -> ScoreModifier:
	if modifiers.is_empty():
		push_error("Cannot create chain: No modifiers provided")
		return null
	return ChainModifier.new(modifiers)

# A modifier that chains multiple modifiers together.
class ChainModifier extends ScoreModifier:
	## Array of modifiers to apply in sequence
	var _modifiers: Array[ScoreModifier] = []

	## Creates a new ChainModifier with the given modifiers
	## @param modifiers Array of ScoreModifier instances to chain
	func _init(modifiers: Array[ScoreModifier]):
		for modifier in modifiers:
			if modifier != null:
				_modifiers.append(modifier)

	## Applies all modifiers in sequence
	func apply(base_score: int, context: Dictionary = {}) -> Dictionary:
		var current_score = base_score
		var descriptions: Array[String] = []

		for modifier in _modifiers:
			if modifier != null:
				var result = modifier.apply(current_score, context)
				if not result is Dictionary:
					push_error("Invalid result from modifier: " + str(result))
					continue
				
				current_score = result.get("score", current_score)
				var desc = result.get("description", "")
				if desc and not desc.is_empty():
					descriptions.append(desc)

		return {
			"score": current_score,
			"description": " ".join(descriptions)
		}

	## Adds a new modifier to the end of the chain
	## @param modifier The modifier to add
	func add_modifier(modifier: ScoreModifier) -> void:
		if modifier != null:
			_modifiers.append(modifier)
		else:
			push_error("Cannot add null modifier to chain")
