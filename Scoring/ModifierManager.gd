class_name ModifierManager
extends Node

# Liste der aktiven Modifier in der Reihenfolge ihrer Ausführung
var _modifiers = []

# Fügt einen neuen Modifier hinzu
func add_modifier(modifier: BaseModifier) -> void:
	if not modifier in _modifiers:
		_modifiers.append(modifier)

# Entfernt einen Modifier
func remove_modifier(modifier: BaseModifier) -> void:
	_modifiers.erase(modifier)

# Wendet alle Modifier auf die Basis-Punkte an
func apply_modifiers(base_points: int, context: Dictionary) -> Dictionary:
	var current_points = base_points
	var descriptions = []
	
	for modifier in _modifiers:
		var result = modifier.apply(current_points, context)
		current_points = result.points
		
		# Nur nicht-leere Beschreibungen hinzufügen
		if result.get("description", "") != "":
			descriptions.append(result.description)
	
	return {
		"points": current_points,
		"descriptions": descriptions
	}

# Gibt eine lesbare Zusammenfassung der aktiven Modifier zurück
func get_modifier_list() -> String:
	var names = []
	for mod in _modifiers:
		names.append(mod.get_script().get_path().get_file().replace(".gd", ""))
	return ", ".join(names) if names.size() > 0 else "Keine Modifier aktiv"
