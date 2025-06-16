extends TextureButton

# Signals
signal flipped(card)
signal matched(card)
signal state_changed(card, is_face_up: bool)

@export var card_identifier: Variant = null
@export var face_texture: Texture2D = null
@export var back_texture: Texture2D = null
@export var matched_texture: Texture2D = preload("res://Globals/TextureLoader.gd").get_matched_texture()

# Preload floating label helper
const FloatingLabel = preload("res://Globals/FloatingLabel.gd")

var _is_face_up: bool = false
var _is_matched: bool = false
var was_flipped_in_rhythm: bool = false

# Compatibility property for legacy code (read-only)
var is_matched: bool:
	get: return _is_matched

# ------------------------------------------------------------------ #
# Public API                                                         #
# ------------------------------------------------------------------ #

# One-time setup after instancing the card.
func initialize(id: Variant, p_face: Texture2D, p_back: Texture2D) -> void:
	card_identifier = id
	face_texture = p_face
	back_texture = p_back
	_reset_visual()

# Flip the card to show its face. When user-initiated, a signal is emitted.
func flip_up(user_initiated: bool = false) -> void:
	if _is_face_up or _is_matched:
		return
	_is_face_up = true
	texture_normal = face_texture
	state_changed.emit(self, true)
	if user_initiated:
		flipped.emit(self)
		EventManager.emit_event("card_flipped_by_user", self)

# Flip the card back to its backside.
func flip_down() -> void:
	if not _is_face_up or _is_matched:
		return
	_is_face_up = false
	was_flipped_in_rhythm = false  # Reset the flag when flipping down
	texture_normal = back_texture
	state_changed.emit(self, false)
	disabled = false # Re-enable interaction

# Locks the card in matched state and shows highlight frame.
func mark_matched() -> void:
	if _is_matched:
		return
	_is_matched = true
	texture_normal = matched_texture
	disabled = true
	matched.emit(self)
	show_points(50, Color.DARK_GREEN, true)

func is_face_up() -> bool:
	return _is_face_up

# ------------------------------------------------------------------ #
# Engine callbacks                                                   #
# ------------------------------------------------------------------ #

func _ready() -> void:
	toggle_mode = false
	pressed.connect(_on_pressed)
	_reset_visual()

# ------------------------------------------------------------------ #
# Internal helpers                                                   #
# ------------------------------------------------------------------ #

# Spawn a floating text at the card's position indicating points earned
func _center_floating_label(flbl: Control) -> void:
	if not is_instance_valid(flbl):
		return
	flbl.position = (size - flbl.size) / 2

#
func show_points(points: int, p_color: Color = Color.WHITE, p_bold: bool = false) -> void:
	var lbl := FloatingLabel.new()
	lbl.text = "+" + str(points)
	lbl.start_color = p_color
	lbl.bold = p_bold
	add_child(lbl)
	# Center within card
	# reset anchors to top-left so we can place via position
	lbl.anchor_left = 0
	lbl.anchor_top = 0
	lbl.anchor_right = 0
	lbl.anchor_bottom = 0
	# defer centering until label has size
	call_deferred("_center_floating_label", lbl)
	lbl.start()



func _on_pressed() -> void:
	if GameManager and not GameManager.can_player_flip_card():
		return
	
	# First, reset the rhythm flag
	was_flipped_in_rhythm = false
	
	# INTENSIVE DIAGNOSE für CardRhythmManager-Zugriff
	print("\n===========================================")
	print("CARD DIAGNOSE: " + name + " sucht CardRhythmManager")
	
	# Variablen für die Diagnose
	var rhythm_manager = null
	var game_manager = null
	
	# 1. Direkt im Szenenbaum suchen
	rhythm_manager = get_node_or_null("/root/CardRhythmManager")
	print("1. Direkt im Szenenbaum gefunden: ", rhythm_manager != null)
	
	# 2. Über GameManager suchen
	game_manager = get_node_or_null("/root/GameManager")
	print("2. GameManager gefunden: ", game_manager != null)
	
	if game_manager:
		print("   GameManager hat card_rhythm_manager: ", game_manager.has_method("_setup_rhythm_manager"))
		print("   GameManager.card_rhythm_manager = ", game_manager.card_rhythm_manager)
		
		if game_manager and game_manager.card_rhythm_manager:
			print("   GameManager.card_rhythm_manager vorhanden!")
			rhythm_manager = game_manager.card_rhythm_manager
			
			# Wenn wir den GameManager haben, aber keinen CardRhythmManager, initialisieren
			if not rhythm_manager and game_manager.has_method("_setup_rhythm_manager"):
				print("   Initialisiere CardRhythmManager...")
				game_manager._setup_rhythm_manager()
				rhythm_manager = game_manager.card_rhythm_manager
	
	# 3. Über die Gruppe suchen
	if not rhythm_manager and get_tree():
		var rhythm_managers = get_tree().get_nodes_in_group("RhythmManager")
		print("3. RhythmManager-Gruppe Anzahl: ", rhythm_managers.size())
		if rhythm_managers.size() > 0:
			rhythm_manager = rhythm_managers[0]
		
	# FINALE DIAGNOSE
	print("CardRhythmManager gefunden: ", rhythm_manager != null)
	if rhythm_manager:
		print("CardRhythmManager Methoden:")
		print("  - has_signal('card_flipped_in_rhythm'): ", rhythm_manager.has_signal("card_flipped_in_rhythm"))
		print("  - has_method('is_card_highlighted'): ", rhythm_manager.has_method("is_card_highlighted"))
		print("  - debug_mode: ", rhythm_manager.debug_mode if "debug_mode" in rhythm_manager else "nicht gefunden")
		print("  - highlight_color: ", rhythm_manager.highlight_color if "highlight_color" in rhythm_manager else "nicht gefunden")
	print("=========================================\n")
	
	if rhythm_manager:
		# Debug output
		if rhythm_manager.debug_mode:
			print("Card ", name, " clicked. Checking if it's highlighted...")
			print("Card modulate: ", modulate)
			print("Highlight color: ", rhythm_manager.highlight_color)
		
		# Check both the array and the visual state for reliability
		var is_visually_highlighted = (modulate == rhythm_manager.highlight_color)
		var is_in_highlighted_array = rhythm_manager.is_card_highlighted(self)
		
		if rhythm_manager.debug_mode:
			print("Is in highlighted array: ", is_in_highlighted_array)
			print("Is visually highlighted: ", is_visually_highlighted)
		
		if is_in_highlighted_array or is_visually_highlighted:
			print("Great rhythm! Card flipped at the right moment!")
			# Set the rhythm flag
			was_flipped_in_rhythm = true
			print("Set was_flipped_in_rhythm to TRUE for card: ", name)
			
			# Also emit the signal for any other listeners
			if rhythm_manager.has_signal("card_flipped_in_rhythm"):
				rhythm_manager.emit_signal("card_flipped_in_rhythm", self)
	else:
		print("Warning: Could not find GameManager or CardRhythmManager")
	
	# Now flip the card up
	flip_up(true)
	disabled = true # guard against double-clicks
	
	# Debug: Print the current state after flip
	if game_manager and game_manager.card_rhythm_manager and game_manager.card_rhythm_manager.debug_mode:
		print("After flip - ", name, " was_flipped_in_rhythm: ", was_flipped_in_rhythm)

func _reset_visual() -> void:
	_is_face_up = false
	_is_matched = false
	disabled = false
	texture_normal = back_texture if back_texture else null

# ------------------------------------------------------------------ #
# Compatibility wrappers (will be removed after GameManager refactor)
# ------------------------------------------------------------------ #

func setup_card(id, p_face_texture, p_back_texture) -> void:
	initialize(id, p_face_texture, p_back_texture)

func set_as_matched() -> void:
	mark_matched()

func flip_back() -> void:
	flip_down()
