extends Node2D

onready var game = get_parent()
onready var tac_cam = game.get_node("tac_cam")
onready var home_base = game.get_node("World/structures/ai_mainframe")

onready var units = $units
onready var structs = $structures

onready var general = preload("res://scenes/entities/ai_army.tscn")
onready var avatar_res = preload("res://scenes/entities/units/enemies/AI_avatar.tscn")
onready var u_root = game.get_node("units/hostile")
onready var s_root = game.get_node("World/structures")

var bits := 150.0
var bit_income = 2.5
var energy := 50.0
var RAM := 16

var target_size := 4
var unit_number := 0
var cam_path = []
var forward_base
var armies = []
var bases = []
var unassigned_units = []
var idle_army = null
var reinforcing = false

var struct_priority : Array = ["constructor", "bit_miner", "RAM", "base_tower"]
var struct

func _ready():
	tac_cam.connect("pause", self, "paused")
	tac_cam.connect("unpause", self, "unpaused")
	forward_base = home_base
	unassigned_units.append(get_node("../units/hostile/avatar"))

func get_closest_node():
	var dis := 45000.0
	var n
	for i in get_tree().get_nodes_in_group("nodes"):
		var d = game.get_path_length(forward_base.global_position, i.global_position)
#		print('current distance is %s' % dis)
#		print('node %s is %s px away' % [i.name, d])
		if d < dis:
#			print('node %s is closer than distance' % i.name)
			dis = d
			n = i
#	print('node %s is closest' % n.name)
	n.modulate = Color.gold
	return n
		
func paused():
	$bit_timer.paused = true
	$a_timer.paused = true
	
func unpaused():
	$bit_timer.paused = false
	$a_timer.paused = false

func new_avatar():
	$a_timer.start()
	
func _on_a_timer_timeout():
	var a = avatar_res.instance()
	a.position = home_base.position + Vector2(rand_range(-100,100), rand_range(50,100))
	u_root.add_child(a)

func on_build_finish():
	reinforcing = false
	
#btree tasks
func task_is_tac_pause(task):
	if tac_cam.tac_pause:
		task.succeed()
	else:
		task.failed()

func task_has_army(task):
	if armies.size() > 0:
		task.succeed()
	else:
		task.failed()

func task_is_army_at_target(task):
	var diff = (target_size - unit_number)
	if diff == 0:
		task.succeed()
	else:
		task.failed()

func task_is_under_attack(task):
	for i in bases:
		var z = i.get_node("range")
		var col = z.get_overlapping_bodies()
		if col.size() > 0:
			for o in col:
				if "team" in o:
					if o.team == "Player":
						task.succeed()
					else:
						task.failed()

func task_find_idle_army(task):
	for i in armies:
		if !i.mission:
			idle_army = i
			task.succeed()
			return
	task.failed()
	
func task_order_units(task):
	if reinforcing:
		task.failed()
	else:
		var num : int
		var diff = (target_size - unit_number)
		if diff < RAM:
			num = diff
		else:
			num = RAM
		var con = get_tree().get_nodes_in_group("ai_constructors")
		var u = units.get_resource("base_enemy")
		var loc = home_base.position + Vector2(rand_range(-100,100),100)
		var time = 1
		for i in con:
			i.build_queue.append({
				"unit": u,
				"num": num/con.size(),
				"loc": loc,
				"time": time
			})
		RAM -= num
		reinforcing = true
		task.succeed()
	
func task_create_army(task):
	if unassigned_units.size() < target_size:
		task.failed()
	else:
		var army = general.instance()
		for i in unassigned_units:
			army.units.append(i)
		u_root.add_child(army)
		army.game = game
		army.controller = self
		armies.append(army)
		unassigned_units.clear()
		task.succeed()
	
func task_move_army(task):
	if idle_army:
		var miss = get_closest_node()
		idle_army.mission = miss
		print('moving army to ' + idle_army.mission.name)
		idle_army = null
		task.succeed()
	else:
		task.failed()

func task_capture_node(task):
	pass

func task_build_structure(task):
	var sname = struct_priority[0]
	var s = $structures.get_resource(sname).instance()
	if bits > s.bit_cost:
		bits -= s.bit_cost
		var spos = forward_base.global_position + Vector2(rand_range(-200,200),rand_range(-200,200))
		s.global_position = spos.snapped(Vector2(32,32))
		s.team = "AI"
		s.parent = self
		s_root.add_child(s)
		struct_priority.remove(struct_priority.find(sname))
		struct_priority.append(sname)
		task.succeed()
	else:
		task.failed()
	
func _on_bit_timer_timeout():
	bits += bit_income
	$bit_timer.start()

