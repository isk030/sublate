extends Control

# Signal wird emittiert, wenn ein Item verwendet wird
signal item_used(item_id)

# Referenz zum Item-Widget für Stap Scratch
@onready var _stap_scratch_widget = $VBoxContainer/HBoxContainer/StapScratchItem

# Referenz zum InventoryManager-Singleton
@onready var _inventory_manager = get_node_or_null("/root/InventoryManager")

# Verbindung zum GameManager für die Item-Nutzung
var game_manager: Node = null

func _ready() -> void:
	if not _inventory_manager:
		push_error("InventoryPanel: InventoryManager-Singleton nicht gefunden")
		return
	
	if _stap_scratch_widget:
		_stap_scratch_widget.set_item(_inventory_manager.ITEM_STAP_SCRATCH)
		_stap_scratch_widget.item_used.connect(_on_stap_scratch_used)
		
		# Update mit aktuellem Bestand
		_stap_scratch_widget.update_count(_inventory_manager.get_item_count(_inventory_manager.ITEM_STAP_SCRATCH))

# Setze die Referenz zum GameManager
func set_game_manager(manager: Node) -> void:
	game_manager = manager

# Aktiviert oder deaktiviert die Items
func set_items_enabled(enabled: bool) -> void:
	if not _inventory_manager:
		return
		
	if _stap_scratch_widget:
		_stap_scratch_widget.set_enabled(enabled and _inventory_manager.get_item_count(_inventory_manager.ITEM_STAP_SCRATCH) > 0)

# Item "Stap Scratch" wurde verwendet
func _on_stap_scratch_used(item_id: String) -> void:
	print("Item verwendet: ", item_id)
	
	# Prüfe, ob _inventory_manager existiert
	if not _inventory_manager:
		push_error("InventoryPanel: _inventory_manager ist null bei Item-Verwendung")
		return
	
	# Prüfe, ob das Item wirklich im Inventar ist
	if not _inventory_manager.has_item(item_id):
		print("Item nicht im Inventar vorhanden!")
		return
	
	# Versuche, das Item zu verwenden (stellt sicher, dass die Anzahl verringert wird)
	if _inventory_manager.use_item(item_id):
		# Signal emittieren, dass ein Item verwendet wurde
		emit_signal("item_used", item_id)
		
		# Die direkte Anwendung ist jetzt optional, da der Main-Controller
		# sich über das Signal kümmern wird
		if game_manager:
			game_manager.reset_random_matched_pair()
		else:
			push_error("InventoryPanel: GameManager-Referenz fehlt, kann Item-Effekt nicht direkt anwenden")
	else:
		print("Fehler beim Verwenden des Items!")
