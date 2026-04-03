extends CharacterBody2D

## Player character — moves during day and night.
## During night, casts support abilities.

signal ability_used(ability_name: String, pos: Vector2)

var move_speed: float = 120.0

# Consecrate ability
var consecrate_cooldown: float = 0.0
const CONSECRATE_MAX_CD := 10.0
const CONSECRATE_RADIUS := 80.0
const CONSECRATE_DAMAGE := 5
const CONSECRATE_SLOW_DURATION := 3.0

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")

	velocity = input_dir.normalized() * move_speed
	move_and_slide()

func _process(delta: float) -> void:
	if consecrate_cooldown > 0.0:
		consecrate_cooldown -= delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or game_state.current_phase != 2:  # NIGHT = 2
		return

	if event.is_action_pressed("ui_accept"):  # Space bar
		_use_consecrate()

func _use_consecrate() -> void:
	if consecrate_cooldown > 0.0:
		return
	consecrate_cooldown = CONSECRATE_MAX_CD
	ability_used.emit("consecrate", global_position)

	# Damage enemies in radius
	var enemies_node = get_node_or_null("/root/Game/Enemies")
	if not enemies_node:
		return
	for enemy in enemies_node.get_children():
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= CONSECRATE_RADIUS:
			if enemy.has_method("take_damage"):
				enemy.take_damage(CONSECRATE_DAMAGE)

func _draw() -> void:
	# Player body
	draw_circle(Vector2.ZERO, 10.0, Color.WHITE)
	draw_circle(Vector2.ZERO, 8.0, Color(0.2, 0.3, 0.8))

	# Night ability indicators
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or game_state.current_phase != 2:
		return

	if consecrate_cooldown <= 0.0:
		# Ready indicator - faint circle showing range
		draw_arc(Vector2.ZERO, CONSECRATE_RADIUS, 0, TAU, 32, Color(0.8, 0.8, 0.2, 0.15), 1.0)
	else:
		# Cooldown indicator
		var cd_ratio: float = consecrate_cooldown / CONSECRATE_MAX_CD
		var arc_end: float = TAU * (1.0 - cd_ratio)
		draw_arc(Vector2.ZERO, 14.0, 0, arc_end, 16, Color(0.8, 0.8, 0.2, 0.5), 2.0)
