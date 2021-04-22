extends Node2D

onready var nav = get_node("navigation")

var start = true
var path_ends = []
var path = []

func _process(delta):
	var mp = get_global_mouse_position()
	if Input.is_action_just_pressed("left_mouse"):
		var node = get_closest_point(mp)
		if start:
			reset_colours()
			path_ends.clear()
			path_ends.append(node.global_position)
			node.modulate = Color.chartreuse
			start = false
		else:
			path_ends.append(node.global_position)
			node.modulate = Color.brown
			path = nav.find_path(path_ends[0], path_ends[1])
			$Line2D.points = path
			start = true

func reset_colours():
	for i in get_node("navigation").get_children():
		i.modulate = Color.white

func get_closest_point(mp):
	var dis = 8000
	var p
	for i in get_node("navigation").get_children():
		var d = i.global_position.distance_to(mp)
		if d < dis:
			dis = d
			p = i
	return p
