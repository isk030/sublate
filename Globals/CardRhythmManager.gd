extends Node

# Configuration
@export var bpm: float = 120.0
@export var cards_to_highlight: int = 2  # Number of cards to highlight each beat (2-3)
@export var highlight_duration: float = 0.3  # How long the highlight should last in seconds
@export var highlight_color: Color = Color(1.0, 0.2, 0.2, 0.7)  # Rot mit Transparenz

# Debug
@export var debug_mode: bool = true

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
	# Wait for the game to be ready
	game_manager = get_node("/root/GameManager")
	if not game_manager:
		printerr("CardRhythmManager: GameManager not found!")
		return
	print("CardRhythmManager: Found GameManager")

	# Wait a few frames to ensure everything is initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("GameManager card_area: ", game_manager.card_area)
	
	# Try to get the card container
	if game_manager.card_area:
		card_container = game_manager.card_area.get_node_or_null("GridContainer")
		print("Card container found: ", card_container != null)
	else:
		printerr("CardRhythmManager: Card area is null!")
		return
	
	if not card_container:
		printerr("CardRhythmManager: GridContainer not found in card area!")
		# Try to find the GridContainer in the scene
		card_container = get_tree().get_root().find_child("GridContainer", true, false)
		if card_container:
			print("Found GridContainer in scene tree")
		else:
			printerr("Could not find GridContainer anywhere!")
	
	# Initialize timers
	highlight_timer = Timer.new()
	highlight_timer.one_shot = true
	highlight_timer.timeout.connect(_on_highlight_timeout)
	add_child(highlight_timer)
	
	beat_timer = Timer.new()
	beat_timer.timeout.connect(_on_beat)
	add_child(beat_timer)
	
	# Start the beat
	start_beat()

func start_beat() -> void:
	if beat_timer.is_stopped():
		var beat_interval: float = 60.0 / bpm
		beat_timer.wait_time = beat_interval
		beat_timer.start()
		# Trigger first beat immediately
		_on_beat()

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

func _on_beat() -> void:
	if debug_mode:
		print("\n--- New Beat ---")
		
	if not card_container or not is_instance_valid(card_container):
		printerr("CardRhythmManager: Card container not found or invalid!")
		return
	
	# Clear any existing highlights
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
	if valid_cards.size() < cards_to_highlight:
		if debug_mode:
			print("Not enough valid cards to highlight (need ", cards_to_highlight, ")")
		return
	
	# Select random cards
	valid_cards.shuffle()
	var cards_to_highlight_this_beat = min(cards_to_highlight, valid_cards.size())
	highlighted_cards = valid_cards.slice(0, cards_to_highlight_this_beat)
	
	# Apply red highlight to cards
	for card in highlighted_cards:
		if card is CanvasItem and is_instance_valid(card):
			# Speichere die ursprüngliche Modulate-Farbe
			if not card.has_meta("original_modulate"):
				card.set_meta("original_modulate", card.modulate)
			# Wende die rote Färbung an
			card.modulate = highlight_color
			if debug_mode:
				print("Highlighted card: ", card.name)
	
	# Set timer to clear highlights
	highlight_timer.start(highlight_duration)

func _on_highlight_timeout() -> void:
	_clear_highlights()

func _clear_highlights() -> void:
	for card in highlighted_cards:
		if is_instance_valid(card) and card is CanvasItem:
			# Stelle die ursprüngliche Farbe wieder her
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
