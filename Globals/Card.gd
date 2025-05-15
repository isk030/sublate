extends TextureButton
## Represents a single card in the memory game.
## Handles its visual state (face up/down), textures, and interaction logic.

var card_identifier: Variant = null ## Unique identifier for the card (e.g., its face texture).
var face_texture: Texture2D = null ## Texture for the card's face.
var back_texture: Texture2D = null ## Texture for the card's back (set by GameManager).

var is_flipped: bool = false ## Logical state: true if the card is face up.
var is_matched: bool = false ## True if the card has been successfully matched.

var _is_programmatically_changing_state: bool = false ## Guard flag to prevent re-entrant calls during state changes.

## Centralized function to change card state (pressed/flipped) programmatically.
## Ensures visual (button_pressed) and logical (is_flipped) states are synchronized.
func _set_visual_and_logical_state(p_is_pressed: bool) -> void:
	_is_programmatically_changing_state = true
	self.button_pressed = p_is_pressed 
	self.is_flipped = p_is_pressed    
	call_deferred("_reset_programmatic_change_flag") 

## Resets the programmatic change guard flag.
func _reset_programmatic_change_flag() -> void:
	_is_programmatically_changing_state = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.toggled.connect(_on_toggled)

## Initializes the card with its identifier and textures.
## Called by GameManager during card creation.
func setup_card(id: Variant, p_face_texture: Texture2D, p_back_texture: Texture2D) -> void:
	card_identifier = id
	face_texture = p_face_texture
	back_texture = p_back_texture
	self.button_pressed = false

## Handles the 'toggled' signal emitted when the button_pressed state changes.
## This is the core logic for user interaction and programmatic flips.
func _on_toggled(button_is_pressed_now: bool) -> void:
	if _is_programmatically_changing_state:
		return 

	if is_matched:
		if not button_is_pressed_now: 
			_set_visual_and_logical_state(true) 
		return

	if button_is_pressed_now: 
		if self.is_flipped:
			if not self.button_pressed: self.button_pressed = true
			return

		if not GameManager.can_player_flip_card():
			_set_visual_and_logical_state(false) 
			return
		
		self.is_flipped = true 
		EventManager.emit_event("card_flipped_by_user", self)
	
	else: 
		if not self.is_flipped:
			if self.button_pressed: self.button_pressed = false
			return

		if GameManager.is_this_the_only_user_flipped_card(self):
			_set_visual_and_logical_state(true) 
			return

		self.is_flipped = false 
		# Optional: EventManager.emit_event("card_returned_to_back_by_user", self)

## Marks the card as successfully matched.
func set_as_matched() -> void:
	is_matched = true
	self.modulate = Color.MAGENTA 
	self.disabled = true 
	_set_visual_and_logical_state(true) 

## Flips the card back to its face-down state.
## Called by GameManager (e.g., on a mismatch).
func flip_back() -> void:
	if not is_matched: 
		_set_visual_and_logical_state(false)
