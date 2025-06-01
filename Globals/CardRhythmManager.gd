extends Node

# Signals
signal card_flipped_in_rhythm(card)

# Configuration
@export var bpm: float = 95.0  # Geschwindigkeit des Beats
# Immer genau 2 Karten hervorheben
const CARDS_TO_HIGHLIGHT: int = 2
@export var highlight_duration: float = 0.5  # Dauer der Hervorhebung
@export var highlight_color: Color = Color(1.0, 0.2, 0.2, 0.7)  # Farbe der Hervorhebung
@export var random_seed: int = 42  # Fester Seed für Reproduzierbarkeit

# Debug
@export var debug_mode: bool = true  # Set to true to see debug messages

# References
@onready var game_manager: Node = get_node("/root/GameManager") if get_node_or_null("/root/GameManager") else null
var card_container: GridContainer = null
var highlight_timer: Timer = null
var beat_timer: Timer = null

# Internal state
var cards: Array = []
var highlighted_cards: Array = []

func _ready() -> void:
	print("CardRhythmManager: Initializing...")
	print("Debug mode: ", debug_mode)
	
	# Timer zuerst initialisieren
	highlight_timer = Timer.new()
	highlight_timer.one_shot = true
	highlight_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(highlight_timer)
	highlight_timer.timeout.connect(_on_highlight_timeout, CONNECT_DEFERRED)
	
	beat_timer = Timer.new()
	beat_timer.one_shot = false
	beat_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(beat_timer)
	
	# Warten, bis der Node im Szenenbaum ist
	await get_tree().process_frame
	
	# GameManager suchen
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		printerr("CardRhythmManager: GameManager not found!")
		return
		
	print("CardRhythmManager: Found GameManager at ", game_manager.get_path())
	
	# Auf Initialisierung des GameManagers warten
	if game_manager.has_method("is_initialized") and not game_manager.is_initialized:
		await game_manager.initialized
	
	# Zusätzliche Frames warten, um sicherzustellen, dass alles initialisiert ist
	await get_tree().process_frame
	await get_tree().process_frame
	
	if not is_instance_valid(game_manager) or not is_inside_tree():
		printerr("CardRhythmManager: GameManager or self no longer valid!")
		return
	
	# Karten-Container finden
	if game_manager.has_signal("card_area_ready"):
		await game_manager.card_area_ready
	
	if game_manager.card_area:
		card_container = game_manager.card_area.get_node_or_null("GridContainer")
		print("Card container found: ", card_container != null)
	else:
		printerr("CardRhythmManager: Card area is null!")
		return
	
	if not card_container:
		printerr("CardRhythmManager: GridContainer not found in card area!")
		card_container = get_tree().get_root().find_child("GridContainer", true, false)
		if card_container:
			print("Found GridContainer in scene tree")
		else:
			printerr("Could not find GridContainer anywhere!")
			return

	# Signal verbinden
	if not card_flipped_in_rhythm.is_connected(_on_card_flipped_in_rhythm):
		card_flipped_in_rhythm.connect(_on_card_flipped_in_rhythm, CONNECT_DEFERRED)
	
	# Beat starten
	print("Starting beat timer...")
	call_deferred("start_beat")

func start_beat() -> void:
	if not beat_timer:
		printerr("Beat timer not initialized!")
		return
		
	var beat_interval: float = 60.0 / bpm
	if debug_mode:
		print("Starting beat with interval: ", beat_interval, " seconds (BPM: ", bpm, ")")
	
	beat_timer.stop()  # Sicherstellen, dass der Timer gestoppt ist
	beat_timer.wait_time = beat_interval
	beat_timer.one_shot = false  # Wichtig für wiederholte Ausführung
	beat_timer.autostart = false
	beat_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS  # Präzisere Timer
	
	if not beat_timer.is_connected("timeout", _on_beat):
		beat_timer.timeout.connect(_on_beat, CONNECT_DEFERRED)
	
	beat_timer.start()
	# Ersten Beat sofort auslösen
	call_deferred("_on_beat")

func stop_beat() -> void:
	if beat_timer:
		beat_timer.stop()
	if highlight_timer:
		highlight_timer.stop()
	# Clear any active highlights
	_clear_highlights()

func _is_card_valid(card: Node) -> bool:
	if not card or not is_instance_valid(card):
		return false
	
	# Check if card is matched
	var is_matched = false
	if card.has_method("is_matched"):
		is_matched = card.is_matched if typeof(card.is_matched) == TYPE_BOOL else false
	
	# Check if card is face up
	var is_face_up = false
	if card.has_method("is_face_up"):
		var face_up_result = card.call("is_face_up")
		is_face_up = face_up_result if typeof(face_up_result) == TYPE_BOOL else false
	
	if debug_mode:
		print("Card ", card.name, ": matched=", is_matched, ", face_up=", is_face_up)
	
	return not is_matched and not is_face_up

# Called when a card is flipped in rhythm
func _on_card_flipped_in_rhythm(card: Node) -> void:
	if card and card.has_method("set"):
		print("Setting was_flipped_in_rhythm to TRUE for card: ", card.name)
		card.was_flipped_in_rhythm = true
		if debug_mode:
			print("Card ", card.name, " was flipped in rhythm!")
	else:
		print("WARNING: Invalid card in _on_card_flipped_in_rhythm: ", card)

func _on_beat() -> void:
	if not is_inside_tree():
		return
		
	if debug_mode:
		print("\n--- New Beat (Time: ", Time.get_ticks_msec() / 1000.0, ") ---")
		print("CardRhythmManager: Starting new beat, current highlighted cards: ", highlighted_cards.size())
		
	if not card_container or not is_instance_valid(card_container):
		if debug_mode:
			printerr("CardRhythmManager: Card container not found or invalid!")
		return
		
	# Sicherstellen, dass wir im Haupt-Thread arbeiten
	if not is_inside_tree():
		call_deferred("_on_beat")
		return
		
	# Random Seed setzen für konsistente Ergebnisse
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(random_seed) + str(Time.get_ticks_msec() / 1000.0))
	
	# Clear any existing highlights first
	_clear_highlights()
	
	# Get all valid cards (not matched and not already face up)
	var valid_cards: Array[Node] = []
	var total_children = card_container.get_child_count()
	
	if debug_mode:
		print("Checking ", total_children, " cards in container")
	
	for i in range(total_children):
		var card = card_container.get_child(i)
		if _is_card_valid(card):
			valid_cards.append(card)
	
	if debug_mode:
		print("Found ", valid_cards.size(), " valid cards out of ", total_children)
	
	# If not enough cards, do nothing
	if valid_cards.size() < CARDS_TO_HIGHLIGHT:
		if debug_mode:
			print("Not enough valid cards to highlight (need ", CARDS_TO_HIGHLIGHT, ")")
		return
	
	# Sicherstellen, dass wir genügend Karten haben
	if valid_cards.size() < CARDS_TO_HIGHLIGHT:
		if debug_mode:
			print("Not enough valid cards to highlight (need ", CARDS_TO_HIGHLIGHT, ")")
		return
	
	if debug_mode:
		print("Highlighting ", CARDS_TO_HIGHLIGHT, " cards this beat")
	
	# Clear any existing highlights first
	_clear_highlights()
	highlighted_cards.clear()
	
	# Mischen der gültigen Karten mit Fisher-Yates Shuffle
	var shuffled_cards = valid_cards.duplicate()
	for i in range(shuffled_cards.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = shuffled_cards[i]
		shuffled_cards[i] = shuffled_cards[j]
		shuffled_cards[j] = temp
	
	# Nur die ersten 2 Karten auswählen
	shuffled_cards.resize(CARDS_TO_HIGHLIGHT)
	
	# Die ausgewählten Karten hervorheben
	var has_valid_cards = false
	for card in shuffled_cards:
		if card and is_instance_valid(card):
			has_valid_cards = true
			highlighted_cards.append(card)
			
			# Apply red highlight to card
			if card is CanvasItem:
				# Save the original color if not already saved
				if not card.has_meta("original_modulate"):
					card.set_meta("original_modulate", card.modulate)
				# Apply highlight color
				card.modulate = highlight_color
				if debug_mode:
					print("Highlighted card: ", card.name)
	
	if not has_valid_cards and debug_mode:
		print("No valid cards to highlight")
	
	# Set timer to clear highlights
	highlight_timer.start(highlight_duration)
	
	# Debug output
	if debug_mode:
		var card_names = []
		for card in highlighted_cards:
			if is_instance_valid(card):
				card_names.append(card.name)
		print("Cards currently highlighted (", highlighted_cards.size(), "): ", card_names)

func _on_highlight_timeout() -> void:
	_clear_highlights()

func is_card_highlighted(card: Node) -> bool:
	var is_highlighted = card in highlighted_cards
	if debug_mode:
		print("Checking if card ", card.name, " is highlighted:", is_highlighted)
		print("Current highlighted cards: ", highlighted_cards)
	return is_highlighted

func _clear_highlights() -> void:
	if debug_mode:
		print("Clearing highlights from ", highlighted_cards.size(), " cards")
	
	# Process all currently highlighted cards
	for i in range(highlighted_cards.size() - 1, -1, -1):
		var card = highlighted_cards[i]
		if not is_instance_valid(card):
			highlighted_cards.remove_at(i)
			continue
			
		if card is CanvasItem:
			# Restore original color if available
			if card.has_meta("original_modulate"):
				var original_color = card.get_meta("original_modulate")
				if original_color is Color:
					card.modulate = original_color
					if debug_mode:
						print("Removed highlight from card: ", card.name)
	
	# Clear the array after processing all cards
	highlighted_cards.clear()

func set_bpm(new_bpm: float) -> void:
	if new_bpm > 0:
		bpm = new_bpm
		if beat_timer and not beat_timer.is_stopped():
			start_beat()  # Restart with new BPM
