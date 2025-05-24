# Speichern als: res://Globals/EventManager.gd
extends Node

# Signals
# warning-ignore:unused_signal
signal pair_found(data)
# warning-ignore:unused_signal
signal mismatch_attempt()
# warning-ignore:unused_signal
signal all_pairs_found()
# warning-ignore:unused_signal
signal card_flipped_by_user(card)

# Map event names to signal names for compatibility.
const _EVENT_SIGNAL_MAP: Dictionary = {
	"pair_found": &"pair_found",
	"mismatch_attempt": &"mismatch_attempt",
	"all_pairs_found": &"all_pairs_found",
	"card_flipped_by_user": &"card_flipped_by_user",
}

# ------------------------------------------------------------------ #
# Compatibility wrapper API                                          #
# ------------------------------------------------------------------ #

func connect_to_event(event_name: String, callable: Callable) -> void:
	if not callable.is_valid():
		push_warning("EventManager: Invalid callable for '" + event_name + "'.")
		return
	var sig: StringName = _EVENT_SIGNAL_MAP.get(event_name, StringName(""))
	if sig == StringName("") or not has_signal(sig):
		push_warning("EventManager: Unknown event '" + event_name + "'.")
		return
	if is_connected(sig, callable):
		return
	connect(sig, callable)

func emit_event(event_name: String, payload: Variant = null) -> void:
	var sig: StringName = _EVENT_SIGNAL_MAP.get(event_name, StringName(""))
	if sig == StringName("") or not has_signal(sig):
		push_warning("EventManager: Unknown event '" + event_name + "'.")
		return
	if payload == null:
		emit_signal(sig)
	else:
		emit_signal(sig, payload)

func disconnect_from_event(event_name: String, callable: Callable) -> void:
	var sig: StringName = _EVENT_SIGNAL_MAP.get(event_name, StringName(""))
	if sig == StringName("") or not has_signal(sig):
		return
	if is_connected(sig, callable):
		disconnect(sig, callable)

# Simple stubs for clear_all/clear_event listeners (manual in Godot 4)
func clear_event_listeners(_event_name: String):
	push_warning("EventManager: clear_event_listeners not supported – disconnect manually.")

func clear_all_listeners():
	push_warning("EventManager: clear_all_listeners not supported – disconnect manually.")
