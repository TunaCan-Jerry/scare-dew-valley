extends CanvasLayer

## HUD showing resources, day counter, clock, phase, wave info.

var game_state: Node
var res_mgr: Node

var gold_label: Label
var food_label: Label
var scrap_label: Label
var day_label: Label
var clock_label: Label
var phase_label: Label
var wave_label: Label

func _ready() -> void:
	game_state = get_node_or_null("/root/GameState")
	res_mgr = get_node_or_null("/root/ResourceMgr")

	# Build HUD UI programmatically
	_build_ui()

	if game_state:
		game_state.phase_changed.connect(_on_phase_changed)
		game_state.day_count_changed.connect(_on_day_changed)
	if res_mgr:
		res_mgr.resource_changed.connect(_on_resource_changed)

	_update_resources()
	if game_state:
		_on_day_changed(game_state.current_day)
		_on_phase_changed(game_state.current_phase)

func _build_ui() -> void:
	# Top bar - resources and info
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 30
	add_child(top_bar)

	# Add a dark background panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom = 30
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.move_to_front()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	day_label = _make_label("Day 1")
	hbox.add_child(day_label)

	clock_label = _make_label("3:00")
	hbox.add_child(clock_label)

	phase_label = _make_label("DAY")
	phase_label.modulate = Color.YELLOW
	hbox.add_child(phase_label)

	hbox.add_child(VSeparator.new())

	gold_label = _make_label("Gold: 100")
	hbox.add_child(gold_label)

	food_label = _make_label("Food: 20")
	hbox.add_child(food_label)

	scrap_label = _make_label("Scrap: 10")
	hbox.add_child(scrap_label)

	hbox.add_child(VSeparator.new())

	wave_label = _make_label("")
	hbox.add_child(wave_label)

func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label

func _process(_delta: float) -> void:
	if game_state and game_state.current_phase == 0:  # DAY
		var mins: int = int(game_state.day_time_remaining) / 60
		var secs: int = int(game_state.day_time_remaining) % 60
		clock_label.text = "%d:%02d" % [mins, secs]
	elif game_state and game_state.current_phase == 2:  # NIGHT
		clock_label.text = "NIGHT"

func _on_phase_changed(phase: int) -> void:
	match phase:
		0:  # DAY
			phase_label.text = "DAY"
			phase_label.modulate = Color.YELLOW
			wave_label.text = ""
		1:  # DUSK
			phase_label.text = "DUSK"
			phase_label.modulate = Color.ORANGE
		2:  # NIGHT
			phase_label.text = "NIGHT"
			phase_label.modulate = Color.RED
		3:  # DAWN
			phase_label.text = "DAWN"
			phase_label.modulate = Color.LIGHT_BLUE

func _on_day_changed(day: int) -> void:
	day_label.text = "Day %d" % day

func _on_resource_changed(_name: String, _amount: int) -> void:
	_update_resources()

func _update_resources() -> void:
	if res_mgr:
		gold_label.text = "Gold: %d" % res_mgr.get_amount("gold")
		food_label.text = "Food: %d" % res_mgr.get_amount("food")
		scrap_label.text = "Scrap: %d" % res_mgr.get_amount("scrap")

func show_wave(wave_num: int) -> void:
	wave_label.text = "Wave %d" % wave_num

func show_wave_cleared(wave_num: int) -> void:
	wave_label.text = "Wave %d cleared!" % wave_num
