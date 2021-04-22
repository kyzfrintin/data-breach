extends KinematicBody2D

onready var game = get_node("../../../")
onready var nav = game.get_node("World/navigation")
onready var sightline = $RayCast2D

export var max_hp := 100.0
export (String, "Player", "AI", "Neutral") var team
export var speed = 4.5
export var min_range := 100.0
export var max_range := 300.0
export var cooldown = 0.2
export var RAM_cost := 1
export var accel = 0.04
export var decel = 0.04

var hp = max_hp
var can_attack = true
var target = null
var potential_targets = []
var sector = null
var path = []
var pathline
var tac_cam
var move_order = null
var velocity := Vector2(0,0)
var stored_move_order = null
var following_move_order = false
var retreating = false
var healing = false

signal death
signal engaged

func _ready():
	if team == "Player":
		var p = Line2D.new()
		p.width = 2
		p.modulate.a = 0.9
		p.hide()
		p.position = Vector2(0,0)
		game.get_node("units/friendly").call_deferred("add_child", p)
		pathline = p
	elif !get("capturer"):
		game.get_node("ai_controller").unit_number += RAM_cost
	sightline.cast_to.x = max_range

func _on_attack_timer_timeout():
	can_attack = true

func attack():
	delegate_attack()

func sector_update():
	if !sector: return
	if target == null:
		var cols = sector.get_overlapping_bodies()
		var pt = []
		for i in cols:
			if ('team' in i) and (i.team != team):
				pt.append(i)
		if pt.size() > 0:
			if stored_move_order != null:
				move_order = stored_move_order
				stored_move_order = null
			following_move_order = false
			path.resize(0)
			var tnum = randi() % pt.size()
			target = pt[tnum]
			new_state("combat")
	
func _on_Detection_body_entered(body):
	if "team" in body:
		if body.team != team:
			if !is_instance_valid(target):
				if path.size() > 0:
					if stored_move_order == null:
						stored_move_order = move_order
					move_order = null
					path.resize(0)
				target = body
				new_state("combat")
				emit_signal("engaged", target)
				if !target.is_connected("death", self, "target_killed"):
					target.connect("death", self, "target_killed")

func delegate_attack():
	pass

func target_killed(_t):
	target = null
	sector_update()
	
func hit(amnt, entity):
	$hit_sound.play()
	hp -= amnt
	update_hp(hp)
	if healing:
		healing = false
		$heal_timer.start()
	if target != entity:
		if is_instance_valid(target):
			potential_targets.append(target)
		if !retreating:
			target = entity
	if hp <= 0:
		emit_signal("death", self)
		hp = 0
		die()

func die():
	on_death()
	call_deferred("queue_free")
	
func _process(_delta):
	if $ProgressBar.modulate.a > 0:
		$ProgressBar.modulate.a -= 0.001
	elif $ProgressBar.visible:
		$ProgressBar.hide()
	if !game.tac_cam.tac_pause:
		if !following_move_order:
			velocity = lerp(velocity, Vector2(0,0), decel)
		position += velocity

func draw_path():
	var p = path
	p.insert(0,position)
	pathline.points = p
	
func update_hp(value):
	$ProgressBar.value = value
	$ProgressBar.max_value = max_hp
	$ProgressBar.show()
	$ProgressBar.modulate.a = 1

func on_death():
	pass

	
func _on_scan_timer_timeout():
	sector_update()
	$scan_timer.start()

func _on_heal_timer_timeout():
	healing = true

func _on_Detection_area_entered(area):
	if 'Sector' in area.name:
		sector = area
		sector_update()
		
#btree tasks

func task_is_tactics_pause(task):
	if game.tac_cam.tac_pause == true:
		task.succeed()
	else:
		task.failed() 

func task_has_target(task):
	if is_instance_valid(target):
		task.succeed()
	else:
		new_state("move")
		task.failed()

func task_does_path_reach_target(task):
	if path.size() > 0:
		var path_end = path[path.size() - 1]
		var t
		match task.get_param(0):
			"target":
				t = target.position
			"move_order":
				t = move_order
		if Vector2(path_end.x,path_end.y).distance_to(Vector2(t.x,t.y)) > 250:
			task.failed()
		else:
			task.succeed()
	else:
		task.failed()

func task_is_enemy_close(task):
	var dis = position.distance_to(target.position)
	if dis <= min_range:
#		print('close!')
		task.succeed()
	else:
#		print('not close!')
		task.failed()
	return

func task_enemy_in_range(task):
#	$Polygon2D/Line2D.show()
	var dis = global_position.distance_to(target.global_position)
	if dis <= max_range:
		task.succeed()
#		$Polygon2D/Line2D.hide()
	else:
		task.failed()

func new_state(s):
	match s:
		"combat":
			$combat_tree.enable = true
			$move_tree.enable = false
		"move":
			$move_tree.enable = true
			$combat_tree.enable = false
	
func task_has_path(task):
	if path.size() > 0:
		task.succeed()
	else:
		following_move_order = false
		task.failed()

func task_create_path(task):
	var point : Vector2
	match task.get_param(0):
		"target":
			var dir = position.direction_to(target.position)
			point = target.position
			dir = Vector2(rand_range(-1,1),rand_range(-1,1))
			point += dir * rand_range(min_range, max_range)
			following_move_order = false
		"move_order":
			point = move_order
			following_move_order = true
	path = nav.find_path(global_position, point)
	if path:
		task.succeed()
#		print('created path!')
	else:
		task.failed()

func task_is_following_move_order(task):
	if following_move_order:
		task.succeed()
	else:
		task.failed()

func task_follow_path(task):
	var point = Vector2(path[0].x,path[0].y)
	var pdis = position.distance_to(point)
	var cspeed = velocity.length()
#	print('speed is %s, distance is %s' % [cspeed, pdis])
	if pdis < (200):
		path.remove(0)
		if team == "Player":
			draw_path()
		if path.size() > 0:
			point = Vector2(path[0].x,path[0].y)
		else:
			path = []
			if following_move_order:
				following_move_order = false
				move_order = null
			task.failed()
			return
	var dir = position.direction_to(point)
#	$Polygon2D.look_at(point)
	velocity = lerp(velocity, dir*speed, accel)
	task.succeed()

func task_can_attack(task):
	if can_attack:
		task.succeed()
	else:
		task.failed()
	
func task_can_see_enemy(task):
	sightline.look_at(target.position)
	var col = sightline.get_collider()
	if col == target:
		task.succeed()
	else:
		task.failed()

func task_attack(task):
	attack()
	task.succeed()

func task_has_move_order(task):
	if move_order != null:
		task.succeed()
	else:
		task.failed()

func task_get_stored_moved_order(task):
	if stored_move_order != null:
		move_order = stored_move_order
		stored_move_order = null
		task.succeed()
	else:
		task.failed()
