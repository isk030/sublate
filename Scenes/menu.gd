extends Control

@onready var background_area = get_node_or_null("../BackgroundArea")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var start_button = $VBoxContainer/Button
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
	if background_area:
		background_area.visible = true
		self.visible = false  # Optional: Hide the menu after starting
