extends Node
class_name CardRhythmManager

# Singleton instance tracking
static var instance: CardRhythmManager = null
static var instance_count: int = 0

# Signals
signal card_flipped_in_rhythm(card)

# Configuration
@export var bpm: float = 95.0  # Geschwindigkeit des Beats
# Immer genau 2 Karten hervorheben
const CARDS_TO_HIGHLIGHT: int = 2
@export var highlight_duration: float = 0.5  # Dauer der Hervorhebung
@export var highlight_color: Color = Color(1.5, 1.5, 1.5)  # Farbe der Hervorhebung
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
var instance_id: int = 0
var _is_processing_beat: bool = false
var _beat_in_progress: bool = false
var _last_beat_time: float = 0.0

func _init():
	# Track instance creation
	instance_count += 1
	instance_id = instance_count
	if instance == null:
		instance = self
	if debug_mode:
		print("CardRhythmManager _init() - Instance ID: ", instance_id, ", Total instances: ", instance_count)

func _enter_tree():
	if debug_mode:
		print("CardRhythmManager _enter_tree() - Instance ID: ", instance_id)
	if instance != self:
		if debug_mode:
			printerr("Multiple CardRhythmManager instances detected! Instance ID: ", instance_id)
		queue_free()
		return

func _ready() -> void:
	if debug_mode:
		print("CardRhythmManager _ready() - Instance ID: ", instance_id)
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
		
	# Berechne das Intervall in Sekunden basierend auf BPM
	# 60 Sekunden / BPM = Intervall in Sekunden
	var beat_interval: float = 60.0 / bpm
	
	if debug_mode:
		print("Starting beat with interval: ", beat_interval, " seconds (BPM: ", bpm, ")")
	
	# Timer zurücksetzen und konfigurieren
	beat_timer.stop()
	beat_timer.wait_time = beat_interval
	beat_timer.one_shot = false  # Für wiederholte Ausführung
	beat_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS  # Präzisere Zeitsteuerung
	
	# Sicherstellen, dass die Verbindung nur einmal hergestellt wird
	if beat_timer.timeout.get_connections().size() == 0:
		beat_timer.timeout.connect(_on_beat, CONNECT_DEFERRED)
	
	# Timer starten
	beat_timer.start()
	
	# Ersten Beat sofort auslösen, aber mit einer kleinen Verzögerung,
	# um sicherzustellen, dass alles korrekt initialisiert ist
	call_deferred("call_deferred", "_on_beat")

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
	var current_time = Time.get_ticks_msec()
	var time_since_last_beat = (current_time - _last_beat_time) / 1000.0
	
	if _is_processing_beat or _beat_in_progress:
		if debug_mode:
			print("Beat processing already in progress (is_processing: ", _is_processing_beat, 
				", beat_in_progress: ", _beat_in_progress, "), skipping this beat")
		return
	
	if not is_inside_tree():
		if debug_mode:
			print("Not in tree yet, deferring beat processing")
		call_deferred("_on_beat")  # Try again next frame
		return
	
	# Safety check - don't process beats too close together
	if time_since_last_beat < 0.1:  # 100ms minimum between beats
		if debug_mode:
			print("Beat too soon after last one (", time_since_last_beat, "s), skipping")
		return
	
	_is_processing_beat = true
	_beat_in_progress = true
	_last_beat_time = current_time
	
	if debug_mode:
		print("\n--- New Beat (Time: ", current_time / 1000.0, ")")
		print("Instance ID: ", instance_id, ", Time since last beat: ", time_since_last_beat, "s")
		print("Current highlighted cards: ", highlighted_cards.size())
	
	# Bestehende Hervorhebungen entfernen
	_clear_highlights()
	
	# Sicherstellen, dass der Card-Container gültig ist
	if not card_container or not is_instance_valid(card_container):
		card_container = get_tree().get_root().find_child("GridContainer", true, false)
		if not card_container or not is_instance_valid(card_container):
			if debug_mode:
				printerr("CardRhythmManager: Card container not found or invalid!")
			_is_processing_beat = false
			return
	
	# Gültige Karten sammeln (nicht gefunden und nicht aufgedeckt)
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
	
	# Wenn nicht genügend Karten vorhanden sind oder nur noch 2 oder weniger Karten übrig sind, nichts tun
	if valid_cards.size() <= CARDS_TO_HIGHLIGHT:
		if debug_mode:
			print("Not enough valid cards to highlight (need more than ", CARDS_TO_HIGHLIGHT, ")")
		_is_processing_beat = false
		_beat_in_progress = false
		return
	
	# Zufallsgenerator mit aktuellem Seed initialisieren
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(random_seed) + str(Time.get_ticks_msec() / 1000.0))
	
	# Karten mischen mit Fisher-Yates Shuffle
	for i in range(valid_cards.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = valid_cards[i]
		valid_cards[i] = valid_cards[j]
		valid_cards[j] = temp
	
	# Nur die ersten CARDS_TO_HIGHLIGHT Karten auswählen
	highlighted_cards.clear()
	for i in range(min(CARDS_TO_HIGHLIGHT, valid_cards.size())):
		var card = valid_cards[i]
		if card and is_instance_valid(card):
			highlighted_cards.append(card)
	
	if debug_mode:
		print("Selected ", highlighted_cards.size(), " cards to highlight")
	
	# Sicherstellen, dass wir nicht mehr als CARDS_TO_HIGHLIGHT Karten haben
	if highlighted_cards.size() > CARDS_TO_HIGHLIGHT:
		printerr("Too many cards selected: ", highlighted_cards.size())
		highlighted_cards = highlighted_cards.slice(0, CARDS_TO_HIGHLIGHT)
	
	# Hervorheben der ausgewählten Karten
	for card in highlighted_cards:
		if card is CanvasItem:
			# Originalfarbe speichern, falls noch nicht geschehen
			if not card.has_meta("original_modulate"):
				card.set_meta("original_modulate", card.modulate)
			# Hervorhebungsfarbe anwenden
			card.modulate = highlight_color
			if debug_mode:
				print("Highlighted card: ", card.name)
	
	# Timer zum Entfernen der Hervorhebungen starten
	if not highlight_timer:
		printerr("Highlight timer is not initialized!")
		_is_processing_beat = false
		_beat_in_progress = false
		return
	
	# Stoppe den Timer und entferne alle ausstehenden Timeout-Signale
	highlight_timer.stop()
	
	# Warte bis zum nächsten Frame, um sicherzustellen, dass alle ausstehenden Timeouts verarbeitet wurden
	await get_tree().process_frame
	
	# Starte den Timer neu
	highlight_timer.start(highlight_duration)
	
	if debug_mode:
		print("Started highlight timer for ", highlight_duration, " seconds")
		
		# Debug-Ausgabe nach dem Hervorheben
		if highlighted_cards.size() > 0:
			var card_names = []
			for card in highlighted_cards:
				if is_instance_valid(card):
					card_names.append(card.name)
			print("Successfully highlighted ", card_names.size(), " cards: ", ", ".join(card_names))
		else:
			print("No cards were highlighted this beat")

	# Reset processing flags
	_is_processing_beat = false
	_beat_in_progress = false
	
	if debug_mode:
		print("Beat processing completed at ", Time.get_ticks_msec() / 1000.0)
	
	_is_processing_beat = false

func _on_highlight_timeout() -> void:
	if debug_mode:
		print("Highlight timeout triggered, clearing highlights...")
	_clear_highlights()
	if debug_mode:
		print("Highlights cleared after timeout")

func is_card_highlighted(card: Node) -> bool:
	var is_highlighted = card in highlighted_cards
	if debug_mode:
		print("Checking if card ", card.name, " is highlighted:", is_highlighted)
		print("Current highlighted cards: ", highlighted_cards)
	return is_highlighted

func _clear_highlights() -> void:
	var _start_time = Time.get_ticks_msec() if debug_mode else 0
	var cards_cleared = 0
	
	if debug_mode:
		print("Clearing highlights from ", highlighted_cards.size(), " cards")
	
	# Create a copy of cards to clear for debugging
	var cards_to_clear = highlighted_cards.duplicate()
	
	# Process all currently highlighted cards in reverse order
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
					cards_cleared += 1
					if debug_mode:
						print("Removed highlight from card: ", card.name)
		else:
			if debug_mode:
				print("Card is not a CanvasItem: ", card.name)

	# Clear the array after processing all cards
	highlighted_cards.clear()
	
	# Debug: Check if all cards were properly cleared
	if debug_mode:
		for card in cards_to_clear:
			if is_instance_valid(card) and card is CanvasItem and card.modulate == highlight_color:
				printerr("Card still has highlight color after clear: ", card.name)
		
		var clear_time = (Time.get_ticks_msec() - _start_time) / 1000.0
		print("Cleared ", cards_cleared, " cards in ", clear_time, "s")

func set_bpm(new_bpm: float) -> void:
	if new_bpm > 0:
		bpm = new_bpm
		if beat_timer and not beat_timer.is_stopped():
			start_beat()  # Restart with new BPM
