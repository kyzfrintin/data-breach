extends "res://scenes/entities/units/baseAI.gd"

onready var bul_res = preload("res://scenes/projectiles/bullet.tscn")
onready var parent = get_node("../../../ai_controller")

var general

func _process(delta):
	if is_instance_valid(target):
		if target.is_queued_for_deletion():
			target = null
			return
		$aim.look_at(target.position)
	elif path:
		var look = Vector2(path[0].x,path[0].y)
		$aim.look_at(look)

func _ready():
	$AnimationPlayer.playback_speed = rand_range(0.85,1.5)
	add_to_group("ai_units")

func delegate_attack():
	can_attack = false
	$attack_timer.start(cooldown)
	var bul = bul_res.instance()
	bul.position = $aim/Line2D/Position2D.global_position
	bul.team = "AI"
	bul.dir = position.direction_to(target.position)
	bul.parent = self
	game.add_child(bul)

func on_death():
	if general:
		if general.units.find(self) != -1:
			general.units.remove(general.units.find(self))
	parent.RAM += RAM_cost
	parent.unit_number -= RAM_cost
