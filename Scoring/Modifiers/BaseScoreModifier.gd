extends "../ScoreModifier.gd"
class_name BaseScoreModifier

## A score modifier that applies a fixed amount of points per pair found.
## This is typically used as the first modifier in the chain to establish a base score.

## The number of points awarded per pair found
var _points_per_pair: int

## Creates a new BaseScoreModifier with the specified points per pair.
## @param points_per_pair The number of points to award per pair (must be >= 0)
func _init(points_per_pair: int):
	_points_per_pair = max(0, points_per_pair)  # Ensure non-negative points

## Applies the base score calculation.
## Multiplies the points per pair by the number of pairs found in the context.
## @param _base_score The base score (ignored in this implementation)
## @param context Dictionary containing scoring context (e.g., pairs_found)
## @return Dictionary with 'score' (int) and 'description' (String)
func apply(_base_score: int, context: Dictionary = {}) -> Dictionary:
	# Ensure we have a valid context and pairs_found value
	if not context is Dictionary:
		push_error("Invalid context parameter: " + str(context))
		return {"score": 0, "description": ""}
	
	var pairs_found = max(0, context.get("pairs_found", 1))  # Ensure non-negative
	var score = _points_per_pair * pairs_found
	
	# Only show description if we actually have points
	var description = "%d Punkte" % score if score > 0 else ""
	
	return {
		"score": score,
		"description": description
	}
