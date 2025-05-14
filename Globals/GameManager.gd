extends Node

# --- Konstanten ---
const CARD_PAIR_COUNT: int = 4
const DEFAULT_CARD_AREA_SIZE: int = 2 * CARD_PAIR_COUNT
const INITIAL_LEVEL: int = 1
const CARD_GRID_COLUMNS: int = int(ceil(sqrt(float(DEFAULT_CARD_AREA_SIZE))))
const MINIMUM_CARD_SIZE: int = 200

const CARD_TEXTURE_PATHS: Array[String] = [
	"res://assets/cards/cassettes.png", "res://assets/cards/ghetto-blaster.png",
	"res://assets/cards/spray-can.png", "res://assets/cards/vinyl.png",

]

var card_area: Control = null
var card_back_tex: Texture2D = load("res://assets/cards/level_select_frame_128.png")
var card_front_tex: Texture2D = load("res://assets/cards/vinyl.png")

var _all_textures: Array[Texture2D] = []
var _available_textures: Array[Texture2D] = []

func _ready() -> void:
	randomize()
	_load_textures()
	_reset_texture_pool()
	print("GameManager (Autoload) bereit.")


func set_card_area_ref(area_node: Control) -> void:
	card_area = area_node
	print("GameManager: 'card_area' Ref erhalten.")


func _load_textures() -> void:
	_all_textures.clear()
	for path in CARD_TEXTURE_PATHS:
		var tex: Texture2D = load(path)
		if tex: _all_textures.append(tex)
		else: printerr("Fehler: Textur konnte nicht geladen werden: ", path)

	if _all_textures.is_empty(): printerr("Warnung: Keine Texturen geladen! Pfade prüfen.")
	else: print("GameManager: ", _all_textures.size(), " Texturen geladen.")

func _reset_texture_pool() -> void:
	_available_textures.clear()

	var num_unique_cards_needed = int(DEFAULT_CARD_AREA_SIZE / 2.0)

	if DEFAULT_CARD_AREA_SIZE % 2 != 0:
		printerr("FEHLER in _reset_texture_pool: DEFAULT_CARD_AREA_SIZE muss eine gerade Zahl sein, um Paare zu bilden! Aktuell: ", DEFAULT_CARD_AREA_SIZE)
		return

	if _all_textures.size() < num_unique_cards_needed:
		printerr("FEHLER in _reset_texture_pool: Nicht genug einzigartige Texturen in '_all_textures', um ", num_unique_cards_needed, " Paare für ", DEFAULT_CARD_AREA_SIZE, " Karten zu bilden. Benötigt: ", num_unique_cards_needed, ", Verfügbar: ", _all_textures.size(), ". Bitte 'CARD_TEXTURE_PATHS' anpassen.")
		return

	var temp_unique_textures_pool = _all_textures.duplicate()
	temp_unique_textures_pool.shuffle()

	for i in range(num_unique_cards_needed):
		var chosen_texture = temp_unique_textures_pool.pop_front()
		_available_textures.append(chosen_texture)
		_available_textures.append(chosen_texture)

	_available_textures.shuffle()
	print("GameManager: Texturen-Pool für Memory-Spiel zurückgesetzt. Größe: ", _available_textures.size(), " (", num_unique_cards_needed, " Paare).")

func get_random_unique_texture() -> Texture2D:
	if _available_textures.is_empty():
		print("GameManager: Alle Texturen verwendet. Setze Pool zurück.")
		_reset_texture_pool()
		if _available_textures.is_empty():
			printerr("GameManager: Fehler: Keine Texturen nach Reset. Gebe null zurück.")
			return null

	var rand_idx = randi() % _available_textures.size()
	var selected_tex = _available_textures[rand_idx]
	_available_textures.remove_at(rand_idx)
	return selected_tex

func init_game_elements() -> void:
	if card_area == null:
		printerr("GameManager: Fehler: 'card_area' ist NULL. Main.gd muss Referenz übergeben.")
		return

	card_area.visible = true
	var card_container: GridContainer = card_area.get_node_or_null("GridContainer")

	if card_container == null or not card_container is GridContainer:
		printerr("GameManager: Fehler: GridContainer nicht gefunden oder falscher Typ unter 'card_area'.")
		return

	card_container.columns = CARD_GRID_COLUMNS
	for i in range(DEFAULT_CARD_AREA_SIZE):
		_init_single_card(card_container)

	print("GameManager: Spiel-Elemente (Karten-Auslage) initialisiert.")

func init_player_panel() -> void:
	ScoreManager.reset_score_panel()
	print("GameManager: Spieler-Panel Initialisierung angefordert.")

func _init_single_card(card_container: GridContainer) -> void:
	var new_card = TextureButton.new()
	new_card.texture_normal = card_back_tex
	new_card.toggle_mode = true
	new_card.stretch_mode = TextureButton.STRETCH_SCALE
	new_card.custom_minimum_size = Vector2(MINIMUM_CARD_SIZE, MINIMUM_CARD_SIZE)

	var card_face_tex: Texture2D = get_random_unique_texture()
	if card_face_tex:
		new_card.texture_pressed = card_face_tex
	else:
		printerr("GameManager: Warnung: Keine einzigartige Kartentextur erhalten. Nutze Fallback.")
		new_card.texture_normal = card_back_tex
		var fallback_rect = ColorRect.new()
		fallback_rect.color = Color.MAGENTA
		fallback_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		new_card.add_child(fallback_rect)

	card_container.add_child(new_card)
