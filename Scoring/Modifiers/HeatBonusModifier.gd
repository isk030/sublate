extends "res://Scoring/Modifiers/BaseModifier.gd"

class_name HeatBonusModifier

## The bonus points to add when both cards are flipped in rhythm.
const HEAT_BONUS = 100

## Applies the heat bonus if both cards were flipped in rhythm.
## Returns the modified score and a description of the modification.
func apply(base_points: int, context: Dictionary) -> Dictionary:
	var heat_bonus = context.get("heat_bonus", 0)
	var in_rhythm = context.get("in_rhythm", false)
	
	if heat_bonus <= 0 or not in_rhythm:
		return {"points": base_points, "description": ""}
		
	return {
		"points": base_points + heat_bonus,
		"description": "+%d Heat Bonus" % heat_bonus
	}
