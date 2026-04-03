extends CharacterBody2D

## A named NPC character on the farm.

signal interacted(npc: CharacterBody2D)

var data: Resource = null  # CharacterData
var heart_level: int = 0

func setup(char_data) -> void:
	data = char_data
	queue_redraw()

func interact() -> String:
	if data and data.greeting_lines.size() > 0:
		return data.greeting_lines[randi() % data.greeting_lines.size()]
	return "..."

func get_display_name() -> String:
	if data:
		return data.character_name
	return "Unknown"

func _draw() -> void:
	if data:
		# Body
		draw_circle(Vector2.ZERO, 10.0, data.color)
		draw_circle(Vector2.ZERO, 8.0, data.color.lightened(0.3))
		# Name above head
		var font := ThemeDB.fallback_font
		if font:
			var name_text: String = data.character_name
			var text_size: Vector2 = font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
			draw_string(font, Vector2(-text_size.x / 2, -18), name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)
