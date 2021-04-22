extends Node2D

onready var detectors = $detectors.get_children()
onready var room = get_node("../../")
onready var types = room.get_node("room/types")

var node_spot
var active = false
#var priority := 0
#var results = []
var previous
var next
var connections = []
var path_leader
var path = []
var current_tile
var tile_type
var last_tile = false
var changed = false
var opening = "none"

var entry : String
var exit : String

signal activated
signal complete

func _ready():
	connect("activated", room, "room_activated")
	connect("complete", room, "room_finished")

func get_opposite(side):
	match side:
		"top":
			return "bottom"
		"right":
			return "left"
		"bottom":
			return "top"
		"left":
			return "right"

func get_results(filter_active = true):
	var results = []
	for i in detectors:
		var col = i.get_collider()
		if !col: continue
		var pcol = col.get_parent()
		if pcol != previous:
			if filter_active:
				if !pcol.active:
					results.append([pcol, i.name])
			else:
				results.append([pcol, i.name])
	return results

func is_connected_to(node):
	if connections.find(node) != -1:
		return true
	else:
		return false

func is_in_path(node):
	if path_leader.path.find(node) != -1:
		return true
	else:
		return false

func get_corner(sides : PoolStringArray):
	if ("bottom" in sides) and ("right" in sides):
		return "top_left"
	if ("bottom" in sides) and ("left" in sides):
		return "top_right"
	if ("top" in sides) and ("right" in sides):
		return "bottom_left"
	if ("top" in sides) and ("left" in sides):
		return "bottom_right"

func get_type(en, ex, op):
	if op != "none":
		pass
	if ex == get_opposite(en):
		var flip = (rand_range(0,1) > 0.5)
		var r = 0
		if flip:
			r = 180
		if (ex == "top") or (ex == "bottom"):
			return ["straight", 0 + r]
		else:
			return ["straight", 90 + r]
	elif ex != get_opposite(en) and ex != "none":
		var r = 0
		match get_corner([en, ex]):
			"top_left":
				r = 0
			"top_right":
				r = 90
			"bottom_right":
				r = 180
			"bottom_left":
				r = 270
		return ["corner", r]
	elif ex == "none":
		var r = 0
		match en:
			"bottom":
				r = 0
			"left":
				r = 90
			"top":
				r = 180
			"right":
				r = 270
		return ["cap", r]

func change_type_to(type, r, begin):
	var tile_folder = types.get_node(type)
	var variant = (rand_range(0,1) > 0.5)
	var tile
	if variant or path_leader or last_tile:
		randomize()
		var nt = (1 + (randi() % (tile_folder.get_child_count() - 1)))
		tile = tile_folder.get_child(nt).duplicate()
		if type == "cap":
			room.ends.append(self)
		room.nodes.append(self)
		if tile.get_node("node_spot") != null:
			node_spot = tile.get_node("node_spot")
	else:
		tile = tile_folder.get_child(0)
	if current_tile:
		current_tile.queue_free()
		var side = "right"
		if !begin:
			side = "left"
		match type:
			"cap":
				pass
			"straight":
				exit = side
			"corner":
				exit = side
			"3way":
				opening = side
	add_child(tile)
	tile.global_position = global_position
	current_tile = tile
	if node_spot:
		node_spot = tile.get_node("node_spot")
	tile.show()
	tile.rotation_degrees = r

func activate(first : bool, last : bool, remain : int, last_path : bool):
	active = true
	emit_signal("activated")
#	$box.hide()
	var results = get_results()
	if !last:
		if path_leader:
			path_leader.path.append(self)
		randomize()
		if results:
			results.shuffle()
			var r = results[0]
			next = r[0]
			exit = r[1]
			next.entry = get_opposite(r[1])
			next.previous = self
			next.connections.append(self)
			connections.append(next)
			
			if first:
				entry = exit
				path.append(self)
				path_leader = self
				next.path_leader = self
				var type = get_type(exit, "none", "none")
				tile_type = type
				change_type_to(type[0], type[1], true)
			else:
				next.path_leader = path_leader
				var type = get_type(entry, exit, "none")
				tile_type = type
				change_type_to(type[0], type[1], true)
			remain -= 1
			if remain > 1:
				next.activate(false, false, remain, last_path)
			else:
				next.activate(false, true, 0, last_path)
		else:
			last = true
			var type = get_type(entry, "none", "none")
			tile_type = type
			change_type_to(type[0], type[1], true)
	else:
		var type = get_type(entry, "none", "none")
		tile_type = type
		last_tile = true
		change_type_to(type[0], type[1], true)
	if tile_type[0] == "straight":
		if rand_range(0,1) > 0.75:
			branch()
	emit_signal("complete")
	
func branch():
	var num =  5 + (randi() % 5)
	var results = get_results()
	var n
	randomize()
	if results.size() > 0:
		results.shuffle()
		var r = results[0]
		n = r
		n[0].entry = get_opposite(r[1])
		n[0].previous = self
		n[0].connections.append(self)
		connections.append(n[0])
		n[0].activate(false, false, num, false)
		var vert = (entry == "top") or (entry == "bottom")
#		modulate = Color.gold
		if vert:
			if r[1] == "right":
				change_type_to("3way", 270, false)
			else:
				change_type_to("3way", 90, false)
		else:
			if r[1] == "top":
				change_type_to("3way", 180, false)
			else:
				change_type_to("3way", 0, false)
