extends Control

# Signal wird emittiert, wenn ein Item verwendet wird
signal item_used(item_id)

# Referenzen zu Item-Widgets
@onready var _stap_scratch_widget = $VBoxContainer/HBoxContainer/StapScratchItem
@onready var _hbox_container = $VBoxContainer/HBoxContainer

# Referenz zum InventoryManager-Singleton
@onready var _inventory_manager = get_node_or_null("/root/InventoryManager")

# Referenzen zu ScoreManager für Buff-Status
@onready var _score_manager = get_node_or_null("/root/ScoreManager")

# Preload des ItemWidget
const ItemWidgetScene = preload("res://Scenes/item_widget.tscn")

# Preload der Texturen für die Buffs (identisch zu denen in ShopUI)
const HEAT_BONUS_TEXTURE = preload("res://assets/images/ChatGPT Bild 12 Juli 2025 (1).png")
const BASE_POINTS_TEXTURE = preload("res://assets/images/ChatGPT Bild 12 Juli 2025 (2).png")

# Buff Icons referenzen
var _heat_bonus_widget: Control = null
var _base_points_widget: Control = null

# Konstanten für Buff-Typen
const BUFF_HEAT_BONUS = "heat_bonus"
const BUFF_BASE_POINT_INCREASE = "base_point_increase"

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
	
	# Initialisiere Buff-Anzeigen
	_initialize_buff_widgets()
	
	# Wenn ScoreManager existiert, überwache Änderungen an den Buffs
	if _score_manager:
		_update_buff_displays()

# Setze die Referenz zum GameManager
func set_game_manager(manager: Node) -> void:
	game_manager = manager

# Aktiviert oder deaktiviert die Items
func set_items_enabled(enabled: bool) -> void:
	if not _inventory_manager:
		return
		
	if _stap_scratch_widget:
		_stap_scratch_widget.set_enabled(enabled and _inventory_manager.get_item_count(_inventory_manager.ITEM_STAP_SCRATCH) > 0)
		
	# Buff-Widgets nicht deaktivieren, da sie nur zur Anzeige dienen

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
		
# Initialisiert die Widgets für die Buffs
func _initialize_buff_widgets() -> void:
	# Erstelle Widgets für die Buffs, wenn sie noch nicht existieren
	if not _heat_bonus_widget:
		_heat_bonus_widget = ItemWidgetScene.instantiate()
		_hbox_container.add_child(_heat_bonus_widget)
		_heat_bonus_widget.name = "HeatBonusWidget"
		_heat_bonus_widget.visible = false
	
	if not _base_points_widget:
		_base_points_widget = ItemWidgetScene.instantiate()
		_hbox_container.add_child(_base_points_widget)
		_base_points_widget.name = "BasePointsWidget"
		_base_points_widget.visible = false
	
	# Konfiguriere die Widgets
	# Für Heat Bonus
	if _heat_bonus_widget:
		# Konfiguriere als Anzeige-Widget (nicht klickbar)
		_heat_bonus_widget.set_item(BUFF_HEAT_BONUS, 1)
		_heat_bonus_widget.set_as_display_only()
		var heat_bonus_label = _heat_bonus_widget.get_node_or_null("ItemContainer/ItemName")
		if heat_bonus_label:
			heat_bonus_label.text = "Heat Bonus"
		
		# Setze die Textur aus der ShopUI
		var texture_rect = _heat_bonus_widget.get_node_or_null("ItemContainer/TextureRect")
		if texture_rect:
			texture_rect.texture = HEAT_BONUS_TEXTURE
	
	# Für Base Points
	if _base_points_widget:
		# Konfiguriere als Anzeige-Widget (nicht klickbar)
		_base_points_widget.set_item(BUFF_BASE_POINT_INCREASE, 1)
		_base_points_widget.set_as_display_only()
		var base_points_label = _base_points_widget.get_node_or_null("ItemContainer/ItemName")
		if base_points_label:
			base_points_label.text = "Base Points+"
		
		# Setze die Textur aus der ShopUI
		var texture_rect = _base_points_widget.get_node_or_null("ItemContainer/TextureRect")
		if texture_rect:
			texture_rect.texture = BASE_POINTS_TEXTURE

# Aktualisiert die Sichtbarkeit der Buff-Widgets basierend auf aktivierten Buffs
func _update_buff_displays() -> void:
	if _score_manager:
		# Update Heat Bonus Widget
		if _heat_bonus_widget:
			_heat_bonus_widget.visible = _score_manager.is_heat_bonus_enabled()
		
		# Update Base Points Widget
		if _base_points_widget:
			_base_points_widget.visible = _score_manager.is_base_point_increase_enabled()

# Öffentliche Methode zum manuellen Aktualisieren der Buff-Anzeigen
func update_buff_displays() -> void:
	_update_buff_displays()
