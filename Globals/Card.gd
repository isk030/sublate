extends TextureButton

# Signals
signal flipped(card)
signal matched(card)
signal state_changed(card, is_face_up: bool)

@export var card_identifier: Variant = null
@export var face_texture: Texture2D = null
@export var back_texture: Texture2D = null
@export var matched_texture: Texture2D = preload("res://assets/ui/level_select_frame_select_128.png")

var _is_face_up: bool = false
var _is_matched: bool = false

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

func _on_pressed() -> void:
	if GameManager and not GameManager.can_player_flip_card():
		return
	flip_up(true)
	disabled = true # guard against double-clicks

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
