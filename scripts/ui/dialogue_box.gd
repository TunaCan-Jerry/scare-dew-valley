extends CanvasLayer

## Simple dialogue display box.

var _panel: PanelContainer
var _name_label: Label
var _text_label: Label
var _is_showing: bool = false

func _ready() -> void:
	_build_ui()
	_panel.visible = false

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -100
	_panel.offset_bottom = -45
	_panel.offset_left = 100
	_panel.offset_right = -100

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.6, 1)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	vbox.add_child(_name_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 12)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_text_label)

func show_dialogue(char_name: String, text: String) -> void:
	_name_label.text = char_name
	_text_label.text = text
	_panel.visible = true
	_is_showing = true

func hide_dialogue() -> void:
	_panel.visible = false
	_is_showing = false

func is_showing() -> bool:
	return _is_showing

func _unhandled_input(event: InputEvent) -> void:
	if _is_showing and event is InputEventMouseButton and event.pressed:
		hide_dialogue()
	elif _is_showing and event.is_action_pressed("ui_accept"):
		hide_dialogue()
