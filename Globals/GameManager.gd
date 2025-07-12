extends Node

# Class References
const CardRhythmManager = preload("res://Globals/CardRhythmManager.gd")

# References
var card_rhythm_manager: Node = null

# Constants
const DELAY_TIME: float = 1.0
const CARD_PAIR_COUNT: int = 8
const DEFAULT_CARD_AREA_SIZE: int = 2 * CARD_PAIR_COUNT
const CARD_GRID_COLUMNS: int = int(ceil(sqrt(float(DEFAULT_CARD_AREA_SIZE))))
const MINIMUM_CARD_SIZE: int = 200

# Dependencies
@onready var _card_script = preload("res://Globals/Card.gd")

# Exported variables
@export var card_area: Control
@export var card_back_tex: Texture2D = preload("res://assets/cards/level_select_frame_128.png")

# Private variables
var _available_textures: Array[Texture2D] = []
var _state = GameState.States.FIRST
var _first_flipped_card = null
var _second_flipped_card = null
var _pairs_found: int = 0
var _total_pairs_to_find: int = 0

# Engine ready
func _ready() -> void:
	# Add self to GameManager group for better discovery
	add_to_group("GameManager")
	
	# Initialize random number generator
	randomize()
	
	# Look up the singleton CardRhythmManager (should be provided via autoload or scene)
	card_rhythm_manager = get_node_or_null("/root/CardRhythmManager")
	if card_rhythm_manager:
		print("Found existing CardRhythmManager (singleton)")
		card_rhythm_manager.debug_mode = true
		# Ensure it's in the RhythmManager group for others to find
		if not card_rhythm_manager.is_in_group("RhythmManager"):
			card_rhythm_manager.add_to_group("RhythmManager")
	else:
		printerr("GameManager: CardRhythmManager singleton not found! Please add it as Autoload or child of root.")

# Helper function to print the path after the node is added
func _print_rhythm_manager_path() -> void:
	if card_rhythm_manager:
		print("CardRhythmManager path: ", card_rhythm_manager.get_path())
	else:
		print("CardRhythmManager not found after creation")
	
	# Connect signals
	if card_rhythm_manager.has_signal("card_flipped_in_rhythm"):
		if not card_rhythm_manager.card_flipped_in_rhythm.is_connected(_on_card_flipped_in_rhythm):
			card_rhythm_manager.card_flipped_in_rhythm.connect(_on_card_flipped_in_rhythm)
	else:
		printerr("CardRhythmManager is missing the 'card_flipped_in_rhythm' signal")
	
	# Initialize random number generator with a fixed seed for reproducible results
	var random_seed = 42
	seed(random_seed)
	print("Zufallsgenerator initialisiert mit Seed: ", random_seed)
	
	# Warte bis der nächste Frame gerendert wurde
	await get_tree().process_frame
	reset_game()  # Dies ruft init_player_panel() auf

# Public API
func reset_game() -> void:
	_reset_texture_pool()
	if card_area and is_instance_valid(card_area):
		init_game_elements()
	# Verwende die neue reset_game-Funktion des ScoreManagers
	if ScoreManager:
		ScoreManager.reset_game()
	else:
		init_player_panel()  # Fallback für Abwärtskompatibilität

# Store reference to UI container
func set_card_area_ref(area_node: Control) -> void:
	card_area = area_node

# Prepare pool with pairs using TextureLoader
func _reset_texture_pool() -> void:
	_pairs_found = 0
	_state = GameState.States.FIRST
	var unique_needed: int = int(DEFAULT_CARD_AREA_SIZE / 2.0)
	_total_pairs_to_find = unique_needed
	_available_textures = TextureLoader.create_texture_pool(unique_needed)

# Get next texture
func get_random_unique_texture() -> Texture2D:
	if _available_textures.is_empty():
		_reset_texture_pool()
		if _available_textures.is_empty():
			return null
	return _available_textures.pop_back()

# Build board
func init_game_elements() -> void:
	if not card_area:
		return
	var grid: GridContainer = card_area.get_node("GridContainer")
	grid.columns = CARD_GRID_COLUMNS
	for c in grid.get_children():
		c.queue_free()
	for _i in range(DEFAULT_CARD_AREA_SIZE):
		_init_single_card(grid)

# Public: reset score labels via ScoreManager
func init_player_panel() -> void:
	if ScoreManager:
		ScoreManager.reset_score_panel()

# Create and add one card
func _init_single_card(card_container: GridContainer) -> void:
	var new_card = _card_script.new()
	new_card.stretch_mode = TextureButton.STRETCH_SCALE
	new_card.custom_minimum_size = Vector2(MINIMUM_CARD_SIZE, MINIMUM_CARD_SIZE)

	var card_face_tex: Texture2D = get_random_unique_texture()
	if card_face_tex == null:
		push_error("Card face texture is missing. Cannot initialize card without a face texture.")
		return

	new_card.initialize(card_face_tex, card_face_tex, card_back_tex)
	new_card.flipped.connect(_on_card_flipped)
	card_container.add_child(new_card)

# Handle first/second flip
func _on_card_flipped(card) -> void:
	if _state == GameState.States.PAUSE or card.is_matched:
		return
	if _state == GameState.States.FIRST:
		_first_flipped_card = card
		_state = GameState.States.SECOND
		return
	_second_flipped_card = card
	_state = GameState.States.PAUSE
	_set_interaction_on_other_cards(true)
	_evaluate_pair()

# Evaluate pair after delay
func _evaluate_pair() -> void:
	var is_match: bool = _first_flipped_card.card_identifier == _second_flipped_card.card_identifier
	var timer := get_tree().create_timer(DELAY_TIME)
	print("\n--- Evaluating pair ---")
	print("First card (", _first_flipped_card.name, ") was in rhythm: ", _first_flipped_card.was_flipped_in_rhythm)
	print("Second card (", _second_flipped_card.name, ") was in rhythm: ", _second_flipped_card.was_flipped_in_rhythm)
	print("First card modulate: ", _first_flipped_card.modulate)
	print("Second card modulate: ", _second_flipped_card.modulate)
	if card_rhythm_manager:
		print("Highlight color: ", card_rhythm_manager.highlight_color)
	
	timer.timeout.connect(func():
		if not (is_instance_valid(_first_flipped_card) and is_instance_valid(_second_flipped_card)):
			_finalize_turn()
			return

		# Check for heat bonus (both cards flipped in rhythm)
		var heat_bonus: int = 0
		if _first_flipped_card.was_flipped_in_rhythm and _second_flipped_card.was_flipped_in_rhythm:
			heat_bonus = 100
			print("HEAT BONUS! +100 points for perfect rhythm!")
			EventManager.emit_event("heat_bonus", {"bonus": heat_bonus})
		else:
			print("No heat bonus - one or both cards not flipped in rhythm")
		
		if is_match:
			print("Cards match! Applying points...")
			_first_flipped_card.mark_matched()
			_second_flipped_card.mark_matched()
			_pairs_found += 1
			# Show passive buff +10 on previously matched cards
			if card_area:
				var grid := card_area.get_node_or_null("GridContainer")
				if grid:
					for child in grid.get_children():
						if child.get_script() == _card_script and child != _first_flipped_card and child != _second_flipped_card and child.is_matched:
							if child.has_method("show_points"):
								child.show_points(10)
			print("Emitting pair_found event with heat_bonus: ", heat_bonus)
			EventManager.emit_event("pair_found", {
				"pairs_found": _pairs_found,
				"total_pairs": _total_pairs_to_find,
				"heat_bonus": heat_bonus
			})
			
			if _pairs_found == _total_pairs_to_find:
				EventManager.emit_event("all_pairs_found")
		else:
			EventManager.emit_event("mismatch_attempt")
			_first_flipped_card.flip_down()
			_second_flipped_card.flip_down()

		_finalize_turn())

# Reset turn
func _finalize_turn() -> void:
	_clear_card_selection()
	_state = GameState.States.FIRST
	_set_interaction_on_other_cards(false)

func _clear_card_selection() -> void:
	_first_flipped_card = null
	_second_flipped_card = null

# Enable/disable non-selected cards
func _set_interaction_on_other_cards(p_disable: bool) -> void:
	if card_area == null:
		printerr("GameManager: _set_interaction_on_other_cards - card_area is null")
		return
	var card_container: GridContainer = card_area.get_node_or_null("GridContainer")
	if card_container == null:
		printerr("GameManager: _set_interaction_on_other_cards - GridContainer not found")
		return

	for child in card_container.get_children():
		if child.get_script() == _card_script:
			var card = child
			if not card.is_matched and card != _first_flipped_card and card != _second_flipped_card:
				card.disabled = p_disable

func can_player_flip_card() -> bool:
	return _state != GameState.States.PAUSE

func _on_card_flipped_in_rhythm(card: Node) -> void:
	print("Perfect rhythm! Card flipped at the right time: ", card.card_identifier if card else "unknown")

# Setzt ein zufällig ausgewähltes, bereits gefundenes Kartenpaar zurück
# (für das Inventar-Item "Stap Scratch")
func reset_random_matched_pair() -> bool:
	print("Versuche, ein zufälliges gefundenes Kartenpaar zurückzusetzen...")
	if card_area == null:
		printerr("GameManager: reset_random_matched_pair - card_area is null")
		return false
		
	var card_container: GridContainer = card_area.get_node_or_null("GridContainer")
	if card_container == null:
		printerr("GameManager: reset_random_matched_pair - GridContainer not found")
		return false
	
	# Sammle alle gematchten Karten
	var matched_cards = []
	for child in card_container.get_children():
		if child.get_script() == _card_script and child.is_matched:
			matched_cards.append(child)
	
	# Wenn keine gematchten Karten gefunden wurden, können wir nichts zurücksetzen
	if matched_cards.size() < 2:
		print("Keine gematchten Kartenpaare gefunden!")
		return false
	
	# Gruppiere die Karten nach ihren IDs
	var card_groups = {}
	for card in matched_cards:
		if not card_groups.has(card.card_identifier):
			card_groups[card.card_identifier] = []
		card_groups[card.card_identifier].append(card)
	
	# Wähle ein zufälliges Paar aus
	var card_ids = card_groups.keys()
	if card_ids.is_empty():
		return false
		
	var random_id = card_ids[randi() % card_ids.size()]
	var pair_cards = card_groups[random_id]
	
	# Stelle sicher, dass wir ein Paar haben
	if pair_cards.size() != 2:
		print("Unerwartete Anzahl von Karten mit gleicher ID: ", pair_cards.size())
		return false
	
	print("Setze Kartenpaar mit ID ", random_id, " zurück")
	
	# Setze die Karten zurück
	for card in pair_cards:
		card.unmark_matched() # Diese Methode muss in Card.gd implementiert werden
		card.flip_down()
	
	# Reduziere die Anzahl der gefundenen Paare
	_pairs_found -= 1
	
	# Sende ein Event, dass ein Paar zurückgesetzt wurde
	EventManager.emit_event("pair_reset", {
		"card_id": random_id,
		"pairs_found": _pairs_found,
		"total_pairs": _total_pairs_to_find
	})
	
	return true
