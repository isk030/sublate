# Speichern als: res://Globals/EventManager.gd
extends Node

# Ein Dictionary, um Listen von Callables für jeden Event-Namen zu speichern
var _event_listeners: Dictionary = {}


# Methode, um eine Funktion (Callable) mit einem Event-Namen zu verbinden
func connect_to_event(event_name: String, callable: Callable) -> void:
	if not callable.is_valid():
		printerr("EventManager: Versuch, ein ungültiges Callable mit Event '", event_name, "' zu verbinden.")
		return

	if not _event_listeners.has(event_name):
		_event_listeners[event_name] = []
	
	# Verhindern, dass dasselbe Callable mehrmals für dasselbe Event registriert wird
	if not _event_listeners[event_name].has(callable):
		_event_listeners[event_name].append(callable)
		# print("EventManager: Callable für Objekt '", callable.get_object().name if callable.get_object() else "null", "' (Methode: '", callable.get_method(), "') verbunden mit Event '", event_name, "'")
	else:
		pass
		# print("EventManager: Callable für Objekt '", callable.get_object().name if callable.get_object() else "null", "' (Methode: '", callable.get_method(), "') ist bereits mit Event '", event_name, "' verbunden.")


# Methode, um ein Event auszulösen
func emit_event(event_name: String, payload: Variant = null) -> void:
	if _event_listeners.has(event_name):
		# print("EventManager: Sende Event '", event_name, "' mit Payload: ", payload)
		# Wichtig: Iteriere über eine Kopie des Arrays, falls ein Listener sich selbst oder andere entfernt
		var listeners_copy = _event_listeners[event_name].duplicate()
		for callable in listeners_copy:
			if callable.is_valid():
				# Rufe das Callable mit dem Payload auf, wenn vorhanden
				var bind_count = callable.get_bound_arguments_count()
				var arguments_to_pass = []
				if payload != null:
					arguments_to_pass.append(payload)
				
				# Berücksichtige gebundene Argumente
				for i in range(bind_count):
					arguments_to_pass.insert(i, callable.get_bound_arguments()[i])

				callable.callv(arguments_to_pass) # callv für variable Argumentanzahl
			else:
				# Optional: Ungültige Callables aus der Originalliste entfernen
				# Vorsicht beim Modifizieren von Arrays während der Iteration!
				# Hier ist es sicherer, da wir über eine Kopie iterieren,
				# aber die Entfernung sollte auf _event_listeners[event_name] erfolgen.
				# _event_listeners[event_name].erase(callable) 
				printerr("EventManager: Ungültiges Callable für Event '", event_name, "' gefunden. Entfernung wird empfohlen.")
	else:
		pass
		# print("EventManager: Event '", event_name, "' gesendet, aber keine Listener verbunden.")


# Optionale Methode, um die Verbindung eines Callables zu einem Event zu trennen
func disconnect_from_event(event_name: String, callable: Callable) -> void:
	if _event_listeners.has(event_name) and _event_listeners[event_name].has(callable):
		_event_listeners[event_name].erase(callable)
		# print("EventManager: Callable für Objekt '", callable.get_object().name if callable.get_object() else "null", "' (Methode: '", callable.get_method(), "') von Event '", event_name, "' getrennt.")


# Beispielfunktion, um alle Listener für ein Event zu entfernen (z.B. beim Szenenwechsel)
func clear_event_listeners(event_name: String) -> void:
	if _event_listeners.has(event_name):
		_event_listeners[event_name].clear()
		# print("EventManager: Alle Listener für Event '", event_name, "' entfernt.")

# Beispielfunktion, um alle Listener für alle Events zu entfernen
func clear_all_listeners() -> void:
	_event_listeners.clear()
	# print("EventManager: Alle Listener für alle Events entfernt.")

# Du könntest hier auch eine interne Klasse oder ein Enum für Event-Namen definieren,
# um Tippfehler zu vermeiden, z.B.:
# class Events:
#	const CARD_FLIPPED: StringName = &"card_flipped"
#	const PAIR_FOUND: StringName = &"pair_found"
#	const MISMATCH_ATTEMPT: StringName = &"mismatch_attempt"
#	const UPDATE_SCORE: StringName = &"update_score"
#	const GAME_OVER: StringName = &"game_over"