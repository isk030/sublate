class_name BaseModifier

# Wird aufgerufen, um die Punkte zu modifizieren
# Gibt ein Dictionary zurück mit:
# - points: Die modifizierten Punkte
# - description: Optionaler Beschreibungstext
func apply(_base_points: int, _context: Dictionary) -> Dictionary:
	push_error("apply() muss in der Kindklasse überschrieben werden!")
	return {
		"points": _base_points,
		"description": ""
	}

# Hilfsfunktion für die Erstellung von Beschreibungen
func _format_description(text: String, value) -> String:
	return text.replace("{value}", str(value))
