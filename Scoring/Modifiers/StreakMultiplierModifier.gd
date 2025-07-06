extends "../ScoreModifier.gd"
class_name StreakMultiplierModifier

## A score modifier that applies a multiplier based on the player's current streak.
## This rewards players for making multiple successful matches in a row.

## The maximum multiplier that can be applied
var _max_multiplier: float

## Creates a new StreakMultiplierModifier with the specified maximum multiplier.
## @param max_multiplier The highest possible multiplier (default: 2.0)
func _init(max_multiplier: float = 2.0):
	_max_multiplier = max(1.0, max_multiplier)  # Ensure multiplier is at least 1.0

## Applies a streak-based multiplier to the score.
## The multiplier increases by 0.1 for each consecutive match, up to the maximum.
func apply(base_score: int, context: Dictionary = {}) -> Dictionary:
	var current_streak = context.get("current_streak", 0)
	
	# No multiplier if no streak or just one match
	if current_streak <= 1:
		return {"score": base_score, "description": ""}
		
	# Calculate multiplier (10% per streak, capped at max_multiplier)
	var multiplier = min(1.0 + (current_streak * 0.1), _max_multiplier)
	var new_score = int(base_score * multiplier)
	var bonus = new_score - base_score

	# Only show description if there's an actual bonus
	var description = ""
	if bonus > 0:
		description = "x%.1f Streak (+%d)" % [multiplier, bonus]

	return {
		"score": new_score,
		"description": description
	}
