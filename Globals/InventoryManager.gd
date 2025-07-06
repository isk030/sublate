extends Node

# Item-Definitionen
const ITEM_STAP_SCRATCH = "stap_scratch"

# Inventar-Daten
var _items = {
	ITEM_STAP_SCRATCH: 0  # Anzahl des Items
}

# Flag, ob das Inventar bereits im aktuellen Spiel initialisiert wurde
var _inventory_initialized = false

# Signal, wenn sich die Item-Anzahl ändert
signal item_count_changed(item_id: String, count: int)

func _ready() -> void:
	print("InventoryManager ready")
	
# Füge dem Inventar ein Item hinzu
func add_item(item_id: String, amount: int = 1) -> void:
	if item_id in _items:
		_items[item_id] += amount
		emit_signal("item_count_changed", item_id, _items[item_id])
		print("Item hinzugefügt: ", item_id, " x", amount, " - Neuer Bestand: ", _items[item_id])
	else:
		push_error("InventoryManager: Unbekanntes Item-ID: " + item_id)

# Verwende ein Item aus dem Inventar
func use_item(item_id: String) -> bool:
	if item_id in _items and _items[item_id] > 0:
		_items[item_id] -= 1
		emit_signal("item_count_changed", item_id, _items[item_id])
		print("Item verwendet: ", item_id, " - Verbleibend: ", _items[item_id])
		return true
	return false

# Gibt zurück, ob genug Items vom angegebenen Typ im Inventar sind
func has_item(item_id: String, amount: int = 1) -> bool:
	return item_id in _items and _items[item_id] >= amount

# Gibt die Anzahl eines Items im Inventar zurück
func get_item_count(item_id: String) -> int:
	return _items.get(item_id, 0)

# Initialisiert das Inventar für einen neuen Spieler (erste Runde)
func initialize_inventory() -> void:
	if not _inventory_initialized:
		_inventory_initialized = true
		print("Inventar erstmalig initialisiert - Items werden im nächsten Run verfügbar sein")

# Gibt dem Spieler die Start-Items nach dem ersten Run
func award_start_items() -> void:
	if _inventory_initialized:
		add_item(ITEM_STAP_SCRATCH, 1)
		print("Start-Items vergeben")
