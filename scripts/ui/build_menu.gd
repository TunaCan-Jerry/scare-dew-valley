extends PanelContainer

## Bottom toolbar for farm tools and building placement during day.

signal tool_selected(tool_name: String)
signal building_selected(building_data: Resource)

func _ready() -> void:
	# Build UI programmatically
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -40

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	_add_tool_button(hbox, "Till", "till")
	_add_tool_button(hbox, "Plant", "plant")
	_add_tool_button(hbox, "Water", "water")
	_add_tool_button(hbox, "Harvest", "harvest")

	hbox.add_child(VSeparator.new())

	_add_building_button(hbox, "Fence ($15)", "res://resources/buildings/wood_fence.tres")
	_add_building_button(hbox, "Turret ($40)", "res://resources/buildings/gun_turret.tres")
	_add_building_button(hbox, "Light ($25)", "res://resources/buildings/floodlight.tres")

	hbox.add_child(VSeparator.new())

	_add_tool_button(hbox, "End Day", "end_day")

	# Only visible during day
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.phase_changed.connect(_on_phase_changed)

func _add_tool_button(parent: Node, label_text: String, tool_name: String) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func(): tool_selected.emit(tool_name))
	parent.add_child(btn)

func _add_building_button(parent: Node, label_text: String, res_path: String) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func():
		var data = load(res_path)
		if data:
			building_selected.emit(data)
	)
	parent.add_child(btn)

func _on_phase_changed(phase: int) -> void:
	visible = (phase == 0)  # Only visible during DAY
