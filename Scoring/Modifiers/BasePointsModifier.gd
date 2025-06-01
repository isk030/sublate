extends "res://Scoring/Modifiers/BaseModifier.gd"

func apply(base_points: int, context: Dictionary) -> Dictionary:
	var pairs_found = context.get("pairs_found", 1)
	var points = 100 + ((pairs_found - 1) * 20)
	
	return {
		"points": points,
		"description": "Basis: %d" % points
	}
