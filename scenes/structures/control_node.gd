extends Node2D

onready var game = get_node("../../../")
onready var tower_res = preload("res://scenes/structures/base_tower.tscn")
onready var def_res = preload("res://scenes/entities/units/defences/base_def.tscn")

var defences = []
var parent
var team = "Neutral"
var cap_team := ""
var aligning = false
var realigning = false
var capturer = null
var cap_prog = 0.0
var cap_max = 100.0

func _ready():
	add_to_group("nodes")
	yield(get_tree(), "idle_frame")
	build_towers()

func build_towers():
	var casts = get_node("tower_casts").get_children()
	for i in casts:
		if !i.get_collider():
			var tower = tower_res.instance()
			tower.global_position = global_position + i.cast_to
			tower.team = "Neutral"
			get_parent().add_child(tower)
			defences.append(tower)
			tower.connect("death", self, "tower_killed")
	get_node("tower_casts").queue_free()

func spawn_defences():
	var pos = global_position
	var num = 4 + (randi() % 4)
	for i in num:
		var def = def_res.instance()
		def.global_position = pos + Vector2(rand_range(-10*num,10*num),rand_range(-10*num,10*num))
		game.get_node("units/neutral").add_child(def)
		def.move_order = pos + Vector2(rand_range(-400,400),rand_range(-400,400))

func _process(delta):
	var cols = $Area2D.get_overlapping_bodies()
	if game.get_node("tac_cam").tac_pause: return
	if aligning:
#		print(cap_prog)
		if cols.find(capturer) != -1:
			if cap_prog < cap_max:
				if game.get_node("tac_cam").tac_pause:
					return
				cap_prog += 5*delta
			else:
				aligning = false
				$ProgressBar.hide()
				change_team(cap_team)
	elif realigning:
		if cols.find(capturer) != -1:
			if capturer.team == team:
				realigning = false
			else:
				if cap_prog > 0:
					if game.get_node("tac_cam").tac_pause:
						return
					cap_prog -= 5*delta
				else:
					realigning = false
					parent.RAM -= 8
					parent.bit_income -= 2.0
					parent = null
					_on_Area2D_body_entered(capturer)
				
	$ProgressBar.value = cap_prog

func change_team(new_team):
	if new_team == "Player":
		team = "Player"
		parent = game.get_node("tac_cam")
		modulate = Color8(138, 242, 270, 255)
	else:
		team = "AI"
		parent = game.get_node("ai_controller")
		modulate = Color8(260, 71, 61, 255)
	parent.RAM += 8
	parent.bit_income += 2.0

func tower_killed(t):
	if defences.find(t):
		defences.remove(defences.find(t))

#func cap_is_on_team(cap):
#	if capturer.friendly and team == "Player":
#		return true
#	elif !capturer.friendly and team == "AI":
#		return true
#	return false
	
func _on_Area2D_body_entered(body):
	if "capturer" in body:
		if !aligning:
			aligning = true
			capturer = body
			capturer.decel = 0.1
			cap_team = body.team
			$ProgressBar.show()
		elif body != capturer:
			if capturer.team != team:
				aligning = false
				realigning = true
				capturer = body
				capturer.decel = 0.1
				$ProgressBar.show()
				
func _on_Area2D_body_exited(body):
	if body == capturer:
		body.decel = 0.04
