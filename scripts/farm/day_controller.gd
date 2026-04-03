extends Node

## Handles day phase interactions: farming tools and building placement.

var selected_tool: String = ""
var selected_building = null  # BuildingData resource

var farm_grid: Node = null  # TileMapLayer with farm_grid.gd
var building_system: Node = null

func setup(grid: Node, bld_system: Node, build_menu: Node) -> void:
	farm_grid = grid
	building_system = bld_system

	if farm_grid and farm_grid.has_signal("tile_clicked"):
		farm_grid.tile_clicked.connect(_on_tile_clicked)
	if build_menu:
		if build_menu.has_signal("tool_selected"):
			build_menu.tool_selected.connect(_on_tool_selected)
		if build_menu.has_signal("building_selected"):
			build_menu.building_selected.connect(_on_building_selected)

func _on_tool_selected(tool_name: String) -> void:
	selected_tool = tool_name
	selected_building = null

	if tool_name == "end_day":
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			game_state.end_day_early()

func _on_building_selected(data) -> void:
	selected_building = data
	selected_tool = "build"

func _on_tile_clicked(tile_pos: Vector2i) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or game_state.current_phase != 0:  # DAY = 0
		return

	match selected_tool:
		"till":
			farm_grid.till_soil(tile_pos)
		"plant":
			farm_grid.plant_crop(tile_pos, "wheat")
		"water":
			farm_grid.water_tile(tile_pos)
		"harvest":
			var crop: String = farm_grid.harvest(tile_pos)
			if crop != "":
				var res_mgr = get_node_or_null("/root/ResourceMgr")
				if res_mgr:
					res_mgr.add("food", 5)
		"build":
			if selected_building and building_system:
				building_system.place_building(tile_pos, selected_building)
