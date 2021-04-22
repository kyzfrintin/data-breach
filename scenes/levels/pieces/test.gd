extends Node2D

var start = 136
var path_amount := 3
var path_starts = []
var start_pos = Vector2()
var tiles = []
var ends = []
var nodes = []

func _ready():
	yield(get_tree().create_timer(1),"timeout")
	get_node("grid/136").activate(true, false, 12, false)

func paths_finished():
	var cells = $grid.get_children()
	var rooms = []
	for i in cells:
		if i.active:
			rooms.append(i)
		else:
			i.queue_free()
#	align_with_center(rooms)
	build_level(rooms)
	for i in nodes:
		if i.node_spot:
			RoomHolder.node_spots.append(i.node_spot.global_position)
	add_starts()
	save_level_and_load()

func room_activated():
	$Timer.stop()

func room_finished():
	$Timer.start()

func build_level(rooms):
	var line_root = get_node("../World/lines")
	var box_root = get_node("../World/shade")
	var col_root = get_node("../World/collision")
	var nav = get_node("../World/navigation")
	var sectors = get_node("../World/sectors")
	var num := 1
	for i in rooms:
		var t = i.current_tile
		tiles.append(t)
		var tile = t.get_node("lines").duplicate()
		var box = t.get_node("box").duplicate()
		var col = t.get_node("world_geom").duplicate()
#			var navp = t.get_node("navpoly").duplicate()
		var astar = t.get_node("astar_nodes").duplicate()
		var sector = i.get_node("Area2D").duplicate()
		tile.rotation_degrees = t.rotation_degrees
		box.rotation_degrees = t.rotation_degrees
		col.rotation_degrees = t.rotation_degrees
		astar.rotation_degrees = t.rotation_degrees
#			navp.rotation_degrees = t.rotation_degrees
		tile.global_position = i.global_position
		box.global_position = i.global_position
		col.position = i.global_position
		astar.position = i.global_position
#			navp.position = i.global_position
		sector.position = i.global_position
		line_root.add_child(tile)
		box_root.add_child(box)
		col_root.add_child(col)
		nav.add_child(astar)
		sectors.add_child(sector)
		col.name = ('world_geom_' + str(num))
		sector.name = ('Sector_' + str(num))
		num += 1
		i.queue_free()
	

func add_starts():
	var p_start = ends[randi() % ends.size()]
	ends.remove(ends.find(p_start))
	var e_start = ends[randi() % ends.size()]
	for i in RoomHolder.node_spots:
		var ppos = p_start.global_position
		var epos = e_start.global_position
		if (i.distance_to(ppos) < 1000) or (i.distance_to(epos) < 1000):
			RoomHolder.node_spots.remove(RoomHolder.node_spots.find(i))
	RoomHolder.start_pos = [p_start.node_spot.global_position, p_start.entry]
	RoomHolder.enem_start = [e_start.node_spot.global_position, e_start.entry]
	
func set_room_ownership():
	var room = get_node("../World")
	for i in room.get_children():
		i.set_owner(room)
		if i.get_child_count() > 0:
			for o in i.get_children():
				o.set_owner(room)
				if o.get_child_count() > 0:
					for p in o.get_children():
						p.set_owner(room)

func align_with_center(rooms):
	var left = 1000000.0
	var top = 1000000.0
	for i in rooms:
		var tipos = i.global_position
#		print(tipos)
		if tipos.x < left:
			left = tipos.x
		if tipos.y < top:
			top = tipos.y
	if left < 0.0:
		for i in rooms:
			i.global_position.x += -left
	if top < 0.0:
		for i in rooms:
			i.global_position.y += -top
	
func save_level_and_load():
	set_room_ownership()
	var room = PackedScene.new()
	room.pack(get_node("../World"))
	RoomHolder.room = room
	get_tree().change_scene_to(preload("res://scenes/levels/1/main.tscn"))

func check_connection(begin, end):
	if begin.active:
		if end.active:
			if !begin.is_connected_to(end) and !begin.is_in_path(end):
				print('node ' + begin.name + ' and ' + end.name + ' can connect')
				connect_nodes(begin, end)

func connect_nodes(begin, end):
	var b_type = begin.tile_type
	var e_type = end.tile_type
	match b_type[0]:
		"cap":
			var r = 0
			if begin.entry == "top":
				begin.change_type_to("corner", 270, true)
			elif begin.entry == "left":
				begin.change_type_to("straight", 90, true)
			elif begin.entry == "bottom":
				begin.change_type_to("corner", 0, true)
			match e_type[0]:
				"cap":
					match end.entry:
						"top":
							end.change_type_to("corner", 180, false)
						"right":
							end.change_type_to("straight", 90, false)
						"bottom":
							end.change_type_to("corner", 90, false)
				"straight":
					var vert = (begin.entry == "top") or (begin.entry == "bottom")
					if vert:
						end.change_type_to("3way", 90, false)
		"straight":
			if (begin.entry == "top") or (begin.entry == "bottom"):
				begin.change_type_to("3way", 270, true)
				match e_type[0]:
					"cap":
						match end.entry:
							"top":
								end.change_type_to("corner", 180, false)
							"right":
								end.change_type_to("straight", 90, false)
							"bottom":
								end.change_type_to("corner", 90, false)
					"straight":
						var vert = (begin.entry == "top") or (begin.entry == "bottom")
						if vert:
							end.change_type_to("3way", 90, false)
					"corner":
						match end.get_corner([end.entry, end.exit]):
							"top_left":
								end.change_type_to("3way", 0, false)
							"bottom_left":
								end.change_type_to("3way", 180, false)
			else:
				pass
		"corner":
			var b_corn = begin.get_corner([begin.entry, begin.exit])
			match b_corn:
				"bottom_right":
					begin.change_type_to("3way", 180, true)
				"top_right":
					begin.change_type_to("3way", 0, true)
				"bottom_left":
					begin.change_type_to("3way", 180, true)
				"top_left":
					begin.change_type_to("3way", 180, true)
			match e_type[0]:
				"cap":
					match end.entry:
						"top":
							end.change_type_to("corner", 270, false)
						"right":
							end.change_type_to("straight", 90, false)
						"bottom":
							end.change_type_to("corner", 90, false)
				"straight":
					var vert = (begin.entry == "top") or (begin.entry == "bottom")
					if vert:
						end.change_type_to("3way", 90, false)
				"corner":
					match end.get_corner([end.entry, end.exit]):
						"top_left":
							end.change_type_to("3way", 180, false)
						"bottom_left":
							end.change_type_to("3way", 0, false)
	end.changed = true
	begin.modulate = Color.gold
	end.modulate = Color.gold
	begin.connections.append(end)
	end.connections.append(begin)

func _on_Timer_timeout():
	paths_finished()
