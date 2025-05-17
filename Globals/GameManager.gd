extends Node

## Manages the overall game state, card interactions, and texture loading for the memory game.

# --- Constants ---
const CARD_PAIR_COUNT: int = 4 ## Number of pairs to find.
const DEFAULT_CARD_AREA_SIZE: int = 2 * CARD_PAIR_COUNT ## Total number of cards on the board.
# const INITIAL_LEVEL: int = 1 # Currently unused.
const CARD_GRID_COLUMNS: int = int(ceil(sqrt(float(DEFAULT_CARD_AREA_SIZE)))) ## Columns for the card grid.
const MINIMUM_CARD_SIZE: int = 200 ## Minimum size for a card visual.

## Paths to card face textures.
const CARD_TEXTURE_PATHS: Array[String] = [
	"res://assets/cards/cassettes.png", "res://assets/cards/ghetto-blaster.png",
	"res://assets/cards/spray-can.png", "res://assets/cards/vinyl.png",
]

var card_area: Control = null ## Reference to the Control node where cards are placed.
var card_back_tex: Texture2D = load("res://assets/cards/level_select_frame_128.png") ## Default texture for card backs.
# var card_front_tex: Texture2D = load("res://assets/cards/vinyl.png") # Currently unused as unique textures are loaded per card.

var _all_textures: Array[Texture2D] = [] ## Holds all loaded unique card face textures.
var _available_textures: Array[Texture2D] = [] ## Holds pairs of textures ready for a game round.

const CardScript = preload("res://Globals/Card.gd") ## Preloaded Card script for instancing.

var _first_flipped_card: CardScript = null ## Reference to the first card flipped in a turn.
var _second_flipped_card: CardScript = null ## Reference to the second card flipped in a turn.
var _can_flip_cards: bool = true ## Controls if the player is allowed to flip cards.
var _pairs_found: int = 0 ## Counter for matched pairs.
var _total_pairs_to_find: int = 0 ## Total pairs to find in the current game setup.

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	_load_textures()
	_reset_texture_pool()
	print("GameManager (Autoload) bereit.")
	EventManager.connect_to_event("card_flipped_by_user", Callable(self, &"_on_card_flipped_by_user"))

## Sets the reference to the card area Control node from Main.gd.
func set_card_area_ref(area_node: Control) -> void:
	card_area = area_node
	print("GameManager: 'card_area' Ref erhalten.")

## Loads all unique card face textures from CARD_TEXTURE_PATHS.
func _load_textures() -> void:
	_all_textures.clear()
	for path in CARD_TEXTURE_PATHS:
		var tex: Texture2D = load(path)
		if tex:
			_all_textures.append(tex)
		else:
			printerr("Fehler: Textur konnte nicht geladen werden: ", path)

	if _all_textures.is_empty():
		printerr("Warnung: Keine Texturen geladen! Pfade prüfen.")
	else:
		print("GameManager: ", _all_textures.size(), " Texturen geladen.")

## Prepares the pool of textures for a new game round.
## Ensures there are enough unique textures and creates pairs.
func _reset_texture_pool() -> void:
	_available_textures.clear()
	_pairs_found = 0
	_first_flipped_card = null
	_second_flipped_card = null
	_can_flip_cards = true

	var num_unique_cards_needed = int(DEFAULT_CARD_AREA_SIZE / 2.0)
	_total_pairs_to_find = num_unique_cards_needed

	if DEFAULT_CARD_AREA_SIZE % 2 != 0:
		printerr("FEHLER: DEFAULT_CARD_AREA_SIZE muss eine gerade Zahl sein. Aktuell: ", DEFAULT_CARD_AREA_SIZE)
		return

	if _all_textures.size() < num_unique_cards_needed:
		printerr("FEHLER: Nicht genug einzigartige Texturen. Benötigt: ", num_unique_cards_needed, ", Verfügbar: ", _all_textures.size())
		return

	var temp_unique_textures_pool = _all_textures.duplicate()
	temp_unique_textures_pool.shuffle()

	for i in range(num_unique_cards_needed):
		var chosen_texture = temp_unique_textures_pool.pop_front()
		_available_textures.append(chosen_texture)
		_available_textures.append(chosen_texture) # Add twice for a pair

	_available_textures.shuffle()
	print("GameManager: Texturen-Pool zurückgesetzt. Größe: ", _available_textures.size(), " (", num_unique_cards_needed, " Paare).")

## Retrieves a random texture from the available pool for a card face.
## If the pool is empty, it attempts to reset it.
func get_random_unique_texture() -> Texture2D:
	if _available_textures.is_empty():
		print("GameManager: Alle Texturen verwendet. Setze Pool zurück.")
		_reset_texture_pool()
		if _available_textures.is_empty(): # Still empty after reset attempt
			printerr("GameManager: Fehler: Keine Texturen nach Reset. Gebe null zurück.")
			return null

	# randi() % size() can be slightly biased if size is not a power of 2. For small N, it's often fine.
	# A more uniform way for larger N would be randi_range(0, _available_textures.size() - 1)
	var rand_idx = randi() % _available_textures.size()
	var selected_tex = _available_textures[rand_idx]
	_available_textures.remove_at(rand_idx)
	return selected_tex

## Initializes the game board by creating and placing cards.
func init_game_elements() -> void:
	if card_area == null:
		printerr("GameManager: Fehler: 'card_area' ist NULL.")
		return

	card_area.visible = true
	var card_container: GridContainer = card_area.get_node_or_null("GridContainer")

	if card_container == null or not card_container is GridContainer:
		printerr("GameManager: Fehler: GridContainer nicht gefunden oder falscher Typ.")
		return

	card_container.columns = CARD_GRID_COLUMNS
	# Clear any existing cards before adding new ones
	for child in card_container.get_children():
		child.queue_free()
	
	for i in range(DEFAULT_CARD_AREA_SIZE):
		_init_single_card(card_container)

	print("GameManager: Spiel-Elemente (Karten-Auslage) initialisiert.")

## Requests ScoreManager to reset the player panel (e.g., score display).
func init_player_panel() -> void:
	ScoreManager.reset_score_panel()
	print("GameManager: Spieler-Panel Initialisierung angefordert.")

## Creates and configures a single card instance.
func _init_single_card(card_container: GridContainer) -> void:
	var new_card: CardScript = CardScript.new()
	new_card.texture_normal = card_back_tex
	new_card.toggle_mode = true
	new_card.stretch_mode = TextureButton.STRETCH_SCALE
	new_card.custom_minimum_size = Vector2(MINIMUM_CARD_SIZE, MINIMUM_CARD_SIZE)

	var card_face_tex: Texture2D = get_random_unique_texture()

	if card_face_tex:
		new_card.setup_card(card_face_tex, card_face_tex, card_back_tex)
		new_card.texture_pressed = card_face_tex # Shown when toggled (face up)
	else:
		printerr("GameManager: Warnung: Keine einzigartige Kartentextur erhalten. Nutze Fallback.")
		new_card.setup_card(null, null, card_back_tex)
		# Visual fallback: magenta rectangle
		var fallback_rect = ColorRect.new()
		fallback_rect.color = Color.MAGENTA
		fallback_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		new_card.add_child(fallback_rect)

	card_container.add_child(new_card)

# --- Event Handling and Game Logic ---

## Handles the event when a card is flipped by the user.
func _on_card_flipped_by_user(card_node: CardScript) -> void:
	if card_node.is_matched or not _can_flip_cards:
		return

	if _first_flipped_card == null:
		_first_flipped_card = card_node
	elif _second_flipped_card == null and card_node != _first_flipped_card:
		_second_flipped_card = card_node
		_can_flip_cards = false # Prevent more flips until these are processed
		_set_interaction_on_other_cards(true) # Disable other unflipped cards
		_process_flipped_cards()

## Processes the two currently flipped cards to check for a match or mismatch.
func _process_flipped_cards() -> void:
	# Determine whether the two selected cards match.
	var is_match: bool = _first_flipped_card.card_identifier == _second_flipped_card.card_identifier
	_handle_pair(is_match)

## Unified handling for both match and mismatch with a 1-second reveal pause.
func _handle_pair(is_match: bool) -> void:
	var timer := get_tree().create_timer(1.0) # 1-second reveal
	timer.timeout.connect(func():
		if not (is_instance_valid(_first_flipped_card) and is_instance_valid(_second_flipped_card)):
			_finalize_turn()
			return

		if is_match:
			_first_flipped_card.set_as_matched()
			_second_flipped_card.set_as_matched()
			_pairs_found += 1
			EventManager.emit_event("pair_found", {
				"pairs_found": _pairs_found,
				"total_pairs": _total_pairs_to_find
			})
			print("GameManager: Pair found! (", _pairs_found, "/", _total_pairs_to_find, ")")

			if _pairs_found == _total_pairs_to_find:
				EventManager.emit_event("all_pairs_found")
				print("GameManager: All pairs found! Congratulations!")
		else:
			EventManager.emit_event("mismatch_attempt")
			print("GameManager: Mismatch detected.")
			_first_flipped_card.flip_back()
			_second_flipped_card.flip_back()

		_finalize_turn()
	)

## Resets state & re-enables interaction after each turn.
func _finalize_turn() -> void:
	_clear_card_selection()
	_can_flip_cards = true
	_set_interaction_on_other_cards(false)

## Clears the references to the currently flipped cards.
func _clear_card_selection() -> void:
	_first_flipped_card = null
	_second_flipped_card = null

## Returns true if the player is currently allowed to flip cards.
func can_player_flip_card() -> bool:
	return _can_flip_cards

## Checks if the given card is the only card currently flipped by the user.
func is_this_the_only_user_flipped_card(card_to_check: CardScript) -> bool:
	return _first_flipped_card == card_to_check and _second_flipped_card == null

## Disables or enables interaction for all cards not currently selected or matched.
func _set_interaction_on_other_cards(p_disable: bool) -> void:
	if card_area == null:
		printerr("GameManager: _set_interaction_on_other_cards - card_area is null")
		return
	var card_container: GridContainer = card_area.get_node_or_null("GridContainer")
	if card_container == null:
		printerr("GameManager: _set_interaction_on_other_cards - GridContainer not found")
		return

	for child in card_container.get_children():
		if child is CardScript:
			var card: CardScript = child
			if not card.is_matched and card != _first_flipped_card and card != _second_flipped_card:
				card.disabled = p_disable
				# Optional: Visual cue for disabled state can be added here if desired.
				# e.g., card.modulate = Color(0.7, 0.7, 0.7) if p_disable else Color.WHITE
