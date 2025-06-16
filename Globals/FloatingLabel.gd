extends Label

class_name FloatingLabel

# A simple label that floats upward and fades out, then queues itself for deletion.
# Usage:
#   var lbl = FloatingLabel.new()
#   lbl.text = "+50"
#   add_child(lbl)
#   lbl.start()

@export var rise_distance: float = 50.0  # Pixels to move upward
@export var duration: float = 1.2  # Seconds for the whole animation
@export var start_color: Color = Color.WHITE
@export var font_size: int = 40  # Larger font
@export var bold: bool = false

func _ready() -> void:
    # Apply initial visual state
    modulate = start_color
    horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    add_theme_font_size_override("font_size", font_size)
    if bold:
        add_theme_constant_override("outline_size", 2)
        add_theme_color_override("font_outline_color", Color.BLACK)

func start() -> void:
    # Defer animation to next frame so size is calculated
    call_deferred("_begin_animation")

func _begin_animation() -> void:
    pivot_offset = size / 2.0
    z_index = 100  # ensure on top
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position:y", position.y - rise_distance, duration)
    tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
    tween.connect("finished", Callable(self, "queue_free"))
