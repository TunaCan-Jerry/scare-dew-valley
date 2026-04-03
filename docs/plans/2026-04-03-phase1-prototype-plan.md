# Duskhollow Farm — Phase 1 Prototype Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a playable core loop: farm by day, defend by night, with one character, basic resources, and one enemy type. Prove the game feel before adding depth.

**Architecture:** Godot 4.x, top-down 2D. DayNightCycle state machine drives everything. TileMapLayer for the farm grid. Data-driven Resources for buildings, crops, enemies, and characters. Signals decouple systems.

**Tech Stack:** Godot 4.x, GDScript, TileMapLayer, NavigationAgent2D for enemy pathfinding.

**Design doc:** `docs/plans/2026-04-03-duskhollow-design.md`

**Prototype scope:** Day/night cycle, farm grid with crops, wall/turret building, zombie waves, player commander with one ability, gold + food resources, one NPC with basic dialogue, dawn/dusk transitions.

---

### Task 1: Project Setup

**Files:**
- Create: `project.godot`
- Create: directory structure

**Step 1: Create project.godot**

```ini
; Engine configuration file.

config_version=5

[application]
config/name="Duskhollow Farm"
run/main_scene="res://scenes/game.tscn"
config/features=PackedStringArray("4.3")

[display]
window/size/viewport_width=960
window/size/viewport_height=540
window/size/window_width_override=1920
window/size/window_height_override=1080
window/stretch/mode="viewport"
window/stretch/aspect="keep"

[rendering]
textures/canvas_textures/default_texture_filter=0

[layer_names]
2d_physics/layer_1="walls"
2d_physics/layer_2="enemies"
2d_physics/layer_3="player"
2d_physics/layer_4="buildings"
2d_navigation/layer_1="ground"
```

**Step 2: Create directory structure**

```bash
cd /Users/wells/projects/duskhollow
mkdir -p scripts/{core,farm,defense,characters,ui}
mkdir -p scripts/data
mkdir -p scenes/{game,farm,defense,ui,characters}
mkdir -p resources/{buildings,crops,enemies,characters,waves}
mkdir -p assets/{sprites,fonts,audio}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: project skeleton and directory structure"
```

---

### Task 2: Day/Night Cycle State Machine

The backbone of the entire game.

**Files:**
- Create: `scripts/core/game_state.gd`
- Create: `scripts/core/day_night_cycle.gd`

**Step 1: Write game_state.gd**

```gdscript
class_name GameState
extends Node

enum Phase { DAY, DUSK, NIGHT, DAWN }

signal phase_changed(new_phase: int)
signal day_time_updated(time_remaining: float)
signal day_count_changed(day: int)

var current_phase: int = Phase.DAY
var current_day: int = 1
var day_time_remaining: float = 0.0
var day_duration: float = 180.0  # 3 minutes per day

var _paused: bool = false

func start_day() -> void:
	current_phase = Phase.DAY
	day_time_remaining = day_duration
	phase_changed.emit(Phase.DAY)

func start_dusk() -> void:
	current_phase = Phase.DUSK
	phase_changed.emit(Phase.DUSK)

func start_night() -> void:
	current_phase = Phase.NIGHT
	phase_changed.emit(Phase.NIGHT)

func start_dawn() -> void:
	current_phase = Phase.DAWN
	phase_changed.emit(Phase.DAWN)

func advance_to_next_day() -> void:
	current_day += 1
	day_count_changed.emit(current_day)
	start_day()

func end_day_early() -> void:
	if current_phase == Phase.DAY:
		day_time_remaining = 0.0

func _process(delta: float) -> void:
	if _paused:
		return
	if current_phase == Phase.DAY:
		day_time_remaining -= delta
		day_time_updated.emit(day_time_remaining)
		if day_time_remaining <= 0.0:
			start_dusk()
```

**Step 2: Write day_night_cycle.gd**

```gdscript
extends Node

## Manages the visual and gameplay transitions between phases.

const DUSK_DURATION := 5.0  # seconds for dusk transition
const DAWN_DURATION := 5.0

var game_state: GameState
var _transition_timer: float = 0.0

func _ready() -> void:
	game_state = get_node("/root/GameState")
	game_state.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase: int) -> void:
	match phase:
		GameState.Phase.DUSK:
			_transition_timer = DUSK_DURATION
		GameState.Phase.DAWN:
			_transition_timer = DAWN_DURATION

func _process(delta: float) -> void:
	if game_state.current_phase == GameState.Phase.DUSK:
		_transition_timer -= delta
		if _transition_timer <= 0.0:
			game_state.start_night()
	elif game_state.current_phase == GameState.Phase.DAWN:
		_transition_timer -= delta
		if _transition_timer <= 0.0:
			game_state.advance_to_next_day()
```

**Step 3: Register GameState as autoload**

Add to project.godot under `[autoload]`:
```ini
[autoload]
GameState="*res://scripts/core/game_state.gd"
```

**Step 4: Commit**

```bash
git add scripts/core/ project.godot
git commit -m "feat: add GameState autoload and DayNightCycle manager"
```

---

### Task 3: Resource Manager

**Files:**
- Create: `scripts/core/resource_manager.gd`

**Step 1: Write resource_manager.gd**

```gdscript
class_name ResourceManager
extends Node

signal resource_changed(resource_name: String, new_amount: int)

var _resources: Dictionary = {
	"gold": 100,
	"food": 20,
	"scrap": 10,
}

func get_amount(resource_name: String) -> int:
	return _resources.get(resource_name, 0)

func add(resource_name: String, amount: int) -> void:
	if not _resources.has(resource_name):
		_resources[resource_name] = 0
	_resources[resource_name] += amount
	resource_changed.emit(resource_name, _resources[resource_name])

func spend(resource_name: String, amount: int) -> bool:
	if get_amount(resource_name) >= amount:
		_resources[resource_name] -= amount
		resource_changed.emit(resource_name, _resources[resource_name])
		return true
	return false

func can_afford(costs: Dictionary) -> bool:
	for resource_name in costs:
		if get_amount(resource_name) < costs[resource_name]:
			return false
	return true

func spend_multiple(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false
	for resource_name in costs:
		_resources[resource_name] -= costs[resource_name]
		resource_changed.emit(resource_name, _resources[resource_name])
	return true
```

**Step 2: Register as autoload**

Add to `[autoload]` in project.godot:
```ini
ResourceMgr="*res://scripts/core/resource_manager.gd"
```

**Step 3: Commit**

```bash
git add scripts/core/resource_manager.gd project.godot
git commit -m "feat: add ResourceManager autoload with gold, food, scrap"
```

---

### Task 4: Farm Grid — TileMap Setup

**Files:**
- Create: `scenes/game.tscn` (main game scene)
- Create: `scripts/farm/farm_grid.gd`

**Step 1: Create the main game scene**

Build `scenes/game.tscn` with this structure:

```
Game (Node2D)
├── Camera2D — position centered on farm, zoom for overview
├── FarmGrid (TileMapLayer) — script: farm_grid.gd
├── Buildings (Node2D) — container for placed buildings
├── Enemies (Node2D) — container for enemy instances at night
├── PlayerCommander (CharacterBody2D) — player character
├── DayNightCycle (Node) — script: day_night_cycle.gd
├── UI (CanvasLayer)
│   ├── TopBar (HBoxContainer) — resources, day counter, clock
│   ├── BottomBar (HBoxContainer) — build menu, action buttons
│   └── PhaseLabel (Label) — shows current phase
```

Use a TileMapLayer with a 32x32 tile size. The farm is approximately 30x20 tiles.

Create a simple TileSet with these terrain types (use colored squares as placeholders):
- Grass (green) — default ground
- Tilled soil (brown) — farmable
- Planted (dark green) — has a crop growing
- Path (tan) — walkable
- Water (blue) — pond

**Step 2: Write farm_grid.gd**

```gdscript
extends TileMapLayer

## Manages the farm tile grid — soil states, crop placement, building zones.

signal tile_clicked(tile_pos: Vector2i)

# Soil states tracked separately from tilemap visual
# Key: Vector2i tile position, Value: Dictionary with state info
var soil_data: Dictionary = {}

# Tile source IDs (set these after creating the TileSet)
const TILE_GRASS := 0
const TILE_TILLED := 1
const TILE_PLANTED := 2
const TILE_PATH := 3

func _ready() -> void:
	# Initialize the grid as grass
	for x in range(30):
		for y in range(20):
			set_cell(Vector2i(x, y), 0, Vector2i(TILE_GRASS, 0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_local_mouse_position()
		var tile_pos: Vector2i = local_to_map(mouse_pos)
		tile_clicked.emit(tile_pos)

func till_soil(tile_pos: Vector2i) -> bool:
	if not soil_data.has(tile_pos):
		soil_data[tile_pos] = {"state": "tilled", "crop": null, "growth": 0}
		set_cell(tile_pos, 0, Vector2i(TILE_TILLED, 0))
		return true
	return false

func plant_crop(tile_pos: Vector2i, crop_name: String) -> bool:
	if soil_data.has(tile_pos) and soil_data[tile_pos].state == "tilled":
		soil_data[tile_pos].state = "planted"
		soil_data[tile_pos].crop = crop_name
		soil_data[tile_pos].growth = 0
		set_cell(tile_pos, 0, Vector2i(TILE_PLANTED, 0))
		return true
	return false

func water_tile(tile_pos: Vector2i) -> bool:
	if soil_data.has(tile_pos) and soil_data[tile_pos].state == "planted":
		soil_data[tile_pos]["watered"] = true
		return true
	return false

func advance_crops() -> Array:
	## Called at dawn. Grows watered crops. Returns list of harvestable positions.
	var harvestable: Array = []
	for pos in soil_data:
		var data: Dictionary = soil_data[pos]
		if data.state == "planted" and data.get("watered", false):
			data.growth += 1
			data.watered = false
			if data.growth >= 3:  # 3 days to harvest (prototype)
				harvestable.append(pos)
	return harvestable

func harvest(tile_pos: Vector2i) -> String:
	if soil_data.has(tile_pos) and soil_data[tile_pos].growth >= 3:
		var crop_name: String = soil_data[tile_pos].crop
		soil_data[tile_pos] = {"state": "tilled", "crop": null, "growth": 0}
		set_cell(tile_pos, 0, Vector2i(TILE_TILLED, 0))
		return crop_name
	return ""
```

**Step 3: Commit**

```bash
git add scenes/ scripts/farm/
git commit -m "feat: add main game scene and FarmGrid with soil/crop management"
```

---

### Task 5: Building Data & Placement System

**Files:**
- Create: `scripts/data/building_data.gd`
- Create: `scripts/farm/building_system.gd`
- Create: `scripts/farm/building.gd`

**Step 1: Write building_data.gd**

```gdscript
class_name BuildingData
extends Resource

enum BuildingType { WALL, TURRET, LIGHT, SHELTER, STATION }

@export var building_name: String = ""
@export var building_type: int = BuildingType.WALL
@export var description: String = ""
@export var max_health: int = 100
@export var size: Vector2i = Vector2i(1, 1)  # tile footprint
@export var costs: Dictionary = {}  # {"gold": 50, "scrap": 10}
@export var color: Color = Color.GRAY  # placeholder visual
```

**Step 2: Write building.gd (runtime instance)**

```gdscript
class_name Building
extends Node2D

var data: BuildingData
var current_health: int = 0
var tile_pos: Vector2i

func setup(building_data: BuildingData, pos: Vector2i) -> void:
	data = building_data
	current_health = data.max_health
	tile_pos = pos
	position = Vector2(pos.x * 32 + 16, pos.y * 32 + 16)
	queue_redraw()

func take_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	if current_health <= 0:
		_on_destroyed()

func repair(amount: int) -> void:
	current_health = mini(current_health + amount, data.max_health)

func _on_destroyed() -> void:
	queue_free()

func _draw() -> void:
	if data:
		var size_px: Vector2 = Vector2(data.size) * 32.0
		draw_rect(Rect2(-size_px / 2, size_px), data.color)
		# Health bar
		var bar_width: float = size_px.x
		var hp_ratio: float = float(current_health) / float(data.max_health) if data.max_health > 0 else 0.0
		draw_rect(Rect2(-bar_width / 2, -size_px.y / 2 - 6, bar_width, 4), Color.DARK_RED)
		draw_rect(Rect2(-bar_width / 2, -size_px.y / 2 - 6, bar_width * hp_ratio, 4), Color.GREEN)
```

**Step 3: Write building_system.gd**

```gdscript
extends Node

## Manages building placement, tracks all buildings on the grid.

signal building_placed(building: Node2D, pos: Vector2i)
signal building_destroyed(building: Node2D, pos: Vector2i)

const BuildingScene = preload("res://scripts/farm/building.gd")

var buildings: Dictionary = {}  # Vector2i -> Building
var buildings_container: Node2D

func _ready() -> void:
	buildings_container = get_node("/root/Game/Buildings")

func can_place(pos: Vector2i, data: BuildingData) -> bool:
	# Check if space is free
	for x in range(data.size.x):
		for y in range(data.size.y):
			var check_pos := Vector2i(pos.x + x, pos.y + y)
			if buildings.has(check_pos):
				return false
	# Check resources
	var res_mgr = get_node("/root/ResourceMgr")
	return res_mgr.can_afford(data.costs)

func place_building(pos: Vector2i, data: BuildingData) -> bool:
	if not can_place(pos, data):
		return false

	var res_mgr = get_node("/root/ResourceMgr")
	if not res_mgr.spend_multiple(data.costs):
		return false

	var building_node := Node2D.new()
	building_node.set_script(BuildingScene)
	buildings_container.add_child(building_node)
	building_node.setup(data, pos)

	# Register all tiles this building occupies
	for x in range(data.size.x):
		for y in range(data.size.y):
			buildings[Vector2i(pos.x + x, pos.y + y)] = building_node

	building_placed.emit(building_node, pos)
	return true

func get_building_at(pos: Vector2i):
	return buildings.get(pos, null)

func remove_building(pos: Vector2i) -> void:
	var building = buildings.get(pos)
	if building:
		# Remove all tile references
		for key in buildings.keys():
			if buildings[key] == building:
				buildings.erase(key)
		building_destroyed.emit(building, pos)
		building.queue_free()
```

**Step 4: Create prototype building .tres files**

Create `resources/buildings/wood_fence.tres`, `gun_turret.tres`, `floodlight.tres` with appropriate stats.

**Step 5: Commit**

```bash
git add scripts/data/ scripts/farm/ resources/buildings/
git commit -m "feat: add BuildingData, Building, and BuildingSystem"
```

---

### Task 6: Enemy Data & Spawning

**Files:**
- Create: `scripts/data/enemy_data.gd`
- Create: `scripts/defense/enemy.gd`
- Create: `scripts/defense/wave_manager.gd`

**Step 1: Write enemy_data.gd**

```gdscript
class_name EnemyData
extends Resource

@export var enemy_name: String = ""
@export var max_health: int = 50
@export var speed: float = 40.0  # pixels per second
@export var damage: int = 10  # damage per attack
@export var attack_speed: float = 1.0  # attacks per second
@export var color: Color = Color.DARK_GREEN  # placeholder
@export var gold_drop: int = 5
```

**Step 2: Write enemy.gd**

```gdscript
extends CharacterBody2D

signal died(enemy: CharacterBody2D)

var data: EnemyData
var current_health: int = 0
var _target: Node2D = null
var _attack_cooldown: float = 0.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	current_health = data.max_health
	queue_redraw()

func set_target(target: Node2D) -> void:
	_target = target
	if nav_agent and target:
		nav_agent.target_position = target.global_position

func take_damage(amount: int) -> void:
	current_health -= amount
	queue_redraw()
	if current_health <= 0:
		died.emit(self)
		queue_free()

func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return

	nav_agent.target_position = _target.global_position

	if nav_agent.is_navigation_finished():
		_try_attack(delta)
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = (next_pos - global_position).normalized()
	velocity = direction * data.speed
	move_and_slide()

func _try_attack(delta: float) -> void:
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		if _target.has_method("take_damage"):
			_target.take_damage(data.damage)
		_attack_cooldown = 1.0 / data.attack_speed

func _draw() -> void:
	if data:
		draw_circle(Vector2.ZERO, 12.0, data.color)
		# HP bar
		var hp_ratio: float = float(current_health) / float(data.max_health) if data.max_health > 0 else 0.0
		draw_rect(Rect2(-12, -18, 24, 3), Color.DARK_RED)
		draw_rect(Rect2(-12, -18, 24.0 * hp_ratio, 3), Color.RED)
```

**Step 3: Write wave_manager.gd**

```gdscript
extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared()

var current_wave: int = 0
var total_waves: int = 3
var enemies_alive: int = 0
var _spawn_timer: float = 0.0
var _enemies_to_spawn: int = 0
var _spawn_interval: float = 1.5
var _enemy_data: EnemyData
var _spawning: bool = false

var game_state: GameState
var enemies_container: Node2D

const EnemyScene = preload("res://scenes/defense/enemy.tscn")

func _ready() -> void:
	game_state = get_node("/root/GameState")
	enemies_container = get_node("/root/Game/Enemies")
	game_state.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase: int) -> void:
	if phase == GameState.Phase.NIGHT:
		current_wave = 0
		_start_next_wave()

func _start_next_wave() -> void:
	current_wave += 1
	if current_wave > total_waves:
		all_waves_cleared.emit()
		game_state.start_dawn()
		return

	wave_started.emit(current_wave)
	# Prototype: 3 + 2 per wave zombies
	_enemies_to_spawn = 3 + (current_wave * 2)
	_spawning = true
	_spawn_timer = 0.0

func _process(delta: float) -> void:
	if not _spawning:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _enemies_to_spawn > 0:
		_spawn_enemy()
		_enemies_to_spawn -= 1
		_spawn_timer = _spawn_interval
		if _enemies_to_spawn <= 0:
			_spawning = false

func _spawn_enemy() -> void:
	if not _enemy_data:
		_enemy_data = load("res://resources/enemies/zombie.tres")

	var enemy = EnemyScene.instantiate()
	enemies_container.add_child(enemy)
	enemy.setup(_enemy_data)

	# Spawn from random edge
	var side: int = randi() % 4
	var farm_size := Vector2(960, 640)  # 30*32, 20*32
	match side:
		0: enemy.global_position = Vector2(randf_range(0, farm_size.x), -20)
		1: enemy.global_position = Vector2(farm_size.x + 20, randf_range(0, farm_size.y))
		2: enemy.global_position = Vector2(randf_range(0, farm_size.x), farm_size.y + 20)
		3: enemy.global_position = Vector2(-20, randf_range(0, farm_size.y))

	# Find nearest wall/building to target
	_assign_target(enemy)

	enemy.died.connect(_on_enemy_died)
	enemies_alive += 1

func _assign_target(enemy: CharacterBody2D) -> void:
	var building_sys = get_node("/root/Game/BuildingSystem")
	if building_sys and not building_sys.buildings.is_empty():
		# Target nearest building
		var nearest_dist := 999999.0
		var nearest_building: Node2D = null
		for pos in building_sys.buildings:
			var bld = building_sys.buildings[pos]
			if is_instance_valid(bld):
				var dist: float = enemy.global_position.distance_to(bld.global_position)
				if dist < nearest_dist:
					nearest_dist = dist
					nearest_building = bld
		if nearest_building:
			enemy.set_target(nearest_building)

func _on_enemy_died(enemy: CharacterBody2D) -> void:
	enemies_alive -= 1
	var res_mgr = get_node("/root/ResourceMgr")
	res_mgr.add("gold", enemy.data.gold_drop)
	if enemies_alive <= 0 and not _spawning:
		wave_cleared.emit(current_wave)
		# Brief pause then next wave
		await get_tree().create_timer(3.0).timeout
		_start_next_wave()
```

**Step 4: Create enemy.tscn**

```
Enemy (CharacterBody2D) — script: enemy.gd
├── CollisionShape2D (CircleShape2D, radius 12)
└── NavigationAgent2D
```

**Step 5: Create zombie.tres**

```
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/enemy_data.gd" id="1"]
[resource]
script = ExtResource("1")
enemy_name = "Zombie"
max_health = 30
speed = 35.0
damage = 8
attack_speed = 0.8
color = Color(0.2, 0.4, 0.2, 1)
gold_drop = 3
```

**Step 6: Commit**

```bash
git add scripts/data/ scripts/defense/ scenes/defense/ resources/enemies/
git commit -m "feat: add EnemyData, Enemy, WaveManager with zombie spawning"
```

---

### Task 7: Turret System

**Files:**
- Create: `scripts/defense/turret.gd`

**Step 1: Write turret.gd**

Extends Building to add auto-fire behavior during night.

```gdscript
extends Node2D

## A turret that auto-fires at enemies during night phase.

var data: BuildingData
var current_health: int = 0
var tile_pos: Vector2i

var fire_range: float = 150.0
var fire_rate: float = 2.0  # shots per second
var bullet_damage: int = 10
var _fire_cooldown: float = 0.0
var _target: CharacterBody2D = null

func setup(building_data: BuildingData, pos: Vector2i) -> void:
	data = building_data
	current_health = data.max_health
	tile_pos = pos
	position = Vector2(pos.x * 32 + 16, pos.y * 32 + 16)
	queue_redraw()

func take_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	queue_redraw()
	if current_health <= 0:
		queue_free()

func _process(delta: float) -> void:
	var game_state = get_node("/root/GameState")
	if game_state.current_phase != GameState.Phase.NIGHT:
		return

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_find_target()
		if _target and is_instance_valid(_target):
			_fire()
			_fire_cooldown = 1.0 / fire_rate

func _find_target() -> void:
	_target = null
	var enemies_node = get_node("/root/Game/Enemies")
	var nearest_dist := fire_range
	for enemy in enemies_node.get_children():
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			_target = enemy

func _fire() -> void:
	if _target and _target.has_method("take_damage"):
		_target.take_damage(bullet_damage)
	queue_redraw()

func _draw() -> void:
	if data:
		# Turret body
		draw_rect(Rect2(-14, -14, 28, 28), data.color)
		# Range circle (faint, only at night)
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.current_phase == GameState.Phase.NIGHT:
			draw_arc(Vector2.ZERO, fire_range, 0, TAU, 32, Color(1, 1, 1, 0.1), 1.0)
		# HP bar
		var hp_ratio: float = float(current_health) / float(data.max_health) if data.max_health > 0 else 0.0
		draw_rect(Rect2(-14, -20, 28, 3), Color.DARK_RED)
		draw_rect(Rect2(-14, -20, 28.0 * hp_ratio, 3), Color.GREEN)
```

**Step 2: Update BuildingSystem to use Turret for turret-type buildings**

When placing a building with `BuildingType.TURRET`, instantiate turret.gd instead of building.gd.

**Step 3: Commit**

```bash
git add scripts/defense/turret.gd scripts/farm/building_system.gd
git commit -m "feat: add Turret with auto-targeting and firing at night"
```

---

### Task 8: Player Commander

**Files:**
- Create: `scripts/core/player_commander.gd`

**Step 1: Write player_commander.gd**

```gdscript
extends CharacterBody2D

## Player character — moves during day and night.
## During night, casts support abilities.

signal ability_used(ability_name: String, position: Vector2)

var move_speed: float = 120.0

# Abilities
var consecrate_cooldown: float = 0.0
const CONSECRATE_MAX_CD := 10.0
const CONSECRATE_RADIUS := 80.0
const CONSECRATE_DAMAGE := 5
const CONSECRATE_DURATION := 4.0

func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")

	velocity = input_dir.normalized() * move_speed
	move_and_slide()

	# Ability cooldowns
	if consecrate_cooldown > 0.0:
		consecrate_cooldown -= delta

func _unhandled_input(event: InputEvent) -> void:
	var game_state = get_node("/root/GameState")
	if game_state.current_phase != GameState.Phase.NIGHT:
		return

	if event.is_action_pressed("ui_accept"):  # Space bar
		_use_consecrate()

func _use_consecrate() -> void:
	if consecrate_cooldown > 0.0:
		return
	consecrate_cooldown = CONSECRATE_MAX_CD
	ability_used.emit("consecrate", global_position)

	# Damage enemies in radius
	var enemies_node = get_node("/root/Game/Enemies")
	for enemy in enemies_node.get_children():
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= CONSECRATE_RADIUS:
			if enemy.has_method("take_damage"):
				enemy.take_damage(CONSECRATE_DAMAGE)

func _draw() -> void:
	# Player character
	draw_circle(Vector2.ZERO, 10.0, Color.WHITE)
	draw_circle(Vector2.ZERO, 8.0, Color(0.2, 0.3, 0.8))

	# Consecrate cooldown indicator
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.current_phase == GameState.Phase.NIGHT:
		if consecrate_cooldown <= 0.0:
			draw_arc(Vector2.ZERO, CONSECRATE_RADIUS, 0, TAU, 32, Color(0.8, 0.8, 0.2, 0.15), 1.0)
```

**Step 2: Add to game scene**

PlayerCommander (CharacterBody2D) with a CollisionShape2D (circle, radius 10). Starting position center of farm.

**Step 3: Commit**

```bash
git add scripts/core/player_commander.gd scenes/
git commit -m "feat: add PlayerCommander with movement and Consecrate ability"
```

---

### Task 9: Basic HUD

**Files:**
- Create: `scripts/ui/hud.gd`

**Step 1: Write hud.gd**

```gdscript
extends CanvasLayer

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var food_label: Label = $TopBar/FoodLabel
@onready var day_label: Label = $TopBar/DayLabel
@onready var clock_label: Label = $TopBar/ClockLabel
@onready var phase_label: Label = $PhaseLabel
@onready var wave_label: Label = $WaveLabel

var game_state: GameState
var res_mgr: ResourceManager

func _ready() -> void:
	game_state = get_node("/root/GameState")
	res_mgr = get_node("/root/ResourceMgr")

	game_state.phase_changed.connect(_on_phase_changed)
	game_state.day_count_changed.connect(_on_day_changed)
	res_mgr.resource_changed.connect(_on_resource_changed)

	_update_resources()
	_on_day_changed(game_state.current_day)

func _process(_delta: float) -> void:
	if game_state.current_phase == GameState.Phase.DAY:
		var mins: int = int(game_state.day_time_remaining) / 60
		var secs: int = int(game_state.day_time_remaining) % 60
		clock_label.text = "%d:%02d" % [mins, secs]

func _on_phase_changed(phase: int) -> void:
	match phase:
		GameState.Phase.DAY:
			phase_label.text = "DAY"
			phase_label.modulate = Color.YELLOW
		GameState.Phase.DUSK:
			phase_label.text = "DUSK"
			phase_label.modulate = Color.ORANGE
		GameState.Phase.NIGHT:
			phase_label.text = "NIGHT"
			phase_label.modulate = Color.RED
		GameState.Phase.DAWN:
			phase_label.text = "DAWN"
			phase_label.modulate = Color.LIGHT_BLUE

func _on_day_changed(day: int) -> void:
	day_label.text = "Day %d" % day

func _on_resource_changed(_name: String, _amount: int) -> void:
	_update_resources()

func _update_resources() -> void:
	gold_label.text = "Gold: %d" % res_mgr.get_amount("gold")
	food_label.text = "Food: %d" % res_mgr.get_amount("food")
```

**Step 2: Build the HUD scene nodes in game.tscn**

Add Labels for resources, day counter, clock, phase indicator, and wave info.

**Step 3: Commit**

```bash
git add scripts/ui/hud.gd scenes/
git commit -m "feat: add HUD with resources, day counter, clock, phase display"
```

---

### Task 10: Build Menu & Day Interactions

**Files:**
- Create: `scripts/ui/build_menu.gd`
- Create: `scripts/farm/day_controller.gd`

**Step 1: Write build_menu.gd**

A simple bottom bar that lets the player select a building to place, or select farm tools (till, plant, water, harvest).

```gdscript
extends HBoxContainer

signal tool_selected(tool_name: String)
signal building_selected(building_data: BuildingData)

var _tool_buttons: Array = []
var _building_data_map: Dictionary = {}

func _ready() -> void:
	_add_tool_button("Till", "till")
	_add_tool_button("Plant", "plant")
	_add_tool_button("Water", "water")
	_add_tool_button("Harvest", "harvest")
	_add_separator()
	_add_building_button("Wood Fence", "res://resources/buildings/wood_fence.tres")
	_add_building_button("Gun Turret", "res://resources/buildings/gun_turret.tres")
	_add_building_button("Floodlight", "res://resources/buildings/floodlight.tres")
	_add_separator()
	_add_tool_button("End Day", "end_day")

func _add_tool_button(label: String, tool_name: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(func(): tool_selected.emit(tool_name))
	add_child(btn)

func _add_building_button(label: String, res_path: String) -> void:
	var data: BuildingData = load(res_path)
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(func(): building_selected.emit(data))
	add_child(btn)

func _add_separator() -> void:
	var sep := VSeparator.new()
	add_child(sep)
```

**Step 2: Write day_controller.gd**

Wires farm grid clicks to the selected tool/building.

```gdscript
extends Node

## Handles day phase interactions: farming tools and building placement.

var selected_tool: String = ""
var selected_building: BuildingData = null

var farm_grid: TileMapLayer
var building_system: Node

func _ready() -> void:
	farm_grid = get_node("/root/Game/FarmGrid")
	building_system = get_node("/root/Game/BuildingSystem")
	var build_menu = get_node("/root/Game/UI/BottomBar")

	farm_grid.tile_clicked.connect(_on_tile_clicked)
	if build_menu.has_signal("tool_selected"):
		build_menu.tool_selected.connect(_on_tool_selected)
	if build_menu.has_signal("building_selected"):
		build_menu.building_selected.connect(_on_building_selected)

func _on_tool_selected(tool_name: String) -> void:
	selected_tool = tool_name
	selected_building = null

	if tool_name == "end_day":
		var game_state = get_node("/root/GameState")
		game_state.end_day_early()

func _on_building_selected(data: BuildingData) -> void:
	selected_building = data
	selected_tool = "build"

func _on_tile_clicked(tile_pos: Vector2i) -> void:
	var game_state = get_node("/root/GameState")
	if game_state.current_phase != GameState.Phase.DAY:
		return

	match selected_tool:
		"till":
			farm_grid.till_soil(tile_pos)
		"plant":
			if farm_grid.plant_crop(tile_pos, "wheat"):
				pass  # Could cost seeds
		"water":
			farm_grid.water_tile(tile_pos)
		"harvest":
			var crop: String = farm_grid.harvest(tile_pos)
			if crop != "":
				var res_mgr = get_node("/root/ResourceMgr")
				res_mgr.add("food", 5)
		"build":
			if selected_building:
				building_system.place_building(tile_pos, selected_building)
```

**Step 3: Commit**

```bash
git add scripts/ui/build_menu.gd scripts/farm/day_controller.gd
git commit -m "feat: add build menu and day controller for farming and building"
```

---

### Task 11: Lighting & Phase Visuals

**Files:**
- Modify: `scenes/game.tscn`
- Create: `scripts/core/lighting_manager.gd`

**Step 1: Write lighting_manager.gd**

```gdscript
extends CanvasModulate

## Shifts the world lighting based on game phase.

var game_state: GameState

const DAY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DUSK_COLOR := Color(0.7, 0.5, 0.3, 1.0)
const NIGHT_COLOR := Color(0.15, 0.15, 0.25, 1.0)
const DAWN_COLOR := Color(0.6, 0.6, 0.8, 1.0)

var _target_color := DAY_COLOR

func _ready() -> void:
	game_state = get_node("/root/GameState")
	game_state.phase_changed.connect(_on_phase_changed)
	color = DAY_COLOR

func _on_phase_changed(phase: int) -> void:
	match phase:
		GameState.Phase.DAY: _target_color = DAY_COLOR
		GameState.Phase.DUSK: _target_color = DUSK_COLOR
		GameState.Phase.NIGHT: _target_color = NIGHT_COLOR
		GameState.Phase.DAWN: _target_color = DAWN_COLOR

func _process(delta: float) -> void:
	color = color.lerp(_target_color, delta * 2.0)
```

**Step 2: Add CanvasModulate to game scene, add PointLight2D to floodlight buildings and player**

Floodlights get a PointLight2D child that only enables during night. Player gets a small light.

**Step 3: Commit**

```bash
git add scripts/core/lighting_manager.gd scenes/
git commit -m "feat: add LightingManager with phase-based ambient lighting"
```

---

### Task 12: One NPC — Basic Dialogue

**Files:**
- Create: `scripts/data/character_data.gd`
- Create: `scripts/characters/npc.gd`
- Create: `scripts/ui/dialogue_box.gd`
- Create: `resources/characters/maria.tres`

**Step 1: Write character_data.gd**

```gdscript
class_name CharacterData
extends Resource

@export var character_name: String = ""
@export var description: String = ""
@export var trait_name: String = ""
@export var trait_description: String = ""
@export var color: Color = Color.WHITE  # placeholder sprite color
@export var greeting_lines: PackedStringArray = []
@export var preferred_gifts: PackedStringArray = []
```

**Step 2: Write npc.gd**

```gdscript
extends CharacterBody2D

var data: CharacterData
var heart_level: int = 0

func setup(char_data: CharacterData) -> void:
	data = char_data
	queue_redraw()

func interact() -> String:
	if data and data.greeting_lines.size() > 0:
		return data.greeting_lines[randi() % data.greeting_lines.size()]
	return "..."

func _draw() -> void:
	if data:
		draw_circle(Vector2.ZERO, 10.0, data.color)
		draw_circle(Vector2.ZERO, 8.0, data.color.lightened(0.3))
```

**Step 3: Write dialogue_box.gd**

```gdscript
extends PanelContainer

@onready var name_label: Label = $VBox/NameLabel
@onready var text_label: Label = $VBox/TextLabel

var _visible: bool = false

func show_dialogue(char_name: String, text: String) -> void:
	name_label.text = char_name
	text_label.text = text
	visible = true
	_visible = true

func _unhandled_input(event: InputEvent) -> void:
	if _visible and event.is_action_pressed("ui_accept"):
		visible = false
		_visible = false
```

**Step 4: Create maria.tres**

Maria, the former nurse — first NPC the player meets.

**Step 5: Wire NPC interaction into PlayerCommander (interact with E key or proximity + click)**

**Step 6: Commit**

```bash
git add scripts/data/character_data.gd scripts/characters/ scripts/ui/dialogue_box.gd resources/characters/
git commit -m "feat: add NPC system with Maria, basic dialogue interaction"
```

---

### Task 13: Wire It All Together

**Files:**
- Modify: `scenes/game.tscn`
- Create: `scripts/core/game_controller.gd`

**Step 1: Write game_controller.gd**

The main script that connects all systems together:

```gdscript
extends Node2D

## Main game controller. Wires all systems together.

@onready var farm_grid = $FarmGrid
@onready var building_system = $BuildingSystem
@onready var wave_manager = $WaveManager
@onready var day_night_cycle = $DayNightCycle
@onready var player = $PlayerCommander

var game_state: GameState

func _ready() -> void:
	game_state = get_node("/root/GameState")
	game_state.phase_changed.connect(_on_phase_changed)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)

	# Start the game
	game_state.start_day()

func _on_phase_changed(phase: int) -> void:
	match phase:
		GameState.Phase.DAWN:
			_process_dawn()

func _process_dawn() -> void:
	# Advance crops
	var harvestable: Array = farm_grid.advance_crops()

	# Consume food (1 per community member)
	var res_mgr = get_node("/root/ResourceMgr")
	var food_needed: int = 1  # Just player for now
	res_mgr.spend("food", food_needed)

	# Salvage from night
	res_mgr.add("scrap", 3)

func _on_all_waves_cleared() -> void:
	# Night survived
	pass
```

**Step 2: Build final game.tscn with all nodes wired**

Ensure all nodes are in the scene tree and scripts are assigned.

**Step 3: Verify the full loop**

Run the game. Expected:
1. Day starts. Click toolbar to till, plant, water, build.
2. Clock ticks down (or click End Day).
3. Dusk: lighting shifts orange.
4. Night: zombies spawn, turrets fire, player moves and uses Consecrate (space).
5. Waves clear → Dawn: lighting shifts, crops grow, new day.

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: wire all systems together - playable day/night loop"
```

---

### Task 14: Navigation Setup for Enemies

**Files:**
- Modify: `scenes/game.tscn`

**Step 1: Add NavigationRegion2D to the game scene**

Enemies need a NavigationRegion2D covering the farm area so their NavigationAgent2D can pathfind.

Create a NavigationRegion2D with a NavigationPolygon covering the walkable area (the full farm map). Buildings placed by the player should carve out the navigation mesh (or enemies path around them).

For the prototype, use a simple rectangular polygon covering the entire play area. Building collision will handle obstacle avoidance.

**Step 2: Commit**

```bash
git add scenes/
git commit -m "feat: add NavigationRegion2D for enemy pathfinding"
```

---

## Summary

14 tasks. After completion you have:

- **Day phase:** Farm grid with till/plant/water/harvest, building placement (fences, turrets, floodlights), resource management (gold, food, scrap), day clock with end-day option
- **Night phase:** Zombie waves spawning from edges, turrets auto-firing, player commander moving and casting Consecrate
- **Transitions:** Dusk/dawn with lighting shifts and crop advancement
- **One NPC:** Maria with basic dialogue
- **HUD:** Resources, day counter, clock, phase display

**Critical path:** Tasks 1-8 (playable loop). Tasks 9-14 add UI, interaction, lighting, NPC, and polish.

**What's NOT in Phase 1:** Excursions, other communes, tech tree, crafting stations, status effects, non-corporeal enemies, relationship system, roguelike unlocks, multiple enemy types. Those are all Phase 2+.
