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

func _ready() -> void:
    # Apply initial visual state
    modulate = start_color

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
