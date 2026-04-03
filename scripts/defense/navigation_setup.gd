extends NavigationRegion2D

## Sets up a navigation region covering the farm area for enemy pathfinding.

func _ready() -> void:
	# Create a navigation polygon covering the entire farm area
	# Farm is 30x32 = 960 wide, 20x32 = 640 tall
	# Add margin around the farm for enemy spawning
	var nav_poly := NavigationPolygon.new()

	var outline := PackedVector2Array([
		Vector2(-40, -40),
		Vector2(1000, -40),
		Vector2(1000, 680),
		Vector2(-40, 680),
	])
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()

	navigation_polygon = nav_poly
