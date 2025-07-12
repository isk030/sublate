extends Control

# Referenzen zu UI-Elementen
@onready var _icon_texture: TextureRect = $ItemContainer/Icon
@onready var _count_label: Label = $ItemContainer/CountLabel
@onready var _button: Button = $ItemContainer

# Das aktuelle Item, das dieses Widget darstellt
var _item_id: String = ""
var _count: int = 0
var _enabled: bool = false
var _inventory_manager = null
var _is_display_only: bool = false

# Signal, wenn das Item verwendet werden soll
signal item_used(item_id: String)

func _ready() -> void:
	# Hole den InventoryManager-Singleton
	_inventory_manager = get_node_or_null("/root/InventoryManager")
	if not _inventory_manager:
		push_error("ItemWidget: InventoryManager-Singleton nicht gefunden")
	
	if _button:
		_button.pressed.connect(_on_button_pressed)
	
	# Standardmäßig deaktiviert
	set_enabled(false)
	
	# Verbinde mit dem InventoryManager
	if _inventory_manager:
		_inventory_manager.item_count_changed.connect(_on_item_count_changed)

# Setzt das Item, das dieses Widget anzeigen soll
func set_item(item_id: String, count: int = 0) -> void:
	_item_id = item_id
	_count = count
	
	# Icon aktualisieren
	if _inventory_manager and _item_id == _inventory_manager.ITEM_STAP_SCRATCH:
		# Hier können wir später ein angepasstes Icon laden
		if _icon_texture:
			_icon_texture.modulate = Color(0.8, 0.4, 0.2)  # Orange-Braun für "Stap Scratch"
	
	# Anzahl aktualisieren
	update_count(_count)
	
	# Aktiviere Widget, wenn Anzahl > 0
	set_enabled(_count > 0)

# Aktualisiere die angezeigte Anzahl
func update_count(count: int) -> void:
	_count = count
	if _count_label:
		_count_label.text = str(_count)
	
	# Aktiviere oder deaktiviere je nach Anzahl
	set_enabled(_count > 0)

# Aktiviert oder deaktiviert das Widget
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if _button:
		_button.disabled = not _enabled
		
	# Zeige das Widget nur, wenn es aktiviert ist oder mindestens 1 Item vorhanden ist
	# Bei Display-Only Widgets immer sichtbar, wenn sie aktiviert sind
	if _is_display_only:
		visible = _enabled
	else:
		visible = _enabled or _count > 0
	
	# Verdunkle das Icon, wenn deaktiviert
	if _icon_texture:
		_icon_texture.modulate.a = 1.0 if _enabled else 0.5
		
# Setzt das Widget auf Display-Only Modus (nicht klickbar, nur zur Anzeige)
func set_as_display_only() -> void:
	_is_display_only = true
	if _button:
		# Entferne die Klick-Interaktion
		_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_button.disabled = false
		
	# Verstecke die Anzahl, da sie für Buffs nicht relevant ist
	if _count_label:
		_count_label.visible = false
	
	# Aktiviere standardmäßig
	_enabled = true

# Callback für InventoryManager-Signale
func _on_item_count_changed(item_id: String, count: int) -> void:
	if item_id == _item_id:
		update_count(count)

# Callback für Button-Klick
func _on_button_pressed() -> void:
	if _enabled and _count > 0:
		emit_signal("item_used", _item_id)
