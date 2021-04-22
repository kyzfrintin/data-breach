extends Node2D

# You can only create an AStar node from code, not from the Scene tab
onready var astar_node = AStar.new()
# The Tilemap node doesn't have clear bounds so we're defining the map's limits here
export(Vector2) var map_size = Vector2(8000, 8000)

# The path start and end variables use setter methods
# You can find them at the bottom of the script
var path_start_position = Vector2() setget _set_path_start_position
var path_end_position = Vector2() setget _set_path_end_position

var _point_path = []

const BASE_LINE_WIDTH = 3.0
const DRAW_COLOR = Color('#fff')

# get_used_cells_by_id is a method from the TileMap node
# here the id 0 corresponds to the grey tile, the obstacles
var points = []

func initialise():
	var walkable_cells_list = astar_add_walkable_cells()
	astar_connect_walkable_cells(walkable_cells_list)


# Click and Shift force the start and end position of the path to update
# and the node to redraw everything
#func _input(event):
#	if event.is_action_pressed('click') and Input.is_key_pressed(KEY_SHIFT):
#		# To call the setter method from this script we have to use the explicit self.
#		self.path_start_position = world_to_map(get_global_mouse_position())
#	elif event.is_action_pressed('click'):
#		self.path_end_position = world_to_map(get_global_mouse_position())


# Loops through all cells within the map's bounds and
# adds all points to the astar_node, except the obstacles
func astar_add_walkable_cells():
	var points_array = []
	for i in get_children():
		for o in i.get_children():
			points.append(o)
	for i in points:
		var point = i.global_position
			
		points_array.append(point)
		# The AStar class references points with indices
		# Using a function to calculate the index from a point's coordinates
		# ensures we always get the same index with the same input point
		var point_index = calculate_point_index(point)
#		print(point_index)
		# AStar works for both 2d and 3d, so we have to convert the point
		# coordinates from and to Vector3s
		astar_node.add_point(point_index, Vector3(point.x, point.y, 0.0))
	return points_array


# Once you added all points to the AStar node, you've got to connect them
# The points don't have to be on a grid: you can use this class
# to create walkable graphs however you'd like
# It's a little harder to code at first, but works for 2d, 3d,
# orthogonal grids, hex grids, tower defense games...
func astar_connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		# For every cell in the map, we check the one to the top, right.
		# left and bottom of it. If it's in the map and not an obstalce,
		# We connect the current point with it
		
		var other_points = points_array
		for relative in other_points:
			if (point.distance_to(relative) < 150) and (relative != point):
				var relative_index = calculate_point_index(relative)
				astar_node.connect_points(point_index, relative_index, true)


# This is a variation of the method above
# It connects cells horizontally, vertically AND diagonally
func astar_connect_walkable_cells_diagonal(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		for local_y in range(3):
			for local_x in range(3):
				var point_relative = Vector2(point.x + local_x - 1, point.y + local_y - 1)
				var point_relative_index = calculate_point_index(point_relative)

				if point_relative == point:
					continue
				if not astar_node.has_point(point_relative_index):
					continue
				astar_node.connect_points(point_index, point_relative_index, true)


func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= map_size.x or point.y >= map_size.y


func calculate_point_index(point):
	return point.x + 10000 * point.y

func find_path(world_start, world_end):
	self.path_start_position = get_closest_point(world_start)
	self.path_end_position = get_closest_point(world_end)
#	print('calculating')
	_recalculate_path()
	var path_world = []
	for point in _point_path:
		path_world.append(point)
	return path_world

func get_closest_point(world_pos):
	var point
	var dis = 50000
	for i in astar_node.get_points():
		var pos_3 = astar_node.get_point_position(i)
		var pos = Vector2(pos_3.x, pos_3.y)
		if pos.distance_to(world_pos) < dis:
			point = pos
			dis = pos.distance_to(world_pos)
	return point
	
func _recalculate_path():
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
#	print('start is %s, end is %s' % [start_point_index, end_point_index])
	# This method gives us an array of points. Note you need the start and end
	# points' indices as input
	_point_path = astar_node.get_point_path(start_point_index, end_point_index)

# Setters for the start and end path values.
func _set_path_start_position(value):
#	if is_outside_map_bounds(value):
#		return
	path_start_position = value
	if path_end_position and path_end_position != path_start_position:
		_recalculate_path()

func _set_path_end_position(value):
#	if is_outside_map_bounds(value):
#		return
	path_end_position = value
	if path_start_position != value:
		_recalculate_path()
