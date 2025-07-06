extends "res://Scoring/Modifiers/BaseModifier.gd"

func apply(_base_points: int, context: Dictionary) -> Dictionary:
	var pairs_found = context.get("pairs_found", 1)
	var match_successful = context.get("match_successful", true)
	
	var points = 0
	if match_successful:
		points = 100 + ((pairs_found - 1) * 20)
	
	return {
		"points": points,
		"description": "Basis: %d" % points
	}
