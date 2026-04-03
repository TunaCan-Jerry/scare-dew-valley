extends CanvasModulate

## Shifts the world lighting based on game phase.

const DAY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DUSK_COLOR := Color(0.7, 0.5, 0.3, 1.0)
const NIGHT_COLOR := Color(0.15, 0.15, 0.25, 1.0)
const DAWN_COLOR := Color(0.6, 0.6, 0.8, 1.0)

var _target_color := DAY_COLOR

func _ready() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.phase_changed.connect(_on_phase_changed)
	color = DAY_COLOR

func _on_phase_changed(phase: int) -> void:
	match phase:
		0: _target_color = DAY_COLOR     # DAY
		1: _target_color = DUSK_COLOR    # DUSK
		2: _target_color = NIGHT_COLOR   # NIGHT
		3: _target_color = DAWN_COLOR    # DAWN

func _process(delta: float) -> void:
	color = color.lerp(_target_color, delta * 2.0)
