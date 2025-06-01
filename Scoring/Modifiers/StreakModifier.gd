extends "res://Scoring/Modifiers/BaseModifier.gd"

const MAX_STREAK_MULTIPLIER = 10

func apply(base_points: int, context: Dictionary) -> Dictionary:
	var current_streak = context.get("current_streak", 1)
	var multiplier = min(current_streak, MAX_STREAK_MULTIPLIER)
	
	if multiplier <= 1:
		return {"points": base_points, "description": ""}
		
	var new_points = base_points * multiplier
	
	return {
		"points": new_points,
		"description": "x%d Streak" % multiplier
	}
